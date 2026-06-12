import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/estado_app.dart';
import '../../../services/servicio_notificaciones.dart';
import '../../../widgets/interactive_scale.dart';

class AjustesNotificacionFija extends StatefulWidget {
  final VoidCallback onBack;

  const AjustesNotificacionFija({
    super.key,
    required this.onBack,
  });

  @override
  State<AjustesNotificacionFija> createState() => _AjustesNotificacionFijaState();
}

class _AjustesNotificacionFijaState extends State<AjustesNotificacionFija> {
  bool _solicitandoPermiso = false;

  Future<void> _onToggleNotificacion(bool habilitar) async {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    
    if (habilitar) {
      setState(() {
        _solicitandoPermiso = true;
      });

      // Solicitar permiso nativo de notificaciones
      final permisoConcedido = await ServicioNotificaciones.solicitarPermiso();

      setState(() {
        _solicitandoPermiso = false;
      });

      if (!permisoConcedido) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de notificaciones denegado. Habilítalo en los ajustes del celular.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        await estadoApp.setNotificacionFijaHabilitada(false);
        return;
      }
    }

    await estadoApp.setNotificacionFijaHabilitada(habilitar);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(habilitar
              ? 'Notificación fija activada en la barra de tareas'
              : 'Notificación fija desactivada'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: habilitar ? const Color(0xFF10B981) : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
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
        const SizedBox(height: 20),
        Text(
          'Notificación Fija',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colorTexto,
            letterSpacing: -0.8,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          'RESUMEN FINANCIERO SIEMPRE A MANO',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorTexto.withValues(alpha: 0.4),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 24),

        // Interruptor Principal
        _buildSectionCard(
          esOscuro: esOscuro,
          colorTexto: colorTexto,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: colorPrincipal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mostrar Tarjeta Fija',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colorTexto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fijar un resumen en tu celular',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorTexto.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _solicitandoPermiso
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorPrincipal,
                      ),
                    )
                  : Switch.adaptive(
                      value: estadoApp.notificacionFijaHabilitada,
                      activeThumbColor: colorPrincipal,
                      onChanged: _onToggleNotificacion,
                    ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms, delay: 150.ms),

        if (estadoApp.notificacionFijaHabilitada) ...[
          const SizedBox(height: 24),
          // Vista Previa de Notificación
          Text(
            'VISTA PREVIA EN EL CELULAR',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: colorTexto.withValues(alpha: 0.5),
            ),
          ).animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 10),
          _buildNotificationPreview(estadoApp, esOscuro, colorPrincipal, colorTexto)
              .animate()
              .fadeIn(duration: 400.ms)
              .scaleXY(begin: 0.95, end: 1.0, duration: 400.ms),

          const SizedBox(height: 28),
          // Seleccionar Plantillas
          Text(
            'SELECCIONAR PLANTILLA',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: colorTexto.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          _buildTemplatesSelector(estadoApp, esOscuro, colorPrincipal, colorTexto),

          // Configuración Personalizada
          if (estadoApp.notificacionPlantilla == 'personalizado') ...[
            const SizedBox(height: 24),
            Text(
              'PERSONALIZAR CONTENIDO',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: colorTexto.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            _buildCustomOptions(estadoApp, esOscuro, colorPrincipal, colorTexto),
          ],

          const SizedBox(height: 24),
          // Acción rápida
          Text(
            'ACCIONES RÁPIDAS',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: colorTexto.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionsCard(estadoApp, esOscuro, colorPrincipal, colorTexto),
        ],
        const SizedBox(height: 120),
      ],
    );
  }

  // Tarjeta Contenedora de Sección
  Widget _buildSectionCard({
    required bool esOscuro,
    required Color colorTexto,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: esOscuro
                ? const Color(0xFF0A0A0A).withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: esOscuro
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.65),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // Simulación Visual de la Notificación del Teléfono
  Widget _buildNotificationPreview(
      EstadoApp estadoApp, bool esOscuro, Color colorPrincipal, Color colorTexto) {
    final String symbol = estadoApp.currencySymbol;

    // Obtener valores simulados reales
    final double saldo = estadoApp.totalBalance;
    final double ingresos = estadoApp.totalIncome;
    final double gastos = estadoApp.totalExpenses;
    final double gastosHoy = estadoApp.totalExpensesToday;

    final globalBudget = estadoApp.budgets.firstWhere(
      (b) => b.categoryName == 'Global',
      orElse: () => ModeloPresupuesto(id: '', categoryName: 'Global', limitAmount: 0.0),
    );
    double totalLimite = 0.0;
    if (globalBudget.limitAmount > 0) {
      totalLimite = globalBudget.limitAmount;
    } else {
      totalLimite = estadoApp.budgets.fold(0.0, (sum, b) => sum + b.limitAmount);
    }
    double presupuestoRestante = totalLimite - gastos;

    // Determinar campos según plantilla
    bool showSaldo = false;
    bool showIngresos = false;
    bool showGastos = false;
    bool showGastosHoy = false;
    bool showPresupuesto = false;

    switch (estadoApp.notificacionPlantilla) {
      case 'balance':
        showSaldo = true;
        break;
      case 'control':
        showGastosHoy = true;
        showPresupuesto = totalLimite > 0;
        break;
      case 'resumen':
        showSaldo = true;
        showIngresos = true;
        showGastos = true;
        break;
      case 'personalizado':
      default:
        showSaldo = estadoApp.notificacionMostrarSaldo;
        showIngresos = estadoApp.notificacionMostrarIngresos;
        showGastos = estadoApp.notificacionMostrarGastos;
        showGastosHoy = estadoApp.notificacionMostrarGastosHoy;
        showPresupuesto = estadoApp.notificacionMostrarPresupuesto && totalLimite > 0;
        break;
    }

    String formatVal(double val) {
      String sign = val < 0 ? '-' : '';
      String formatted = val.abs().toStringAsFixed(2);
      final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      formatted = formatted.split('.')[0].replaceAllMapped(reg, (Match match) => '${match[1]},') + '.' + formatted.split('.')[1];
      return '$sign$symbol$formatted';
    }

    List<String> lineasExtra = [];
    if (showIngresos) lineasExtra.add('Ingresos: ${formatVal(ingresos)}');
    if (showGastos) lineasExtra.add('Gastos: ${formatVal(gastos)}');

    List<String> hoyLineas = [];
    if (showGastosHoy) hoyLineas.add('Hoy: ${formatVal(gastosHoy)}');
    if (showPresupuesto && totalLimite > 0) {
      hoyLineas.add('Disponible: ${formatVal(presupuestoRestante)}');
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Simular el gris oscuro/claro de la barra de notificaciones del celular
        color: esOscuro ? const Color(0xFF161618) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del sistema de notificaciones
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colorPrincipal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AirMoney',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: esOscuro ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '•  Resumen Financiero',
                style: TextStyle(
                  fontSize: 10,
                  color: esOscuro ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Text(
                'ahora',
                style: TextStyle(
                  fontSize: 10,
                  color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Contenido de la Notificación según la plantilla
          if (showSaldo)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Saldo Total: ${formatVal(saldo)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: esOscuro ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          
          if (lineasExtra.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 4),
              child: Text(
                lineasExtra.join('  |  '),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: esOscuro ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF334155),
                ),
              ),
            ),

          if (hoyLineas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                hoyLineas.join('  |  '),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: esOscuro ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF334155),
                ),
              ),
            ),

          if (!showSaldo && !showIngresos && !showGastos && !showGastosHoy && !showPresupuesto)
            Text(
              'Resumen financiero activo (Ningún dato seleccionado)',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: esOscuro ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF64748B),
              ),
            ),

          // Botones de acción simulados en la notificación
          if (estadoApp.notificacionMostrarAcciones) ...[
            const SizedBox(height: 12),
            Container(
              height: 0.8,
              color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 4),
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 14,
                  color: colorPrincipal,
                ),
                const SizedBox(width: 6),
                Text(
                  'Nueva Transacción',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colorPrincipal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Selector de Plantillas Prediseñadas
  Widget _buildTemplatesSelector(
      EstadoApp estadoApp, bool esOscuro, Color colorPrincipal, Color colorTexto) {
    final String select = estadoApp.notificacionPlantilla;

    Widget buildCard(String id, String title, String desc, IconData icon) {
      final isSel = select == id;
      return InteractiveScale(
        onTap: () => estadoApp.setNotificacionPlantilla(id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSel
                ? colorPrincipal.withValues(alpha: 0.08)
                : (esOscuro ? const Color(0xFF0F0F0F) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSel
                  ? colorPrincipal
                  : (esOscuro ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
              width: isSel ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSel ? colorPrincipal.withValues(alpha: 0.15) : (esOscuro ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1F5F9)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSel ? colorPrincipal : colorTexto.withValues(alpha: 0.6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorTexto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorTexto.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSel)
                Icon(
                  Icons.check_circle_rounded,
                  color: colorPrincipal,
                  size: 18,
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        buildCard('resumen', 'Resumen Completo', 'Saldo total, ingresos y gastos del mes.', Icons.donut_large_rounded),
        const SizedBox(height: 10),
        buildCard('control', 'Control Diario', 'Gastos de hoy y presupuesto mensual disponible.', Icons.track_changes_rounded),
        const SizedBox(height: 10),
        buildCard('balance', 'Balance Rápido', 'Solo muestra tu saldo total actual.', Icons.account_balance_rounded),
        const SizedBox(height: 10),
        buildCard('personalizado', 'Personalizado...', 'Elige exactamente qué campos mostrar en la tarjeta.', Icons.tune_rounded),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  // Switches individuales para la opción personalizada
  Widget _buildCustomOptions(
      EstadoApp estadoApp, bool esOscuro, Color colorPrincipal, Color colorTexto) {
    final budgets = estadoApp.budgets;
    final hasBudgets = budgets.isNotEmpty;

    Widget buildToggle(String title, bool val, ValueChanged<bool> onChanged, {bool enabled = true, String? subText}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: enabled ? colorTexto : colorTexto.withValues(alpha: 0.3),
                  ),
                ),
                if (subText != null)
                  Text(
                    subText,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orangeAccent.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            Switch.adaptive(
              value: val && enabled,
              activeThumbColor: colorPrincipal,
              onChanged: enabled ? onChanged : null,
            ),
          ],
        ),
      );
    }

    return _buildSectionCard(
      esOscuro: esOscuro,
      colorTexto: colorTexto,
      child: Column(
        children: [
          buildToggle(
            'Saldo Total',
            estadoApp.notificacionMostrarSaldo,
            (val) => estadoApp.setNotificacionMostrarSaldo(val),
          ),
          _buildDivider(esOscuro),
          buildToggle(
            'Ingresos del Mes',
            estadoApp.notificacionMostrarIngresos,
            (val) => estadoApp.setNotificacionMostrarIngresos(val),
          ),
          _buildDivider(esOscuro),
          buildToggle(
            'Gastos del Mes',
            estadoApp.notificacionMostrarGastos,
            (val) => estadoApp.setNotificacionMostrarGastos(val),
          ),
          _buildDivider(esOscuro),
          buildToggle(
            'Gastos de Hoy',
            estadoApp.notificacionMostrarGastosHoy,
            (val) => estadoApp.setNotificacionMostrarGastosHoy(val),
          ),
          _buildDivider(esOscuro),
          buildToggle(
            'Presupuesto Restante',
            estadoApp.notificacionMostrarPresupuesto,
            (val) => estadoApp.setNotificacionMostrarPresupuesto(val),
            enabled: hasBudgets,
            subText: !hasBudgets ? 'Requiere configurar presupuestos' : null,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // Tarjeta para acciones rápidas
  Widget _buildActionsCard(
      EstadoApp estadoApp, bool esOscuro, Color colorPrincipal, Color colorTexto) {
    return _buildSectionCard(
      esOscuro: esOscuro,
      colorTexto: colorTexto,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Botón "Nueva Transacción"',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colorTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Agrega un botón en la barra para crear un registro en 1 toque.',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorTexto.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: estadoApp.notificacionMostrarAcciones,
            activeThumbColor: colorPrincipal,
            onChanged: (val) => estadoApp.setNotificacionMostrarAcciones(val),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildDivider(bool esOscuro) {
    return Container(
      height: 0.8,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: esOscuro ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
    );
  }
}
