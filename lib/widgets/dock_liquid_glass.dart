import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/estado_app.dart';

class DockLiquidGlass extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexSelected;
  final VoidCallback onAddPressed;
  final VoidCallback? onAddLongPressed;

  const DockLiquidGlass({
    super.key,
    required this.selectedIndex,
    required this.onIndexSelected,
    required this.onAddPressed,
    this.onAddLongPressed,
  });

  @override
  State<DockLiquidGlass> createState() => _DockLiquidGlassState();
}

class _DockLiquidGlassState extends State<DockLiquidGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;

  int _oldIndex = 0;
  int _currentIndex = 0;

  static bool _hasDismissedVoiceHint = false;

  @override
  void initState() {
    super.initState();
    _oldIndex = widget.selectedIndex;
    _currentIndex = widget.selectedIndex;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );

    _controller.value = 1.0;

    // Auto-dismiss voice hint card after 10 seconds
    if (!_hasDismissedVoiceHint) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _hasDismissedVoiceHint = true;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant DockLiquidGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _currentIndex) {
      setState(() {
        _oldIndex = _currentIndex;
        _currentIndex = widget.selectedIndex;
      });
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Con el botón + a la derecha, las pestañas ocupan los slots 0, 1, 2 y 3 correlativamente
  int _getSlotFromIndex(int index) {
    return index;
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;

    // Colores de fondo de alta gama con opacidad calibrada para solidez
    final colorFondoDock = esOscuro
        ? const Color(0xFF0A0A0A).withValues(alpha: 0.55)
        : const Color.fromARGB(255, 228, 228, 228).withValues(alpha: 0.75);

    // Bordes micro-delgados sumamente sutiles
    final colorBordeDock = esOscuro
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          // Se resta el ancho de los bordes laterales (2.0 de cada lado = 4.0 en total)
          final innerWidth = totalWidth - 4.0;

          // El divisor toma 17.2 píxeles de espacio interno. Los 5 elementos Expanded comparten el resto equitativamente.
          const double dividerWidth = 17.2;
          final slotWidth = (innerWidth - dividerWidth) / 5.0;

          final double oldSlot = _getSlotFromIndex(_oldIndex).toDouble();
          final double newSlot = _getSlotFromIndex(_currentIndex).toDouble();

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Floating Voice Hint Card pointing to the + button (positioned at the far right)
              if (!_hasDismissedVoiceHint)
                Positioned(
                  bottom: 80, // Float above the 68px tall dock
                  right: 2, // Aligned to the right side of the dock
                  width: 220,
                  child: _buildVoiceHintCard(estadoApp, esOscuro),
                ),
              Container(
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: esOscuro ? 0.20 : 0.03,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorFondoDock,
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(color: colorBordeDock, width: 2.0),
                      ),
                      child: Stack(
                        children: [
                          // 💧 GOTA DE LIQUIDO VISCOSO EN SEGUNDO PLANO (MORPHING FLUID SELECTION INDICATOR)
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final double t = _slideAnimation.value;
                              final double currentSlot = lerpDouble(
                                oldSlot,
                                newSlot,
                                t,
                              )!;
                              // El indicador fluido solo se mueve entre las 4 pestañas de la izquierda
                              final double centerX = (currentSlot + 0.5) * slotWidth;

                              // Dynamic base width depending on selected tab label length (slightly wider for larger icons)
                              double getBaseWidth(int index) {
                                if (index == 0) return 58.0; // "Inicio"
                                if (index == 1) return 80.0; // "Movimientos"
                                if (index == 2) return 82.0; // "Estadísticas"
                                if (index == 3) return 60.0; // "Planes"
                                return 58.0;
                              }

                              final double oldBaseWidth = getBaseWidth(
                                _oldIndex,
                              );
                              final double newBaseWidth = getBaseWidth(
                                _currentIndex,
                              );
                              final double baseWidth = lerpDouble(
                                oldBaseWidth,
                                newBaseWidth,
                                t,
                              )!;

                              final double diff = (newSlot - oldSlot).abs();
                              // Elastic dynamic stretching based on traveling speed
                              final double stretch = 20.0 * sin(t * pi) * diff;
                              final double width = baseWidth + stretch;
                              // Volume conservation
                              final double height = 54.0 - (stretch * 0.10);

                              final double left = centerX - width / 2.0;
                              // Centrar exactamente en la posición media del espacio interno del dock (y = 32.0)
                              final double top = 32.0 - height / 2.0;

                              return Positioned(
                                left: left,
                                top: top,
                                width: width,
                                height: height,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    height / 2.0,
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 5,
                                      sigmaY: 5,
                                    ),
                                    child: CustomPaint(
                                      size: Size(width, height),
                                      painter: ViscousDropletPainter(
                                        left: 0,
                                        right: width,
                                        top: 0,
                                        bottom: height,
                                        activeColor: colorPrincipal,
                                        esOscuro: esOscuro,
                                        animValue: _controller.value,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // CAPA DE ICONOS SOBREPUESTA EN ROW REDISEÑADA (Pestañas a la izquierda, Separador, + a la derecha)
                          Row(
                            children: [
                              _buildDockItem(
                                0,
                                Icons.home_rounded,
                                'Inicio',
                                estadoApp,
                              ),
                              _buildDockItem(
                                1,
                                Icons.receipt_long_rounded,
                                'Movimientos',
                                estadoApp,
                              ),
                              _buildDockItem(
                                2,
                                Icons.bar_chart_rounded,
                                'Estadísticas',
                                estadoApp,
                              ),
                              _buildDockItem(
                                3,
                                Icons.savings_rounded,
                                'Planes',
                                estadoApp,
                              ),

                              // Separador divisor
                              const SizedBox(width: 8),
                              Container(
                                width: 1.2,
                                height: 26,
                                color: colorBordeDock,
                              ),
                              const SizedBox(width: 8),

                              // El botón Agregar al extremo derecho, separado
                              Expanded(
                                child: Center(
                                  child: _buildAddDockButton(
                                    colorPrincipal,
                                    esOscuro,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddDockButton(Color colorPrincipal, bool esOscuro) {
    final isColorPrincipalBlanco =
        colorPrincipal.toARGB32() == Colors.white.toARGB32();
    
    // Si estamos en modo oscuro y el color de acento es blanco, usamos un fondo oscuro
    // para que el signo de "+" pueda ser blanco como requiere el usuario y verse estético.
    final bool useDarkButtonBg = esOscuro && isColorPrincipalBlanco;
    
    final Color colorFondoBotonStart = useDarkButtonBg
        ? const Color(0xFF1E293B) // Slate oscuro elegante
        : colorPrincipal;
        
    final Color colorFondoBotonEnd = useDarkButtonBg
        ? const Color(0xFF0F172A)
        : Color.lerp(colorPrincipal, Colors.white, 0.15)!;

    final iconColor = (useDarkButtonBg || !isColorPrincipalBlanco)
        ? Colors.white
        : const Color(0xFF020617);
        
    final Color colorSombraBoton = useDarkButtonBg
        ? Colors.black.withValues(alpha: 0.40)
        : colorPrincipal.withValues(alpha: esOscuro ? 0.35 : 0.22);

    return GestureDetector(
      onTap: widget.onAddPressed,
      onLongPress: widget.onAddLongPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorFondoBotonStart,
              colorFondoBotonEnd,
            ],
          ),
          boxShadow: [
            // Soft base shadow
            BoxShadow(
              color: colorSombraBoton,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            // Inner glow effect / top sheen shadow
            BoxShadow(
              color: Colors.white.withValues(alpha: useDarkButtonBg ? 0.08 : 0.25),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: esOscuro ? 0.15 : 0.25),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Icon(Icons.add_rounded, color: iconColor, size: 28),
        ),
      ),
    );
  }

  Widget _buildDockItem(
    int index,
    IconData icon,
    String label,
    EstadoApp estadoApp,
  ) {
    final isSelected = widget.selectedIndex == index;
    final esOscuro = estadoApp.esTemaOscuro;
    final activeColor = estadoApp.colorPrincipal;
    // El contenido activo (icono y texto) toma el color principal directamente para destacar
    // con un control de contraste por si el color de acento coincide con el del tema actual.
    final activeContentColor = (esOscuro && activeColor.toARGB32() == Colors.black.toARGB32())
        ? Colors.white
        : (!esOscuro && activeColor.toARGB32() == Colors.white.toARGB32())
            ? const Color(0xFF020617)
            : activeColor;

    final inactiveColor = esOscuro
        ? Colors.white.withValues(alpha: 0.35)
        : const Color(0xFF0F172A).withValues(alpha: 0.40);

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onIndexSelected(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(icon, color: activeContentColor, size: 24)
              else
                Icon(icon, color: inactiveColor, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  color: isSelected ? activeContentColor : inactiveColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceHintCard(EstadoApp estadoApp, bool esOscuro) {
    final colorFondo = esOscuro
        ? const Color(0xFF0F172A).withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.95);

    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorBorde = esOscuro
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorde, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              // Glowing mic icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: estadoApp.colorPrincipal.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: estadoApp.colorPrincipal,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Registro por Voz',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: colorTexto,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Mantén pulsado [+] para hablar',
                      style: TextStyle(
                        fontSize: 9.0,
                        color: colorTexto.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasDismissedVoiceHint = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    color: colorTexto.withValues(alpha: 0.40),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),

          // Little pointer pointing down towards the + button (now aligned to the right-most slot)
          Positioned(
            bottom: -14,
            right: 20.5, // Aligned with the center of the + button on the right
            child: CustomPaint(
              painter: TrianglePointerPainter(colorFondo, colorBorde),
              size: const Size(20, 8),
            ),
          ),
        ],
      ),
    );
  }
}

// 💧 DRAWING PATH VISCOUS MORPHING DROPLET PAINTER WITH CAUSTICS REFRACTION EFFECT
class ViscousDropletPainter extends CustomPainter {
  final double left;
  final double right;
  final double top;
  final double bottom;
  final Color activeColor;
  final bool esOscuro;
  final double animValue;

  ViscousDropletPainter({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.activeColor,
    required this.esOscuro,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(left, top, right, bottom);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2.0),
    );

    // Relleno de la burbuja activa con una opacidad suave para contrastar con el botón +
    final fillPaint = Paint()
      ..color = activeColor.withValues(alpha: esOscuro ? 0.15 : 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant ViscousDropletPainter oldDelegate) => true;
}

class TrianglePointerPainter extends CustomPainter {
  final Color colorFondo;
  final Color colorBorde;

  TrianglePointerPainter(this.colorFondo, this.colorBorde);

  @override
  void paint(Canvas canvas, Size size) {
    final paintFondo = Paint()
      ..color = colorFondo
      ..style = PaintingStyle.fill;

    final paintBorde = Paint()
      ..color = colorBorde
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paintFondo);

    final pathBorde = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(pathBorde, paintBorde);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
