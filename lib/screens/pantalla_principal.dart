import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/estado_app.dart';
import '../services/servicio_autenticacion.dart';
import '../widgets/panel_transaccion.dart';
import '../widgets/pintor_papel_cuaderno.dart';
import '../widgets/dock_liquid_glass.dart';
import 'home/vista_inicio.dart';
import 'movimientos/vista_movimientos.dart';
import 'ajustes/vista_ajustes.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  int _selectedDockIndex = 0;
  final ServicioAutenticacion _servicioAuth = ServicioAutenticacion();

  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PanelTransaccion(),
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
    final size = MediaQuery.of(context).size;
    final esOscuro = estadoApp.esTemaOscuro;
    final colorFondo = esOscuro ? const Color(0xFF020617) : const Color(0xFFF0F2F5);

    Widget cuerpoVista;
    switch (_selectedDockIndex) {
      case 0:
        cuerpoVista = const VistaInicio();
        break;
      case 1:
        cuerpoVista = const VistaMovimientos();
        break;
      case 2:
        cuerpoVista = const Center(
          child: Text(
            'Seccion de Estadisticas en construccion',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
            ),
          ),
        );
        break;
      case 3:
        cuerpoVista = const VistaAjustes();
        break;
      default:
        cuerpoVista = const VistaInicio();
    }

    return Scaffold(
      backgroundColor: colorFondo,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: colorFondo,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: PintorPapelCuaderno(
                  esTemaOscuro: esOscuro,
                  colorAcento: estadoApp.colorPrincipal,
                ),
              ),
            ),
            // Destello superior izquierdo dinámico con el color principal de las configuraciones
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.25,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      esOscuro
                          ? estadoApp.colorPrincipal.withValues(alpha: 0.18)
                          : estadoApp.colorPrincipal.withValues(alpha: 0.28),
                      colorFondo.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Destello inferior derecho dinámico con el color principal de las configuraciones (más grande)
            Positioned(
              bottom: -size.height * 0.2,
              right: -size.width * 0.3,
              child: Container(
                width: 480,
                height: 480,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      esOscuro
                          ? estadoApp.colorPrincipal.withValues(alpha: 0.15)
                          : estadoApp.colorPrincipal.withValues(alpha: 0.22),
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
              selectedIndex: _selectedDockIndex,
              onIndexSelected: (idx) {
                setState(() {
                  _selectedDockIndex = idx;
                });
              },
              onAddPressed: _showAddTransactionSheet,
            ),
          ],
        ),
      ),
    );
  }
}
