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

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final ServicioAutenticacion _servicioAuth = ServicioAutenticacion();

  void _showAddTransactionSheet({bool iniciarConVoz = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PanelTransaccion(iniciarConVoz: iniciarConVoz),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final estadoApp = Provider.of<EstadoApp>(context, listen: false);
      final authUser = _servicioAuth.currentUser;
      if (authUser != null && !authUser.uid.startsWith('demo_')) {
        estadoApp.sincronizarConNube(authUser.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorFondo = esOscuro ? const Color(0xFF000000) : const Color(0xFFF0F2F5);

    Widget cuerpoVista;
    switch (estadoApp.selectedDockIndex) {
      case 0:
        cuerpoVista = const VistaInicio();
        break;
      case 1:
        cuerpoVista = const VistaMovimientos();
        break;
      case 2:
        cuerpoVista = const VistaEstadisticas();
        break;
      case 3:
        cuerpoVista = const VistaAhorro();
        break;
      default:
        cuerpoVista = const VistaInicio();
    }

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

            SafeArea(
              child: cuerpoVista,
            ),
            DockLiquidGlass(
              selectedIndex: estadoApp.selectedDockIndex,
              onIndexSelected: (idx) {
                estadoApp.selectedDockIndex = idx;
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
