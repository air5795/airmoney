import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/app_config.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/interactive_scale.dart';
import '../../../widgets/backdrop_filter_safe.dart';

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
      final file = File('${tempDir.path}/${AppConfig.appName.toLowerCase()}_respaldo_$dateSuffix.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Copia de seguridad de ${AppConfig.appName} ($dateSuffix)',
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
      final file = File('${tempDir.path}/${AppConfig.appName.toLowerCase()}_movimientos_$dateSuffix.csv');
      await file.writeAsString(csvBuffer.toString(), encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reporte de movimientos de ${AppConfig.appName} ($dateSuffix)',
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
        return BackdropFilterSafe(
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

    final Color colorTitulo = esOscuro
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.1), colorPrincipal)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.15), colorPrincipal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InteractiveScale(
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
                            fontWeight: FontWeight.w700,
                            color: colorPrincipal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                    'Respaldos',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colorTitulo,
                    ),
                  ),
                ),
              ),
              const Expanded(
                flex: 3,
                child: SizedBox(),
              ),
            ],
          ),
        ),
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
        const SizedBox(height: 16),
        // Bento Card para Importar CSV
        _buildBentoActionCard(
          icon: Icons.table_chart_rounded,
          title: 'Importar desde Excel / CSV',
          description: 'Selecciona un archivo .csv o .txt para importar tus movimientos de forma masiva. Podrás asociar las columnas de tu archivo (Fecha, Monto, Categoría, Detalle) de forma gráfica.',
          buttonText: 'Importar CSV',
          colorPrincipal: colorPrincipal,
          colorTexto: colorTexto,
          colorSecundario: colorSecundario,
          esOscuro: esOscuro,
          onTap: () => _importarCsv(estadoApp),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05, end: 0, duration: 400.ms),
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
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    return BackdropFilterSafe(
      borderRadius: BorderRadius.circular(24),
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: esOscuro
              ? const Color(0xFF0A0A0A).withValues(alpha: estadoApp.modoRendimiento ? 0.95 : 0.45)
              : Colors.white.withValues(alpha: estadoApp.modoRendimiento ? 0.98 : 0.60),
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
      );
  }

  Future<void> _importarCsv(EstadoApp estadoApp) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      
      String csvContent;
      try {
        csvContent = utf8.decode(bytes);
      } catch (_) {
        csvContent = latin1.decode(bytes);
      }

      final lines = csvContent.split(RegExp(r'\r?\n')).where((line) => line.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El archivo está vacío.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final firstLine = lines.first;
      String delimiter = ',';
      if (firstLine.contains(';')) {
        delimiter = ';';
      } else if (firstLine.contains('\t')) {
        delimiter = '\t';
      }

      List<List<String>> parsedRows = [];
      for (var line in lines) {
        parsedRows.add(_parseCsvLine(line, delimiter));
      }

      if (parsedRows.isEmpty) return;

      final firstRow = parsedRows.first;
      List<String> headers = [];
      for (int i = 0; i < firstRow.length; i++) {
        headers.add(firstRow[i].isNotEmpty ? firstRow[i] : 'Columna ${i + 1}');
      }

      if (!mounted) return;
      _mostrarDialogoMapeo(parsedRows, headers, estadoApp);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar el archivo CSV: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  List<String> _parseCsvLine(String line, String delimiter) {
    List<String> result = [];
    StringBuffer currentField = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        result.add(currentField.toString().trim());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }
    result.add(currentField.toString().trim());
    return result;
  }

  void _mostrarDialogoMapeo(List<List<String>> parsedRows, List<String> headers, EstadoApp estadoApp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _DialogoMapeoCsv(
          parsedRows: parsedRows,
          headers: headers,
          estadoApp: estadoApp,
          onImportCompleted: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Datos CSV importados y sincronizados con éxito.'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _DialogoMapeoCsv extends StatefulWidget {
  final List<List<String>> parsedRows;
  final List<String> headers;
  final EstadoApp estadoApp;
  final VoidCallback onImportCompleted;

  const _DialogoMapeoCsv({
    required this.parsedRows,
    required this.headers,
    required this.estadoApp,
    required this.onImportCompleted,
  });

  @override
  State<_DialogoMapeoCsv> createState() => _DialogoMapeoCsvState();
}

class _DialogoMapeoCsvState extends State<_DialogoMapeoCsv> {
  String? _selectedAccountId;
  bool _omitirCabecera = true;
  int _colTitleIdx = 0;
  int _colAmountIdx = 0;
  int _colDateIdx = 0;
  int? _colCategoryIdx;
  String _selectedDateFormat = 'Automático';
  String? _selectedCategoryFallback;
  String _selectedImportType = 'auto'; // 'auto', 'gasto', 'ingreso'

  @override
  void initState() {
    super.initState();
    if (widget.estadoApp.accounts.isNotEmpty) {
      _selectedAccountId = widget.estadoApp.accounts.first.id;
    }
    if (widget.estadoApp.categories.isNotEmpty) {
      _selectedCategoryFallback = widget.estadoApp.categories.first.name;
    }
    
    // Auto-detect columns based on name matches
    for (int i = 0; i < widget.headers.length; i++) {
      final header = widget.headers[i].toLowerCase();
      if (header.contains('concepto') || header.contains('detalle') || header.contains('descrip') || header.contains('titulo') || header.contains('title')) {
        _colTitleIdx = i;
      } else if (header.contains('monto') || header.contains('importe') || header.contains('cantidad') || header.contains('amount') || header.contains('valor')) {
        _colAmountIdx = i;
      } else if (header.contains('fecha') || header.contains('date')) {
        _colDateIdx = i;
      } else if (header.contains('categor') || header.contains('category') || header.contains('rubro')) {
        _colCategoryIdx = i;
      }
    }
    
    // Fallback if they map to the same column
    if (_colAmountIdx == 0 && widget.headers.length > 1) {
      _colAmountIdx = 1;
    }
    if (_colDateIdx == 0 && widget.headers.length > 2) {
      _colDateIdx = 2;
    }
  }

  DateTime? _intentarParsearFecha(String text, String format) {
    text = text.trim();
    if (text.isEmpty) return null;

    if (format == 'Automático') {
      final matchYmd = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(text);
      if (matchYmd != null) {
        final y = int.parse(matchYmd.group(1)!);
        final m = int.parse(matchYmd.group(2)!);
        final d = int.parse(matchYmd.group(3)!);
        return DateTime(y, m, d);
      }
      final matchDmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(text);
      if (matchDmy != null) {
        final d = int.parse(matchDmy.group(1)!);
        final m = int.parse(matchDmy.group(2)!);
        final y = int.parse(matchDmy.group(3)!);
        return DateTime(y, m, d);
      }
      try {
        return DateTime.parse(text);
      } catch (_) {}
      return null;
    }

    if (format == 'DD/MM/AAAA') {
      final match = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(text);
      if (match != null) {
        final d = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final y = int.parse(match.group(3)!);
        return DateTime(y, m, d);
      }
    }

    if (format == 'AAAA-MM-DD') {
      final match = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(text);
      if (match != null) {
        final y = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        final d = int.parse(match.group(3)!);
        return DateTime(y, m, d);
      }
    }

    if (format == 'MM/DD/AAAA') {
      final match = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(text);
      if (match != null) {
        final m = int.parse(match.group(1)!);
        final d = int.parse(match.group(2)!);
        final y = int.parse(match.group(3)!);
        return DateTime(y, m, d);
      }
    }

    return DateTime.tryParse(text);
  }

  double? _intentarParsearMonto(String text) {
    text = text.trim().replaceAll(RegExp(r'[^\d.,-]'), '');
    if (text.isEmpty) return null;

    if (text.contains(',') && text.contains('.')) {
      final commaIndex = text.indexOf(',');
      final dotIndex = text.indexOf('.');
      if (commaIndex < dotIndex) {
        text = text.replaceAll(',', '');
      } else {
        text = text.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (text.contains(',')) {
      final parts = text.split(',');
      if (parts.length == 2 && parts[1].length == 2) {
        text = text.replaceAll(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
    }

    return double.tryParse(text);
  }

  void _procesarImportacion() async {
    if (_selectedAccountId == null) return;
    
    List<ModeloTransaccion> nuevasTxs = [];
    final startIndex = _omitirCabecera ? 1 : 0;

    for (int i = startIndex; i < widget.parsedRows.length; i++) {
      final row = widget.parsedRows[i];
      if (row.isEmpty) continue;

      final String titulo = _colTitleIdx < row.length ? row[_colTitleIdx].trim() : 'Transacción Importada';
      final String rawMonto = _colAmountIdx < row.length ? row[_colAmountIdx] : '0';
      final double? montoParsed = _intentarParsearMonto(rawMonto);
      if (montoParsed == null) {
        continue;
      }

      final String rawFecha = _colDateIdx < row.length ? row[_colDateIdx] : '';
      final DateTime? fechaParsed = _intentarParsearFecha(rawFecha, _selectedDateFormat);
      final DateTime fechaFinal = fechaParsed ?? DateTime.now();

      String tipo = 'gasto';
      double montoFinal = montoParsed;
      
      if (_selectedImportType == 'gasto') {
        tipo = 'gasto';
        montoFinal = montoParsed.abs();
      } else if (_selectedImportType == 'ingreso') {
        tipo = 'ingreso';
        montoFinal = montoParsed.abs();
      } else {
        if (montoParsed < 0) {
          tipo = 'gasto';
          montoFinal = montoParsed.abs();
        } else {
          tipo = 'ingreso';
        }
      }

      String categoriaFinal = _selectedCategoryFallback ?? 'Otros';
      if (_colCategoryIdx != null && _colCategoryIdx! < row.length) {
        final rawCat = row[_colCategoryIdx!].trim().toLowerCase();
        if (rawCat.isNotEmpty) {
          final matches = widget.estadoApp.categories.where(
            (c) => c.name.toLowerCase() == rawCat || c.id.toLowerCase() == rawCat
          );
          if (matches.isNotEmpty) {
            categoriaFinal = matches.first.name;
          }
        }
      }

      nuevasTxs.add(ModeloTransaccion(
        id: 'tx_${fechaFinal.millisecondsSinceEpoch}_${i}_${(montoFinal * 100).toInt()}',
        title: titulo.isNotEmpty ? titulo : 'Sin concepto',
        description: 'Importado de CSV',
        amount: montoFinal,
        category: categoriaFinal,
        date: fechaFinal,
        type: tipo,
        accountId: _selectedAccountId!,
        pagada: true,
      ));
    }

    if (nuevasTxs.isEmpty) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo importar ninguna fila. Verifica el mapeo.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await widget.estadoApp.importarTransaccionesMasivas(nuevasTxs);
    Navigator.of(context).pop();
    widget.onImportCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.estadoApp.esTemaOscuro;
    final colorPrincipal = widget.estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorSecundario = esOscuro ? Colors.white70 : const Color(0xFF475569);
    
    final previewRowIndex = _omitirCabecera && widget.parsedRows.length > 1 ? 1 : 0;
    final previewRow = widget.parsedRows.length > previewRowIndex ? widget.parsedRows[previewRowIndex] : [];

    return BackdropFilterSafe(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      borderRadius: BorderRadius.circular(24),
      child: AlertDialog(
        backgroundColor: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Asistente de Importación CSV',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: colorTexto,
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdownField<String>(
                  label: 'Cuenta destino',
                  value: _selectedAccountId,
                  items: widget.estadoApp.accounts.map((acc) {
                    return DropdownMenuItem(
                      value: acc.id,
                      child: Text('${acc.name} (${acc.currency ?? 'BOB'})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Checkbox(
                      value: _omitirCabecera,
                      activeColor: colorPrincipal,
                      onChanged: (val) {
                        setState(() => _omitirCabecera = val ?? true);
                      },
                    ),
                    Expanded(
                      child: Text(
                        'La primera fila es de cabecera (omitir)',
                        style: TextStyle(color: colorTexto, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Mapeo de Columnas',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorTexto, fontSize: 14),
                ),
                const SizedBox(height: 12),

                _buildColumnDropdown(
                  label: 'Concepto / Título',
                  value: _colTitleIdx,
                  onChanged: (val) => setState(() => _colTitleIdx = val!),
                  headers: widget.headers,
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 12),

                _buildColumnDropdown(
                  label: 'Monto / Importe',
                  value: _colAmountIdx,
                  onChanged: (val) => setState(() => _colAmountIdx = val!),
                  headers: widget.headers,
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 12),

                _buildColumnDropdown(
                  label: 'Fecha',
                  value: _colDateIdx,
                  onChanged: (val) => setState(() => _colDateIdx = val!),
                  headers: widget.headers,
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 12),

                _buildDropdownField<String>(
                  label: 'Formato de Fecha',
                  value: _selectedDateFormat,
                  items: ['Automático', 'DD/MM/AAAA', 'AAAA-MM-DD', 'MM/DD/AAAA'].map((fmt) {
                    return DropdownMenuItem(
                      value: fmt,
                      child: Text(fmt),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedDateFormat = val!),
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 12),

                _buildDropdownField<int?>(
                  label: 'Columna Categoría (Opcional)',
                  value: _colCategoryIdx,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Ninguna (Usar valor por defecto)'),
                    ),
                    ...List.generate(widget.headers.length, (idx) {
                      return DropdownMenuItem<int?>(
                        value: idx,
                        child: Text(widget.headers[idx]),
                      );
                    }),
                  ],
                  onChanged: (val) => setState(() => _colCategoryIdx = val),
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 12),

                _buildDropdownField<String>(
                  label: 'Categoría por defecto',
                  value: _selectedCategoryFallback,
                  items: widget.estadoApp.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.name,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryFallback = val),
                  colorTexto: colorTexto,
                ),
                const SizedBox(height: 12),

                _buildDropdownField<String>(
                  label: 'Tipo de transacción',
                  value: _selectedImportType,
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('Detectar por signo (+/-)')),
                    DropdownMenuItem(value: 'gasto', child: Text('Forzar Gastos')),
                    DropdownMenuItem(value: 'ingreso', child: Text('Forzar Ingresos')),
                  ],
                  onChanged: (val) => setState(() => _selectedImportType = val!),
                  colorTexto: colorTexto,
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Vista Previa (Fila ${previewRowIndex + 1})',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorTexto, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (previewRow.isNotEmpty) ...[
                  _buildPreviewItem(
                    label: 'Concepto:',
                    value: _colTitleIdx < previewRow.length ? previewRow[_colTitleIdx] : '-',
                    colorSecundario: colorSecundario,
                  ),
                  _buildPreviewItem(
                    label: 'Monto:',
                    value: _colAmountIdx < previewRow.length
                        ? '${_intentarParsearMonto(previewRow[_colAmountIdx]) ?? "Error de formato: " + previewRow[_colAmountIdx]}'
                        : '-',
                    colorSecundario: colorSecundario,
                  ),
                  _buildPreviewItem(
                    label: 'Fecha:',
                    value: _colDateIdx < previewRow.length
                        ? '${_intentarParsearFecha(previewRow[_colDateIdx], _selectedDateFormat) ?? "Error de formato: " + previewRow[_colDateIdx]}'
                        : '-',
                    colorSecundario: colorSecundario,
                  ),
                  if (_colCategoryIdx != null && _colCategoryIdx! < previewRow.length)
                    _buildPreviewItem(
                      label: 'Categoría:',
                      value: previewRow[_colCategoryIdx!],
                      colorSecundario: colorSecundario,
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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
              backgroundColor: colorPrincipal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _procesarImportacion,
            child: const Text(
              'Importar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem({required String label, required String value, required Color colorSecundario}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: colorSecundario, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnDropdown({
    required String label,
    required int value,
    required ValueChanged<int?> onChanged,
    required List<String> headers,
    required Color colorTexto,
  }) {
    return _buildDropdownField<int>(
      label: label,
      value: value,
      items: List.generate(headers.length, (idx) {
        return DropdownMenuItem(
          value: idx,
          child: Text(headers[idx]),
        );
      }),
      onChanged: onChanged,
      colorTexto: colorTexto,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required Color colorTexto,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          style: TextStyle(color: colorTexto, fontSize: 13),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
