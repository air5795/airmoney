import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/interactive_scale.dart';

class AjustesSeguridad extends StatefulWidget {
  final VoidCallback onBack;

  const AjustesSeguridad({
    super.key,
    required this.onBack,
  });

  @override
  State<AjustesSeguridad> createState() => _AjustesSeguridadState();
}

class _AjustesSeguridadState extends State<AjustesSeguridad> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isDeviceSupported = false;
  bool _checkingHardware = true;

  @override
  void initState() {
    super.initState();
    _checkHardwareSupport();
  }

  Future<void> _checkHardwareSupport() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (mounted) {
        setState(() {
          _isDeviceSupported = isSupported;
          _canCheckBiometrics = canCheck;
          _checkingHardware = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingHardware = false;
        });
      }
    }
  }

  Future<void> _toggleBiometrics(bool value, EstadoApp estadoApp) async {
    if (value) {
      // Pedir autenticacion para habilitarla por primera vez
      try {
        final authenticated = await _auth.authenticate(
          localizedReason: 'Confirma tu identidad para activar el acceso biométrico.',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        );

        if (authenticated) {
          await estadoApp.setBiometricEnabled(true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  estadoApp.pinEnabled
                      ? 'Acceso biométrico activado correctamente.'
                      : 'Acceso biométrico activado. Te recomendamos configurar un PIN de respaldo por si la huella falla.',
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al autenticar: ${e.toString().split(':').last.trim()}'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      await estadoApp.setBiometricEnabled(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso biométrico desactivado.'),
            backgroundColor: Color(0xFF64748B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPinBottomSheet(BuildContext context, {required bool isSetup, required EstadoApp estadoApp}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PinNumpadSheet(
          isSetup: isSetup,
          estadoApp: estadoApp,
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

    final biometricsAvailable = !_checkingHardware && _isDeviceSupported && _canCheckBiometrics;

    final Color colorTitulo = esOscuro
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.1), colorPrincipal)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.15), colorPrincipal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InteractiveScale(
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
                            fontWeight: FontWeight.w700,
                            color: colorPrincipal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: Text(
                    'Seguridad',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: colorTitulo,
                    ),
                  ),
                ),
              ),
              const Expanded(
                flex: 3,
                child: SizedBox(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Bento Card - Seguridad
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item de huella digital
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: colorPrincipal.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fingerprint_rounded,
                                color: colorPrincipal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Desbloqueo Biométrico',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: colorTexto,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _checkingHardware
                                        ? 'Verificando hardware...'
                                        : (biometricsAvailable
                                            ? 'Usar huella o rostro al iniciar'
                                            : 'No disponible en este dispositivo'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: colorTexto.withValues(alpha: 0.5),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: estadoApp.biometricEnabled,
                        activeThumbColor: colorPrincipal,
                        onChanged: biometricsAvailable
                            ? (val) => _toggleBiometrics(val, estadoApp)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                  ),
                  const SizedBox(height: 20),
                  // Item de PIN
                  Row(
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
                              Icons.pin_rounded,
                              color: colorPrincipal,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Código PIN de Acceso',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorTexto,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                estadoApp.pinEnabled
                                    ? 'PIN activado como respaldo'
                                    : 'Desactivado (Acceso sin contraseña local)',
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Botones para PIN
                  if (!estadoApp.pinEnabled)
                    InteractiveScale(
                      onTap: () => _showPinBottomSheet(context, isSetup: true, estadoApp: estadoApp),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: colorPrincipal,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorPrincipal.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Activar Código PIN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        InteractiveScale(
                          onTap: () => _showPinBottomSheet(context, isSetup: true, estadoApp: estadoApp),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: colorPrincipal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorPrincipal.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Cambiar Código PIN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorPrincipal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InteractiveScale(
                          onTap: () {
                            // Mostrar dialogo de confirmacion para desactivar PIN
                            showDialog(
                              context: context,
                              builder: (context) => BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: AlertDialog(
                                  backgroundColor: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: const Text(
                                    '¿Desactivar PIN?',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  content: const Text(
                                    'Esto desactivará el código de seguridad local. Tu cuenta de Google seguirá activa, pero cualquier persona con acceso a tu móvil podrá ver tus datos.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Cancelar',
                                        style: TextStyle(color: colorTexto.withValues(alpha: 0.5)),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () async {
                                        await estadoApp.disablePin();
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Código PIN desactivado.'),
                                              backgroundColor: Color(0xFF64748B),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Desactivar', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.15),
                                width: 1.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Desactivar Código PIN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
        const SizedBox(height: 110),
      ],
    );
  }
}

// Bottom Sheet con teclado numérico personalizado para el PIN
class _PinNumpadSheet extends StatefulWidget {
  final bool isSetup;
  final EstadoApp estadoApp;

  const _PinNumpadSheet({
    required this.isSetup,
    required this.estadoApp,
  });

  @override
  State<_PinNumpadSheet> createState() => _PinNumpadSheetState();
}

class _PinNumpadSheetState extends State<_PinNumpadSheet> {
  String _pin = '';
  String _firstPin = '';
  bool _confirming = false;
  String _errorMessage = '';

  void _handleKeyPress(String value) {
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
      Future.delayed(const Duration(milliseconds: 200), () {
        _handlePinCompletion();
      });
    }
  }

  void _handlePinCompletion() async {
    if (widget.isSetup) {
      if (!_confirming) {
        // Primera captura del PIN
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _confirming = true;
        });
      } else {
        // Confirmacion del PIN
        if (_pin == _firstPin) {
          await widget.estadoApp.setPin(_pin);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Código PIN configurado correctamente.'),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          setState(() {
            _pin = '';
            _errorMessage = 'Los PIN no coinciden. Inténtalo de nuevo.';
          });
        }
      }
    } else {
      // Flujo de verificacion si fuese necesario (actualmente no se despliega en settings de esta manera)
      if (widget.estadoApp.verifyPin(_pin)) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _pin = '';
          _errorMessage = 'PIN incorrecto.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esOscuro = widget.estadoApp.esTemaOscuro;
    final colorPrincipal = widget.estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorFondo = esOscuro ? const Color(0xFF0A0A0A) : Colors.white;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linea de arrastre superior
            Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: colorTexto.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _confirming ? 'Confirma tu PIN' : 'Crea tu Código PIN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colorTexto,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _confirming
                  ? 'Vuelve a introducir el PIN de 4 dígitos.'
                  : 'Ingresa 4 dígitos para proteger la aplicación.',
              style: TextStyle(
                fontSize: 12,
                color: colorTexto.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // Visualizador de burbujas del PIN
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final hasChar = index < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasChar
                        ? colorPrincipal
                        : (esOscuro ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
                    border: Border.all(
                      color: hasChar ? colorPrincipal : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            
            // Mensaje de error si los PINs no coinciden
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().shake(duration: 400.ms),

            const SizedBox(height: 36),

            // Teclado numérico táctil
            _buildNumpad(colorTexto, esOscuro),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad(Color colorTexto, bool esOscuro) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumpadButton('1', colorTexto, esOscuro),
            _buildNumpadButton('2', colorTexto, esOscuro),
            _buildNumpadButton('3', colorTexto, esOscuro),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumpadButton('4', colorTexto, esOscuro),
            _buildNumpadButton('5', colorTexto, esOscuro),
            _buildNumpadButton('6', colorTexto, esOscuro),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNumpadButton('7', colorTexto, esOscuro),
            _buildNumpadButton('8', colorTexto, esOscuro),
            _buildNumpadButton('9', colorTexto, esOscuro),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Boton vacio para centrar el cero
            const SizedBox(width: 70, height: 70),
            _buildNumpadButton('0', colorTexto, esOscuro),
            _buildNumpadButton('clear', colorTexto, esOscuro, isSpecial: true),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadButton(String value, Color colorTexto, bool esOscuro, {bool isSpecial = false}) {
    final isClear = value == 'clear';
    
    return InteractiveScale(
      onTap: () => _handleKeyPress(value),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSpecial
              ? Colors.transparent
              : (esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
        ),
        alignment: Alignment.center,
        child: isClear
            ? Icon(
                Icons.backspace_rounded,
                color: colorTexto.withValues(alpha: 0.6),
                size: 20,
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
