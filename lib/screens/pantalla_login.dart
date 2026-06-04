import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/servicio_autenticacion.dart';
import '../services/estado_app.dart';
import '../models/usuario_app.dart';
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
      if (!_servicioAuth.isFirebaseInitialized) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No se pudo conectar con los servicios de Google. Por favor, verifica tu conexion a internet e intenta de nuevo.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      UsuarioApp? user;
      if (provider == 'google') {
        user = await _servicioAuth.signInWithGoogle();
      }

      if (!mounted) return;

      if (user != null) {
        final estadoApp = Provider.of<EstadoApp>(context, listen: false);
        
        // Sincronizar con la nube inmediatamente para descargar las cuentas del usuario logueado
        final bool syncSuccess = await estadoApp.sincronizarConNube(user.uid);

        if (!mounted) return;

        if (!syncSuccess) {
          await _servicioAuth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No se pudo sincronizar tus datos desde la nube. Por favor, verifica tu conexion a internet.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

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
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrimario = estadoApp.colorPrincipal;
    
    final colorFondo = esOscuro ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final colorTexto = esOscuro ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final colorSecundario = esOscuro ? const Color(0xFF64748B) : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: colorFondo,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: colorFondo,
        child: Stack(
          children: [
            // Micro-destello radial de fondo sumamente sutil (no intrusivo)
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
                      colorPrimario.withValues(alpha: esOscuro ? 0.05 : 0.03),
                      colorFondo.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cabecera unificada con Splash para consistencia de marca
                      Column(
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Image.asset(
                              'assets/images/512-trans.png',
                              fit: BoxFit.contain,
                            ),
                          )
                              .animate()
                              .scale(duration: 600.ms, curve: Curves.easeOutCubic),
                          const SizedBox(height: 20),
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 30,
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
                              .fadeIn(duration: 600.ms, delay: 200.ms)
                              .slideY(begin: 0.15, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
                          const SizedBox(height: 6),
                          Text(
                            'ADMINISTRA TUS FINANZAS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3.5,
                              color: colorSecundario.withValues(alpha: 0.5),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 350.ms),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Tarjeta acrílica refinada (Bento Grid Style)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: BoxDecoration(
                          color: esOscuro
                              ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: esOscuro
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.03),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: colorTexto,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Accede de forma rápida y segura para sincronizar tus finanzas.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorSecundario.withValues(alpha: 0.85),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 28),
                            
                            // Botón de login con Spring Animation sutil en tap
                            _buildSocialButton(
                              provider: 'google',
                              label: 'Continuar con Google',
                              assetIcon: 'assets/images/google_logo.png',
                              color: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
                              textColor: colorTexto,
                              border: BorderSide(
                                color: esOscuro
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 400.ms)
                          .slideY(begin: 0.12, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),
                      
                      const SizedBox(height: 36),
                      
                      // Pie de seguridad explícita
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 13,
                            color: colorSecundario.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AirMoney protege tus datos de acuerdo al estándar PCI-DSS.',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: colorSecundario.withValues(alpha: 0.4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 800.ms, delay: 650.ms),
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
    IconData? icon,
    String? assetIcon,
    required Color color,
    required Color textColor,
    Color? iconColor,
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
            color: const Color(0xFF000000).withValues(alpha: 0.04),
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
                  if (assetIcon != null)
                    Image.asset(
                      assetIcon,
                      width: 24,
                      height: 24,
                    )
                  else if (icon != null)
                    Icon(
                      icon,
                      size: 24,
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
