import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/estado_app.dart';
import '../services/servicio_autenticacion.dart';
import '../widgets/panel_transaccion.dart';
import '../widgets/dock_liquid_glass.dart';
import 'home/vista_inicio.dart';
import 'movimientos/vista_movimientos.dart';
import 'estadisticas/vista_estadisticas.dart';
import 'ahorro/vista_ahorro.dart';
import 'pantalla_bloqueo.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> with WidgetsBindingObserver {
  final ServicioAutenticacion _servicioAuth = ServicioAutenticacion();
  late PageController _pageController;

  DateTime? _backgroundTime;
  bool _isLockScreenShowing = false;

  void _showAddTransactionSheet({bool iniciarConVoz = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PanelTransaccion(iniciarConVoz: iniciarConVoz),
    );
  }

  void _onEstadoAppChange() {
    if (mounted) {
      final estadoApp = Provider.of<EstadoApp>(context, listen: false);
      if (estadoApp.debeMostrarFormularioTransaccion) {
        estadoApp.debeMostrarFormularioTransaccion = false; // reset
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAddTransactionSheet();
        });
      }
    }
  }

  void _checkAddTransactionOnStart() {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    if (estadoApp.debeMostrarFormularioTransaccion) {
      estadoApp.debeMostrarFormularioTransaccion = false; // reset
      _showAddTransactionSheet();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    _pageController = PageController(initialPage: estadoApp.selectedDockIndex);
    
    estadoApp.addListener(_onEstadoAppChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authUser = _servicioAuth.currentUser;
      if (authUser != null) {
        estadoApp.sincronizarConNube(authUser.uid);
      }
      _checkAddTransactionOnStart();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    estadoApp.removeListener(_onEstadoAppChange);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    
    if (!estadoApp.biometricEnabled && !estadoApp.pinEnabled) return;
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundTime ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_backgroundTime != null) {
        final elapsed = DateTime.now().difference(_backgroundTime!);
        _backgroundTime = null; // Reiniciar
        
        if (elapsed.inSeconds >= 30 && !_isLockScreenShowing && _servicioAuth.currentUser != null) {
          _isLockScreenShowing = true;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PantallaBloqueo(popOnSuccess: true),
            ),
          ).then((_) {
            _isLockScreenShowing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorFondo = esOscuro ? const Color(0xFF000000) : const Color(0xFFF0F2F5);

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorFondo,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: colorFondo,
        child: Stack(
          children: [
            // Micro-destello radial de fondo sumamente sutil en la esquina superior
            Positioned(
              top: -size.height * 0.15,
              right: -size.width * 0.2,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      estadoApp.colorPrincipal.withValues(alpha: esOscuro ? 0.05 : 0.03),
                      colorFondo.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            PageView(
              controller: _pageController,
              onPageChanged: (idx) {
                estadoApp.selectedDockIndex = idx;
              },
              physics: const BouncingScrollPhysics(),
              children: const [
                VistaInicio(),
                VistaMovimientos(),
                VistaEstadisticas(),
                VistaAhorro(),
              ],
            ),
            DockLiquidGlass(
              selectedIndex: estadoApp.selectedDockIndex,
              onIndexSelected: (idx) {
                estadoApp.selectedDockIndex = idx;
                _pageController.animateToPage(
                  idx,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.fastOutSlowIn,
                );
              },
              onAddPressed: _showAddTransactionSheet,
              onAddLongPressed: () => _showAddTransactionSheet(iniciarConVoz: true),
            ),
          ],
        ),
      ),
    );
  }
}
