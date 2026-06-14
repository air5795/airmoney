import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../services/estado_app.dart';
import '../services/servicio_autenticacion.dart';
import '../models/usuario_app.dart';
import '../widgets/interactive_scale.dart';
import 'pantalla_login.dart';

class PantallaBloqueo extends StatefulWidget {
  final Widget? targetScreen;
  final bool popOnSuccess;
  /// Si se proporciona, al desbloquear se llama a este callback en lugar de
  /// navegar. Lo usa el AuthGate para mostrar el contenido sin cambiar de ruta.
  final VoidCallback? onUnlocked;

  const PantallaBloqueo({
    super.key,
    this.targetScreen,
    this.popOnSuccess = false,
    this.onUnlocked,
  }) : assert(popOnSuccess || targetScreen != null || onUnlocked != null,
            'Debe especificarse targetScreen, popOnSuccess u onUnlocked');

  @override
  State<PantallaBloqueo> createState() => _PantallaBloqueoState();
}

class _PantallaBloqueoState extends State<PantallaBloqueo> {
  final LocalAuthentication _auth = LocalAuthentication();
  final ServicioAutenticacion _servicioAuth = ServicioAutenticacion();
  
  String _pin = '';
  String _errorMessage = '';
  bool _isBiometricsRunning = false;

  @override
  void initState() {
    super.initState();
    // Iniciar biometría automáticamente con un leve retardo para esperar al renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerBiometrics();
    });
  }

  Future<void> _checkAndTriggerBiometrics() async {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    if (estadoApp.biometricEnabled) {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (canCheck && isSupported) {
        _authenticateWithBiometrics();
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isBiometricsRunning) return;
    setState(() {
      _isBiometricsRunning = true;
      _errorMessage = '';
    });

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Desbloquea AirMoney para acceder a tus finanzas.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        HapticFeedback.mediumImpact();
        _unlockAndNavigate();
      }
    } catch (e) {
      // Ignorar cancelaciones o errores comunes
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricsRunning = false;
        });
      }
    }
  }

  void _handleKeyPress(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = '';
      if (value == 'clear') {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_pin.length < 4) {
          _pin += value;
        }
      }
    });

    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), () {
        _verifyPinCode();
      });
    }
  }

  void _verifyPinCode() {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    if (estadoApp.verifyPin(_pin)) {
      HapticFeedback.mediumImpact();
      _unlockAndNavigate();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _pin = '';
        _errorMessage = 'PIN incorrecto. Inténtalo de nuevo.';
      });
    }
  }

  void _unlockAndNavigate() {
    if (!mounted) return;
    if (widget.onUnlocked != null) {
      // Modo AuthGate: avisar que se desbloqueo, el gate muestra el contenido.
      widget.onUnlocked!();
    } else if (widget.popOnSuccess) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.targetScreen!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  Future<void> _handleForgotPin() async {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              '¿Olvidaste tu PIN?',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: const Text(
              'Por motivos de seguridad, para restablecer el PIN debes cerrar sesión. Esto limpiará los datos locales y podrás volver a ingresar mediante Google.',
              style: TextStyle(fontSize: 14),
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
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.of(context).pop(); // Cerrar dialogo
                  
                  // Cerrar sesion de Firebase/Google y limpiar cache
                  await _servicioAuth.signOut();
                  await estadoApp.clearAllData();
                  
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const PantallaLogin()),
                    );
                  }
                },
                child: const Text(
                  'Cerrar Sesión',
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
    final colorFondo = esOscuro ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    
    final user = _servicioAuth.currentUser;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Stack(
          children: [
            // Micro-destello radial de fondo sutil
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.2,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorPrincipal.withValues(alpha: esOscuro ? 0.06 : 0.04),
                      colorFondo.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  
                  // Perfil o Avatar del Usuario
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorPrincipal.withValues(alpha: 0.1),
                            border: Border.all(
                              color: esOscuro ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                              width: 2.0,
                            ),
                          ),
                          child: ClipOval(
                            child: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                                ? Image.network(
                                    user.photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(user, colorPrincipal),
                                  )
                                : _buildInitialsAvatar(user, colorPrincipal),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Bienvenido de nuevo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorTexto.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.displayName ?? 'Usuario',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: colorTexto,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0, duration: 500.ms),
                  
                  const SizedBox(height: 36),

                  // Burbujas indicadoras del PIN
                  if (estadoApp.pinEnabled)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final hasChar = index < _pin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasChar
                                    ? colorPrincipal
                                    : (esOscuro ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
                                border: Border.all(
                                  color: hasChar ? colorPrincipal : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                            );
                          }),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ).animate().shake(duration: 400.ms),
                          ),
                      ],
                    ),

                  const Spacer(),

                  // Teclado numérico
                  if (estadoApp.pinEnabled)
                    _buildKeyboard(colorTexto, esOscuro, estadoApp.biometricEnabled)
                  else if (estadoApp.biometricEnabled)
                    // Si solo hay huella activa (sin PIN), permitir relanzar el dialogo biométrico
                    Center(
                      child: InteractiveScale(
                        onTap: _authenticateWithBiometrics,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorPrincipal.withValues(alpha: 0.08),
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            color: colorPrincipal,
                            size: 64,
                          ),
                        ),
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.bounceOut),
                  
                  const Spacer(),
                  
                  // Boton de salir/olvide mi PIN en la parte inferior
                  Center(
                    child: TextButton(
                      onPressed: _handleForgotPin,
                      child: Text(
                        'Cerrar Sesión / Olvidé mi PIN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorTexto.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(UsuarioApp? user, Color colorPrincipal) {
    final displayName = user?.displayName ?? 'U';
    final initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colorPrincipal,
        ),
      ),
    );
  }

  Widget _buildKeyboard(Color colorTexto, bool esOscuro, bool biometricEnabled) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeyboardButton('1', colorTexto, esOscuro),
            _buildKeyboardButton('2', colorTexto, esOscuro),
            _buildKeyboardButton('3', colorTexto, esOscuro),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeyboardButton('4', colorTexto, esOscuro),
            _buildKeyboardButton('5', colorTexto, esOscuro),
            _buildKeyboardButton('6', colorTexto, esOscuro),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeyboardButton('7', colorTexto, esOscuro),
            _buildKeyboardButton('8', colorTexto, esOscuro),
            _buildKeyboardButton('9', colorTexto, esOscuro),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Boton de Huella a la izquierda (si esta activa)
            biometricEnabled
                ? _buildKeyboardButton('biometric', colorTexto, esOscuro, isSpecial: true)
                : const SizedBox(width: 70, height: 70),
            
            _buildKeyboardButton('0', colorTexto, esOscuro),
            _buildKeyboardButton('clear', colorTexto, esOscuro, isSpecial: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyboardButton(String value, Color colorTexto, bool esOscuro, {bool isSpecial = false}) {
    final isClear = value == 'clear';
    final isBiometric = value == 'biometric';
    
    return InteractiveScale(
      onTap: () {
        if (isBiometric) {
          _authenticateWithBiometrics();
        } else {
          _handleKeyPress(value);
        }
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSpecial
              ? Colors.transparent
              : (esOscuro ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02)),
        ),
        alignment: Alignment.center,
        child: isClear
            ? Icon(
                Icons.backspace_rounded,
                color: colorTexto.withValues(alpha: 0.6),
                size: 20,
              )
            : isBiometric
                ? Icon(
                    Icons.fingerprint_rounded,
                    color: colorTexto.withValues(alpha: 0.8),
                    size: 28,
                  )
                : Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: colorTexto,
                    ),
                  ),
      ),
    );
  }
}
