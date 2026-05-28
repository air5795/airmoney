import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/servicio_autenticacion.dart';
import '../services/estado_app.dart';
import 'pantalla_principal.dart';
import 'onboarding/pantalla_idioma.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final ServicioAutenticacion _servicioAuth = ServicioAutenticacion();
  bool _isLoading = false;
  String? _loadingProvider;

  Future<void> _handleLogin(String provider) async {
    setState(() {
      _isLoading = true;
      _loadingProvider = provider;
    });

    try {
      final user = provider == 'google'
          ? await _servicioAuth.signInWithGoogle()
          : await _servicioAuth.signInWithFacebook();

      if (!mounted) return;

      if (user != null) {
        final estadoApp = Provider.of<EstadoApp>(context, listen: false);
        
        // Sincronizar con la nube inmediatamente para descargar las cuentas del usuario logueado
        if (!user.uid.startsWith('demo_')) {
          await estadoApp.sincronizarConNube(user.uid);
        }

        if (!mounted) return;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo iniciar sesion con $provider. Por favor intenta de nuevo.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Ocurrio un error al intentar iniciar sesion.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFFAFAFA),
        child: Stack(
          children: [
            Positioned(
              top: -size.height * 0.1,
              right: -size.width * 0.2,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFC5FAD5).withValues(alpha: 0.55),
                      const Color(0xFFFAFAFA).withValues(alpha: 0.0),
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
            Positioned(
              bottom: size.height * 0.1,
              left: -size.width * 0.2,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00B0FF).withValues(alpha: 0.08),
                      const Color(0xFFFAFAFA).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                    duration: 5.seconds,
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    curve: Curves.easeInOut,
                  ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFF1E293B).withValues(alpha: 0.12),
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFC5FAD5).withValues(alpha: 0.35),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                    center: Alignment.topLeft,
                                    radius: 1.2,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    'A',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .scale(duration: 600.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 20),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 30,
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
                              .fadeIn(duration: 600.ms, delay: 200.ms)
                              .slideY(begin: 0.2, end: 0, duration: 600.ms),
                          const SizedBox(height: 6),
                          Text(
                            'TU DINERO, LIGERO.',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                              color: const Color(0xFF0F172A).withValues(alpha: 0.4),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 350.ms),
                        ],
                      ),
                      const SizedBox(height: 48),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E293B).withValues(alpha: 0.06),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Accede de forma rapida y segura para sincronizar tus finanzas.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 36),
                                _buildSocialButton(
                                  provider: 'google',
                                  label: 'Continuar con Google',
                                  icon: Icons.g_mobiledata_rounded,
                                  color: Colors.white,
                                  textColor: const Color(0xFF0F172A),
                                  iconColor: const Color(0xFFEA4335),
                                  border: BorderSide(
                                    color: const Color(0xFF1E293B).withValues(alpha: 0.12),
                                    width: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSocialButton(
                                  provider: 'facebook',
                                  label: 'Continuar con Facebook',
                                  icon: Icons.facebook_rounded,
                                  color: const Color(0xFF1877F2),
                                  textColor: Colors.white,
                                  iconColor: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 500.ms)
                          .slideY(begin: 0.15, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),
                      const SizedBox(height: 48),
                      Text(
                        'AIRMONEY asegura tus datos con encriptacion avanzada.',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 800.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String provider,
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color iconColor,
    BorderSide? border,
  }) {
    final isThisLoading = _isLoading && _loadingProvider == provider;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _handleLogin(provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
        child: isThisLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: icon == Icons.g_mobiledata_rounded ? 34 : 24,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
