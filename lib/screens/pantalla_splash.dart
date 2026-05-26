import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/servicio_autenticacion.dart';
import '../services/estado_app.dart';
import 'pantalla_login.dart';
import 'pantalla_principal.dart';
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
    final ServicioAutenticacion servicioAuth = ServicioAutenticacion();
    await servicioAuth.checkInitialSession();
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final estadoApp = Provider.of<EstadoApp>(context, listen: false);

    if (servicioAuth.currentUser != null) {
      if (estadoApp.hasCompletedOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PantallaPrincipal()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PantallaIdioma()),
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          Positioned(
            top: -size.height * 0.15,
            right: -size.width * 0.25,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC5FAD5).withOpacity(0.55),
                    const Color(0xFFFAFAFA).withOpacity(0.0),
                  ],
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  duration: 4.seconds,
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.15, 1.15),
                  curve: Curves.easeInOut,
                ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF1E293B).withOpacity(0.15),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E293B).withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFC5FAD5).withOpacity(0.35),
                            Colors.white.withOpacity(0.0),
                          ],
                          center: Alignment.topLeft,
                          radius: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    )
                    .then()
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(
                      duration: 2.seconds,
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.04, 1.04),
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(height: 32),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              fontFamily: 'Roboto',
                            ),
                            children: [
                              TextSpan(text: 'Air'),
                              TextSpan(
                                text: 'Money',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 200.ms)
                            .slideY(
                              begin: 0.2,
                              end: 0.0,
                              duration: 800.ms,
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 8),
                        Text(
                          'TU DINERO, LIGERO.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            color: const Color(0xFF0F172A).withOpacity(0.4),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 400.ms),
                      ],
                    ),
                    Positioned(
                      bottom: 22,
                      right: size.width * 0.17,
                      child: Container(
                        width: 96,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 1000.ms, delay: 350.ms)
                          .scaleX(
                            duration: 1000.ms,
                            delay: 350.ms,
                            alignment: Alignment.centerLeft,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
