import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'estado_app.dart';

class ServicioNotificaciones {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;
  static EstadoApp? _estadoApp;
  static const int _notificationId = 888;
  static const String _channelId = 'airmoney_fixed_summary_channel';
  static const String _channelName = 'Resumen Financiero Fijo';
  static const String _channelDesc = 'Muestra una tarjeta fija con el resumen financiero de tus cuentas';

  /// Inicializa el plugin de notificaciones.
  static Future<void> inicializar(EstadoApp estadoApp) async {
    if (_inicializado) return;
    _estadoApp = estadoApp;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    _inicializado = true;
    debugPrint('=== SERVICIO NOTIFICACIONES: Inicializado con éxito ===');

    // Si la notificación fija está habilitada, la actualizamos/creamos al iniciar la app
    if (estadoApp.notificacionFijaHabilitada) {
      await actualizarNotificacion(estadoApp);
    }
  }

  /// Maneja el click en la notificación o en sus acciones rápidas (primer plano).
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('=== SERVICIO NOTIFICACIONES: Notificación presionada ===');
    debugPrint('Payload: ${response.payload}, ActionId: ${response.actionId}');
    
    if (response.actionId == 'add_expense' || response.payload == 'open_add_expense') {
      _estadoApp?.debeMostrarFormularioTransaccion = true;
    }
  }

  /// Maneja el click en segundo plano (background) o app terminada.
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    debugPrint('=== SERVICIO NOTIFICACIONES: Notificación en background presionada ===');
    // En Android, presionar una acción abre la UI si la acción tiene `showsUserInterface: true`
  }

  /// Solicita explícitamente los permisos de notificaciones (Android 13+).
  static Future<bool> solicitarPermiso() async {
    if (Platform.isAndroid) {
      final androidPlatform = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlatform = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlatform != null) {
        final granted = await iosPlatform.requestPermissions(
          alert: true,
          badge: true,
          sound: false,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// Cancela y elimina la notificación fija.
  static Future<void> cancelarNotificacion() async {
    if (!_inicializado) return;
    await _plugin.cancel(id: _notificationId);
    debugPrint('=== SERVICIO NOTIFICACIONES: Notificación fija cancelada ===');
  }

  /// Formatea valores numéricos como montos monetarios.
  static String _formatMonto(double monto, String symbol) {
    String sign = monto < 0 ? '-' : '';
    double absMonto = monto.abs();
    String fixed = absMonto.toStringAsFixed(2);
    List<String> parts = fixed.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    integerPart = integerPart.replaceAllMapped(reg, (Match match) => '${match[1]},');

    return '$sign$symbol$integerPart.$decimalPart';
  }

  /// Actualiza la notificación fija con los datos actuales.
  static Future<void> actualizarNotificacion(EstadoApp estadoApp) async {
    if (!_inicializado) return;

    if (!estadoApp.notificacionFijaHabilitada) {
      await cancelarNotificacion();
      return;
    }

    // Calcular montos
    final String symbol = estadoApp.currencySymbol;
    final double saldo = estadoApp.totalBalance;
    final double ingresos = estadoApp.totalIncome;
    final double gastos = estadoApp.totalExpenses;
    final double gastosHoy = estadoApp.totalExpensesToday;

    // Calcular presupuesto restante
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

    // Determinar qué mostrar según la plantilla
    bool showSaldo = false;
    bool showIngresos = false;
    bool showGastos = false;
    bool showGastosHoy = false;
    bool showPresupuesto = false;
    bool showAcciones = estadoApp.notificacionMostrarAcciones;

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

    // Construir las líneas de la notificación
    List<String> lineas = [];
    String mainTitle = 'AirMoney • Resumen Financiero';

    if (showSaldo) {
      lineas.add('Saldo Total: ${_formatMonto(saldo, symbol)}');
    }

    List<String> mesInfo = [];
    if (showIngresos) {
      mesInfo.add('Ingresos: ${_formatMonto(ingresos, symbol)}');
    }
    if (showGastos) {
      mesInfo.add('Gastos: ${_formatMonto(gastos, symbol)}');
    }
    if (mesInfo.isNotEmpty) {
      lineas.add(mesInfo.join('  |  '));
    }

    List<String> hoyInfo = [];
    if (showGastosHoy) {
      hoyInfo.add('Gastos de Hoy: ${_formatMonto(gastosHoy, symbol)}');
    }
    if (showPresupuesto && totalLimite > 0) {
      hoyInfo.add('Disponible: ${_formatMonto(presupuestoRestante, symbol)}');
    }
    if (hoyInfo.isNotEmpty) {
      lineas.add(hoyInfo.join('  |  '));
    }

    if (lineas.isEmpty) {
      lineas.add('Notificación activa - Sin datos seleccionados');
    }

    // El primer renglón será el cuerpo principal, y el resto formará parte de un estilo "BigText"
    String bodyText = lineas.first;
    String bigTextBody = lineas.join('\n');

    // Configuración Android específica para notificación fija y de baja prioridad (no molestar con ruidos)
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max, // Promover al tope
      priority: Priority.high, // Promover al tope
      playSound: false, // Evitar ruidos molestos en actualizaciones
      enableVibration: false, // Evitar vibración molesta en actualizaciones
      ongoing: true, // Fija, no descartable
      autoCancel: false,
      showWhen: false,
      color: estadoApp.colorPrincipal, // Color de cabecera de la app
      colorized: true, // Pintar todo el fondo de la tarjeta de notificación
      styleInformation: BigTextStyleInformation(
        bigTextBody,
        contentTitle: mainTitle,
        summaryText: 'Resumen Diario',
      ),
      actions: showAcciones
          ? <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'add_expense',
                '＋ Nueva Transacción',
                showsUserInterface: true, // Abre la app al presionar el botón
                cancelNotification: false,
              ),
            ]
          : null,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: false, // Evita banners ruidosos repetitivos
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await _plugin.show(
        id: _notificationId,
        title: mainTitle,
        body: bodyText,
        notificationDetails: platformChannelSpecifics,
        payload: 'open_add_expense',
      );
      debugPrint('=== SERVICIO NOTIFICACIONES: Notificación fija actualizada ===');
    } catch (e) {
      debugPrint('Error al mostrar la notificación fija: $e');
    }
  }
}
