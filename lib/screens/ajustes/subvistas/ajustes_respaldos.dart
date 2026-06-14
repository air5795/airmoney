import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/interactive_scale.dart';

class AjustesRespaldos extends StatefulWidget {
  final VoidCallback onBack;

  const AjustesRespaldos({
    super.key,
    required this.onBack,
  });

  @override
  State<AjustesRespaldos> createState() => _AjustesRespaldosState();
}

class _AjustesRespaldosState extends State<AjustesRespaldos> {
  int _activeTab = 0; // 0 = Exportar, 1 = Importar
  bool _isProcessing = false;

  Future<void> _exportarJson(EstadoApp estadoApp) async {
    setState(() => _isProcessing = true);
    try {
      final Map<String, dynamic> backupData = {
        'version': 1,
        'exportadoEn': DateTime.now().toIso8601String(),
        'cuentas': estadoApp.accounts.map((e) => e.toMap()).toList(),
        'transacciones': estadoApp.transactions.map((e) => e.toMap()).toList(),
        'categorias': estadoApp.categories.map((e) => e.toMap()).toList(),
        'ahorros': estadoApp.savingsGoals.map((e) => e.toMap()).toList(),
        'presupuestos': estadoApp.budgets.map((e) => e.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final tempDir = await getTemporaryDirectory();
      final dateSuffix = DateTime.now().toIso8601String().split('T').first;
      final file = File('${tempDir.path}/airmoney_respaldo_$dateSuffix.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Copia de seguridad de AirMoney ($dateSuffix)',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al exportar respaldo JSON.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportarExcel(EstadoApp estadoApp) async {
    setState(() => _isProcessing = true);
    try {
      final csvBuffer = StringBuffer();
      // Excel standard CSV delimiter in Spanish is semicolon (;) and UTF-8 BOM prefix
      csvBuffer.write('\uFEFF'); 
      csvBuffer.writeln('Fecha;Detalle;Tipo;Categoría;Cuenta;Monto;Descripción');

      for (var tx in estadoApp.transactions) {
        final dateStr = '${tx.date.day}/${tx.date.month}/${tx.date.year}';
        final title = tx.title.replaceAll(';', ',');
        final type = tx.type == 'ingreso' ? 'Ingreso' : (tx.type == 'gasto' ? 'Gasto' : 'Transferencia');
        final category = tx.category.replaceAll(';', ',');
        
        final acc = estadoApp.accounts.firstWhere(
          (a) => a.id == tx.accountId, 
          orElse: () => ModeloCuenta(id: '', name: 'N/A', type: '', balance: 0, gradientIndex: 0)
        );
        final accName = acc.name.replaceAll(';', ',');
        final amount = tx.amount.toStringAsFixed(2).replaceAll('.', ','); // Comma as decimal
        final desc = tx.description.replaceAll(';', ',').replaceAll('\n', ' ');

        csvBuffer.writeln('"$dateStr";"$title";"$type";"$category";"$accName";$amount;"$desc"');
      }

      final tempDir = await getTemporaryDirectory();
      final dateSuffix = DateTime.now().toIso8601String().split('T').first;
      final file = File('${tempDir.path}/airmoney_movimientos_$dateSuffix.csv');
      await file.writeAsString(csvBuffer.toString(), encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reporte de movimientos de AirMoney ($dateSuffix)',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al exportar reporte Excel/CSV.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importarJson(EstadoApp estadoApp) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return; // Usuario canceló la selección
      }

      final file = File(result.files.single.path!);
      final jsonContent = await file.readAsString();

      if (!mounted) return;

      // Mostrar diálogo de confirmación antes de sobrescribir
      final bool? confirmar = await _mostrarConfirmacionSobrescribir();
      if (confirmar != true) return;

      setState(() => _isProcessing = true);
      
      final bool exito = await estadoApp.importarDatosDesdeJson(jsonContent);

      if (!mounted) return;

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos importados y sincronizados con éxito.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo de respaldo no es válido o está corrupto.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al importar los datos.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool?> _mostrarConfirmacionSobrescribir() async {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              '¿Sobrescribir datos actuales?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: colorTexto,
              ),
            ),
            content: Text(
              'Esta acción reemplazará de forma permanente toda la información actual de este dispositivo (cuentas, transacciones, presupuestos y metas) con la que contiene el archivo de respaldo.\n\n¿Deseas continuar?',
              style: TextStyle(
                color: colorTexto.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: colorTexto.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorSecundario = esOscuro ? const Color(0xFF64748B) : const Color(0xFF475569);

    final colorContenedorTabs = esOscuro
        ? const Color(0xFF0A0A0A).withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.03);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            InteractiveScale(
              onTap: widget.onBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: colorPrincipal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ajustes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorPrincipal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Respaldos',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colorTexto,
            letterSpacing: -0.8,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          'GESTIÓN DE IMPORTACIÓN Y EXPORTACIÓN',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorTexto.withValues(alpha: 0.4),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 20),

        // Selector Segmentado de Tabs (Estilo Liquid Glass)
        Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colorContenedorTabs,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _activeTab == 0
                          ? colorPrincipal.withValues(alpha: esOscuro ? 0.15 : 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _activeTab == 0
                            ? colorPrincipal.withValues(alpha: 0.25)
                            : Colors.transparent,
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Exportar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == 0 ? colorPrincipal : colorTexto.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _activeTab == 1
                          ? colorPrincipal.withValues(alpha: esOscuro ? 0.15 : 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _activeTab == 1
                            ? colorPrincipal.withValues(alpha: 0.25)
                            : Colors.transparent,
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Importar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == 1 ? colorPrincipal : colorTexto.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 120.ms),
        const SizedBox(height: 24),

        // Cuerpo dinámico basado en el tab activo
        _isProcessing
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 80.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: colorPrincipal, strokeWidth: 3),
                      const SizedBox(height: 16),
                      Text(
                        _activeTab == 0 ? 'Generando archivo de respaldo...' : 'Cargando datos en la aplicación...',
                        style: TextStyle(color: colorSecundario, fontSize: 13),
                      )
                    ],
                  ),
                ),
              )
            : (_activeTab == 0 ? _buildExportTab(estadoApp, esOscuro, colorPrincipal, colorTexto, colorSecundario) : _buildImportTab(estadoApp, esOscuro, colorPrincipal, colorTexto, colorSecundario)),
        
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildExportTab(EstadoApp estadoApp, bool esOscuro, Color colorPrincipal, Color colorTexto, Color colorSecundario) {
    return Column(
      children: [
        // Bento Card para Exportar JSON
        _buildBentoActionCard(
          icon: Icons.code_rounded,
          title: 'Exportar Respaldo completo (JSON)',
          description: 'Crea una copia de seguridad encriptada en formato de texto JSON que contiene todas tus cuentas, metas, presupuestos y movimientos. Ideal para transferir datos a otro celular o guardar un respaldo.',
          buttonText: 'Exportar JSON',
          colorPrincipal: colorPrincipal,
          colorTexto: colorTexto,
          colorSecundario: colorSecundario,
          esOscuro: esOscuro,
          onTap: () => _exportarJson(estadoApp),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
        const SizedBox(height: 16),

        // Bento Card para Exportar Excel
        _buildBentoActionCard(
          icon: Icons.table_view_rounded,
          title: 'Exportar Movimientos a Excel (CSV)',
          description: 'Genera una hoja de cálculo formateada para Microsoft Excel (CSV) con el registro completo de tus ingresos, gastos y transferencias de este dispositivo. Ideal para análisis financiero personal.',
          buttonText: 'Exportar Excel',
          colorPrincipal: colorPrincipal,
          colorTexto: colorTexto,
          colorSecundario: colorSecundario,
          esOscuro: esOscuro,
          onTap: () => _exportarExcel(estadoApp),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
      ],
    );
  }

  Widget _buildImportTab(EstadoApp estadoApp, bool esOscuro, Color colorPrincipal, Color colorTexto, Color colorSecundario) {
    return Column(
      children: [
        // Bento Card para Importar JSON
        _buildBentoActionCard(
          icon: Icons.unarchive_rounded,
          title: 'Restaurar desde Respaldo (JSON)',
          description: 'Selecciona un archivo de respaldo con extensión .json generado previamente por la aplicación para restaurar toda tu información. Ten en cuenta que esta acción sobrescribirá tus datos locales actuales.',
          buttonText: 'Seleccionar Archivo',
          colorPrincipal: colorPrincipal,
          colorTexto: colorTexto,
          colorSecundario: colorSecundario,
          esOscuro: esOscuro,
          onTap: () => _importarJson(estadoApp),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
      ],
    );
  }

  Widget _buildBentoActionCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required Color colorPrincipal,
    required Color colorTexto,
    required Color colorSecundario,
    required bool esOscuro,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: esOscuro
                ? const Color(0xFF0A0A0A).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: esOscuro ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.65),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colorPrincipal.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: colorPrincipal, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorTexto,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: colorSecundario,
                ),
              ),
              const SizedBox(height: 18),
              InteractiveScale(
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: colorPrincipal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorPrincipal.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorPrincipal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
