import 'package:flutter/material.dart';

class PintorPapelCuaderno extends CustomPainter {
  final bool esTemaOscuro;
  final Color colorAcento;

  const PintorPapelCuaderno({
    required this.esTemaOscuro,
    required this.colorAcento,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Pintar gradiente de fondo para profundidad
    final paintFondo = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: esTemaOscuro
            ? [
                const Color(0xFF090A0F),
                const Color(0xFF12131C),
              ]
            : [
                const Color(0xFFF8FAFC),
                const Color(0xFFEEF2F6),
              ],
      ).createShader(rect);
    
    canvas.drawRect(rect, paintFondo);

    // Pintar destello central sutil para aumentar la profundidad
    final paintCentro = Paint()
      ..shader = RadialGradient(
        colors: [
          colorAcento.withValues(alpha: esTemaOscuro ? 0.08 : 0.12),
          colorAcento.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.45),
        radius: size.width * 0.65,
      ));
    
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      size.width * 0.65,
      paintCentro,
    );
  }

  @override
  bool shouldRepaint(covariant PintorPapelCuaderno oldDelegate) =>
      oldDelegate.esTemaOscuro != esTemaOscuro ||
      oldDelegate.colorAcento != colorAcento;
}
