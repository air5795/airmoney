import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/estado_app.dart';
import '../../../widgets/hex_color_picker.dart';

class AjustesApariencia extends StatelessWidget {
  final VoidCallback onBack;

  const AjustesApariencia({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    final List<Color> selectorColores = [
      const Color(0xFFFF2D55),
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFF5856D6),
      const Color(0xFFFFCC00),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onBack,
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
                  fontWeight: FontWeight.w600,
                  color: colorPrincipal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Apariencia',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colorTexto,
            letterSpacing: -0.8,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          'PERSONALIZAR ASPECTO',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorTexto.withValues(alpha: 0.4),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 24),
        // Contenedor acrilico premium
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: esOscuro
                    ? const Color(0xFF0D0E15).withValues(alpha: 0.45)
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
                              Icons.dark_mode_rounded,
                              color: colorPrincipal,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Modo Oscuro',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colorTexto,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Alternar tema de la aplicación',
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
                      Switch.adaptive(
                        value: esOscuro,
                        activeThumbColor: colorPrincipal,
                        onChanged: (val) {
                          estadoApp.toggleTema(val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0D0E15).withValues(alpha: 0.05),
                  ),
                  const SizedBox(height: 24),
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
                          Icons.color_lens_rounded,
                          color: colorPrincipal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Color Principal',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Personalizar acentos y dock',
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
                  const SizedBox(height: 16),
                  // Muestras circulares con sombras
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: selectorColores.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final colorSel = selectorColores[index];
                        final isSelectedColor = colorPrincipal.toARGB32() == colorSel.toARGB32();

                        return GestureDetector(
                          onTap: () {
                            estadoApp.setColorPrincipal(colorSel);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorSel,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelectedColor
                                    ? (esOscuro ? Colors.white : const Color(0xFF0F172A))
                                    : Colors.white.withValues(alpha: esOscuro ? 0.15 : 0.5),
                                width: isSelectedColor ? 2.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelectedColor
                                      ? colorSel.withValues(alpha: esOscuro ? 0.35 : 0.25)
                                      : Colors.black.withValues(alpha: 0.04),
                                  blurRadius: isSelectedColor ? 10 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelectedColor
                                ? const Center(
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0D0E15).withValues(alpha: 0.05),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Color de Acento Personalizado (Hexadecimal)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorTexto,
                    ),
                  ),
                  const SizedBox(height: 12),
                  HexColorPicker(
                    currentColorHex: '#${colorPrincipal.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                    onColorChanged: (hex) {
                      final parsedColor = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                      estadoApp.setColorPrincipal(parsedColor);
                    },
                    esOscuro: esOscuro,
                    colorPrincipal: colorPrincipal,
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
