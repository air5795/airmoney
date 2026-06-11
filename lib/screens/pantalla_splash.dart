import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/servicio_autenticacion.dart';
import '../services/estado_app.dart';
import 'pantalla_login.dart';
import 'pantalla_principal.dart';
import 'pantalla_bloqueo.dart';
import 'onboarding/pantalla_idioma.dart';

class PantallaSplash extends StatefulWidget {
  const PantallaSplash({super.key});

  @override
  State<PantallaSplash> createState() => _PantallaSplashState();
}

class _PantallaSplashState extends State<PantallaSplash> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    if (!mounted) return;
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);

    // 1. Esperar a que se carguen las preferencias locales
    await estadoApp.initFuture;

    final ServicioAutenticacion servicioAuth = ServicioAutenticacion();
    // 2. Comprobar la sesión inicial con robustez
    await servicioAuth.checkInitialSession();

    if (servicioAuth.currentUser != null) {
      if (!mounted) return;
      // Sincronizar con la nube de inmediato en el arranque si hay sesion activa
      await estadoApp.sincronizarConNube(servicioAuth.currentUser!.uid);
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    if (servicioAuth.currentUser != null) {
      final Widget target = estadoApp.hasCompletedOnboarding
          ? const PantallaPrincipal()
          : const PantallaIdioma();

      if (estadoApp.biometricEnabled || estadoApp.pinEnabled) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PantallaBloqueo(targetScreen: target),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => target),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PantallaLogin()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrimario = estadoApp.colorPrincipal;

    final colorFondo = esOscuro
        ? const Color(0xFF000000)
        : const Color(0xFFF8FAFC);
    final colorTexto = esOscuro
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF0F172A);
    final colorSecundario = esOscuro
        ? const Color(0xFF64748B)
        : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Stack(
          children: [
            // Micro-destello radial de fondo sumamente sutil (no intrusivo)
            Positioned(
              top: -120,
              left: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorPrimario.withValues(alpha: esOscuro ? 0.06 : 0.04),
                      colorFondo.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logotipo institucional con efecto fisico tactil
                  SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset(
                          'assets/images/512-trans.png',
                          fit: BoxFit.contain,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOutCubic)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1.0, 1.0),
                        duration: 800.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 32),

                  // Títulos y marcas de tipografía fina y estable
                  RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: colorTexto,
                            fontFamily: 'Roboto',
                            letterSpacing: -0.8,
                          ),
                          children: [
                            const TextSpan(text: 'Air'),
                            TextSpan(
                              text: 'Money',
                              style: TextStyle(
                                color: colorPrimario,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(
                        duration: 800.ms,
                        delay: 200.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .slideY(
                        begin: 0.15,
                        end: 0.0,
                        duration: 800.ms,
                        delay: 200.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 6),

                  Text(
                    'CUIDA TUS FINANZAS.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.0,
                      color: colorSecundario.withValues(alpha: 0.6),
                    ),
                  ).animate().fadeIn(
                    duration: 800.ms,
                    delay: 350.ms,
                    curve: Curves.easeOutCubic,
                  ),

                  const SizedBox(height: 36),

                  // Indicador lineal de carga/sincronización institucional
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        backgroundColor: esOscuro
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorPrimario.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(
                    duration: 800.ms,
                    delay: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
                ],
              ),
            ),

            // Pie de pantalla con seguridad implícita
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: colorSecundario.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CONEXIÓN CIFRADA DE EXTREMO A EXTREMO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colorSecundario.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(
              duration: 800.ms,
              delay: 700.ms,
              curve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}
