import 'dart:ui';
import 'package:flutter/material.dart';

// Tipos de notificaciones del Toast
enum TipoToast { exito, error, info }

class ToastIOS extends StatefulWidget {
  final String mensaje;
  final TipoToast tipo;
  final VoidCallback onDismissed;

  const ToastIOS({
    required this.mensaje,
    required this.tipo,
    required this.onDismissed,
    super.key,
  });

  @override
  State<ToastIOS> createState() => _ToastIOSState();
}

class _ToastIOSState extends State<ToastIOS> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
      vsync: this,
    );

    // Animacion de entrada con rebote estilo iOS
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Desvanecer automaticamente despues de 2.8 segundos
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool esOscuro = Theme.of(context).brightness == Brightness.dark;
    
    IconData icon;
    Color colorIcon;
    
    // Selector de icono y colores por tipo
    switch (widget.tipo) {
      case TipoToast.exito:
        icon = Icons.check_circle_rounded;
        colorIcon = const Color(0xFF10B981);
        break;
      case TipoToast.error:
        icon = Icons.error_rounded;
        colorIcon = const Color(0xFFEF4444);
        break;
      case TipoToast.info:
        icon = Icons.info_rounded;
        colorIcon = const Color(0xFF3B82F6);
        break;
    }

    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, left: 24, right: 24),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: esOscuro
                            ? const Color(0xFF0D0E15).withValues(alpha: 0.70)
                            : Colors.white.withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: esOscuro
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colorIcon.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                color: colorIcon,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              widget.mensaje,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorTexto,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Control estatico global de notificaciones
class ToastHelper {
  static OverlayEntry? _currentOverlay;

  static void _show(BuildContext context, String mensaje, TipoToast tipo) {
    // Remover el toast anterior para no superponerlos
    try {
      _currentOverlay?.remove();
    } catch (_) {}
    _currentOverlay = null;

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => ToastIOS(
        mensaje: mensaje,
        tipo: tipo,
        onDismissed: () {
          try {
            _currentOverlay?.remove();
          } catch (_) {}
          _currentOverlay = null;
        },
      ),
    );

    _currentOverlay = entry;
    overlay.insert(entry);
  }

  static void showSuccess(BuildContext context, String mensaje) {
    _show(context, mensaje, TipoToast.exito);
  }

  static void showError(BuildContext context, String mensaje) {
    _show(context, mensaje, TipoToast.error);
  }

  static void showInfo(BuildContext context, String mensaje) {
    _show(context, mensaje, TipoToast.info);
  }
}
