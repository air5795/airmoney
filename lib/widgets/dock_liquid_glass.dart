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

class _DockLiquidGlassState extends State<DockLiquidGlass> with SingleTickerProviderStateMixin {
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

  // Mapear los índices de pestañas (0, 1, 2, 3) a las 5 columnas físicas del Row
  int _getSlotFromIndex(int index) {
    if (index == 0) return 0;
    if (index == 1) return 1;
    if (index == 2) return 3; // El slot 2 (medio) está reservado para el botón Agregar
    if (index == 3) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;

    // Colores de fondo de alta gama con opacidad calibrada para solidez
    final colorFondoDock = esOscuro
        ? const Color(0xFF0A0A0A).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.75);
        
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
          final slotWidth = totalWidth / 5.0; // 5 columnas exactas

          final double oldSlot = _getSlotFromIndex(_oldIndex).toDouble();
          final double newSlot = _getSlotFromIndex(_currentIndex).toDouble();

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Floating Voice Hint Card pointing to the + button
              if (!_hasDismissedVoiceHint)
                Positioned(
                  bottom: 78, // Float above the 66px tall dock
                  left: (totalWidth - 220) / 2, // Centered (card width is 220)
                  width: 220,
                  child: _buildVoiceHintCard(estadoApp, esOscuro),
                ),
              Container(
                height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(33),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: esOscuro ? 0.20 : 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(33),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorFondoDock,
                        borderRadius: BorderRadius.circular(33),
                        border: Border.all(
                          color: colorBordeDock,
                          width: 1.0,
                        ),
                      ),
                      child: Stack(
                        children: [
                      // 💧 GOTA DE LIQUIDO VISCOSO EN SEGUNDO PLANO (MORPHING FLUID SELECTION INDICATOR)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final double t = _slideAnimation.value;
                          final double currentSlot = lerpDouble(oldSlot, newSlot, t)!;
                          final double centerX = (currentSlot + 0.5) * slotWidth;

                          // Dynamic base width depending on selected tab label length
                          double getBaseWidth(int index) {
                            if (index == 0) return 56.0; // "Inicio"
                            if (index == 1) return 78.0; // "Movimientos"
                            if (index == 2) return 80.0; // "Estadísticas"
                            if (index == 3) return 58.0; // "Ahorro"
                            return 56.0;
                          }

                          final double oldBaseWidth = getBaseWidth(_oldIndex);
                          final double newBaseWidth = getBaseWidth(_currentIndex);
                          final double baseWidth = lerpDouble(oldBaseWidth, newBaseWidth, t)!;

                          final double diff = (newSlot - oldSlot).abs();
                          // Elastic dynamic stretching based on traveling speed
                          final double stretch = 20.0 * sin(t * pi) * diff;
                          final double width = baseWidth + stretch;
                          // Volume conservation
                          final double height = 52.0 - (stretch * 0.10);

                          final double left = centerX - width / 2.0;
                          // Centrar exactamente en la posición media del dock (y = 33.0) para englobar icono + texto
                          final double top = 33.0 - height / 2.0;

                          return Positioned(
                            left: left,
                            top: top,
                            width: width,
                            height: height,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(height / 2.0),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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

                      // CAPA DE ICONOS SOBREPUESTA EN ROW EQUITATIVO
                      Row(
                        children: [
                          _buildDockItem(0, Icons.home_rounded, 'Inicio', estadoApp),
                          _buildDockItem(1, Icons.receipt_long_rounded, 'Movimientos', estadoApp),
                          // El botón central Agregar ocupa exactamente 1 sección Expanded para balancear la cuadrícula
                          Expanded(
                            child: Center(
                              child: _buildAddDockButton(colorPrincipal, esOscuro),
                            ),
                          ),
                          _buildDockItem(2, Icons.bar_chart_rounded, 'Estadísticas', estadoApp),
                          _buildDockItem(3, Icons.savings_rounded, 'Ahorro', estadoApp),
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
    final isColorPrincipalBlanco = colorPrincipal.toARGB32() == Colors.white.toARGB32();
    final iconColor = isColorPrincipalBlanco ? const Color(0xFF020617) : Colors.white;
    return GestureDetector(
      onTap: widget.onAddPressed,
      onLongPress: widget.onAddLongPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorPrincipal,
              Color.lerp(colorPrincipal, Colors.white, 0.15)!,
            ],
          ),
          boxShadow: [
            // Soft base shadow
            BoxShadow(
              color: colorPrincipal.withValues(alpha: esOscuro ? 0.35 : 0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            // Inner glow effect / top sheen shadow
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.25),
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
          child: Icon(
            Icons.add_rounded,
            color: iconColor,
            size: 26,
          ),
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
    final isColorPrincipalBlanco = activeColor.toARGB32() == Colors.white.toARGB32();
    final activeContentColor = isColorPrincipalBlanco ? const Color(0xFF020617) : Colors.white;

    final inactiveColor = esOscuro
        ? Colors.white.withValues(alpha: 0.35)
        : const Color(0xFF0F172A).withValues(alpha: 0.40);

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onIndexSelected(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(
                  icon,
                  color: activeContentColor,
                  size: 21,
                )
              else
                Icon(
                  icon,
                  color: inactiveColor,
                  size: 21,
                ),
              const SizedBox(height: 3),
              Text(
                label,
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
          
          // Little pointer pointing down towards the + button
          Positioned(
            bottom: -14,
            left: 100, // Center of the 220px card (110 - 10 for width offset)
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
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2.0));

    // 1. Viscous solid fluid fill with 80% opacity
    final fillPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.80)
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
