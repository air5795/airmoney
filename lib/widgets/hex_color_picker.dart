import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'interactive_scale.dart';

class HexColorPicker extends StatefulWidget {
  final String currentColorHex;
  final ValueChanged<String> onColorChanged;
  final bool esOscuro;
  final Color colorPrincipal;
  final List<String>? customColors;

  const HexColorPicker({
    super.key,
    required this.currentColorHex,
    required this.onColorChanged,
    required this.esOscuro,
    required this.colorPrincipal,
    this.customColors,
  });

  @override
  State<HexColorPicker> createState() => _HexColorPickerState();
}

class _HexColorPickerState extends State<HexColorPicker> {
  late HSVColor _hsvColor;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(_parseHexColor(widget.currentColorHex));
    _hexController = TextEditingController(
      text: widget.currentColorHex.replaceFirst('#', '').toLowerCase(),
    );
  }

  @override
  void didUpdateWidget(covariant HexColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentColorHex != oldWidget.currentColorHex) {
      final newColor = _parseHexColor(widget.currentColorHex);
      setState(() {
        _hsvColor = HSVColor.fromColor(newColor);
        _hexController.text = widget.currentColorHex.replaceFirst('#', '').toLowerCase();
      });
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hex) {
    try {
      final cleanHex = hex.trim().replaceFirst('#', '');
      if (cleanHex.length == 6) {
        return Color(int.parse('0xFF$cleanHex'));
      } else if (cleanHex.length == 8) {
        return Color(int.parse('0x$cleanHex'));
      }
    } catch (e) {
      debugPrint('Error parsing color: $e');
    }
    return widget.colorPrincipal;
  }

  String _toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _updateColor(HSVColor newHSV) {
    setState(() {
      _hsvColor = newHSV;
      _hexController.text = _toHex(newHSV.toColor()).replaceFirst('#', '').toLowerCase();
    });
    widget.onColorChanged(_toHex(newHSV.toColor()));
  }

  @override
  Widget build(BuildContext context) {
    final colorTexto = widget.esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorCard = widget.esOscuro
        ? const Color(0xFF0E0E0E)
        : Colors.white;
        
    final colorPill = widget.esOscuro
        ? const Color(0xFF1E1E1E).withValues(alpha: 0.8)
        : const Color(0xFFF1F5F9);

    final double s = _hsvColor.saturation;
    final double v = _hsvColor.value;
    final double hue = _hsvColor.hue;

    final Color pureHueColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    return Container(
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.esOscuro
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.esOscuro ? 0.20 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title "Color picker"
          Text(
            'Color picker',
            style: TextStyle(
              color: colorTexto,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // 2D Saturation-Value box
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  void handleGesture(Offset localPos) {
                    final double clampedX = localPos.dx.clamp(0.0, width);
                    final double clampedY = localPos.dy.clamp(0.0, height);
                    final double newS = clampedX / width;
                    final double newV = 1.0 - (clampedY / height);
                    _updateColor(_hsvColor.withSaturation(newS).withValue(newV));
                  }

                  return GestureDetector(
                    onPanStart: (details) => handleGesture(details.localPosition),
                    onPanUpdate: (details) => handleGesture(details.localPosition),
                    onTapDown: (details) => handleGesture(details.localPosition),
                    child: Stack(
                      children: [
                        // 1. Pure hue color background
                        Positioned.fill(
                          child: Container(
                            color: pureHueColor,
                          ),
                        ),
                        // 2. Horizontal Saturation gradient (white to transparent)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.white.withValues(alpha: 0.0)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        // 3. Vertical Value gradient (transparent to black)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // 4. White circle target ring selection
                        Positioned(
                          left: (s * width) - 10,
                          top: ((1.0 - v) * height) - 10,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hue Slider and Eyedropper Row
          Row(
            children: [
              // Hue Rainbow Slider
              Expanded(
                child: SizedBox(
                  height: 36, // Large padding for comfortable touch
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      void handleHueGesture(Offset localPos) {
                        final double clampedX = localPos.dx.clamp(0.0, width);
                        final double newH = (clampedX / width) * 360.0;
                        _updateColor(_hsvColor.withHue(newH.clamp(0.0, 360.0)));
                      }

                      return GestureDetector(
                        onPanStart: (details) => handleHueGesture(details.localPosition),
                        onPanUpdate: (details) => handleHueGesture(details.localPosition),
                        onTapDown: (details) => handleHueGesture(details.localPosition),
                        behavior: HitTestBehavior.opaque,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Rainbow gradient bar
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red,
                                    Colors.yellow,
                                    Colors.green,
                                    Colors.cyan,
                                    Colors.blue,
                                    const Color(0xFFFF00FF), // Magenta
                                    Colors.red,
                                  ],
                                ),
                              ),
                            ),
                            // Handle
                            Positioned(
                              left: ((hue / 360.0) * width).clamp(0.0, width) - 10,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: _hsvColor.toColor(),
                                    width: 3.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Eyedropper Button
              InteractiveScale(
                onTap: () {
                  final random = Random();
                  final List<Color> beautifulColors = [
                    const Color(0xFF3B82F6), // Blue
                    const Color(0xFFEF4444), // Red
                    const Color(0xFF10B981), // Emerald
                    const Color(0xFFF59E0B), // Amber
                    const Color(0xFF8B5CF6), // Purple
                    const Color(0xFFEC4899), // Pink
                    const Color(0xFF06B6D4), // Cyan
                    const Color(0xFF14B8A6), // Teal
                    const Color(0xFFF97316), // Orange
                    const Color(0xFF84CC16), // Lime
                  ];
                  final randomColor = beautifulColors[random.nextInt(beautifulColors.length)];
                  _updateColor(HSVColor.fromColor(randomColor));
                },
                child: Container(
                  width: 44,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorPill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.colorize_rounded,
                    color: colorTexto.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hex Picker Dropdown & Input Container
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: colorPill,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // "Hex" dropdown button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hex',
                      style: TextStyle(
                        color: colorTexto.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorTexto.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ],
                ),
                
                // Vertical divider line
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: VerticalDivider(
                    color: colorTexto.withValues(alpha: 0.1),
                    width: 1.0,
                    thickness: 1.0,
                  ),
                ),

                // Hex TextInput Field
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    style: TextStyle(
                      color: colorTexto,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLength: 6,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                    decoration: InputDecoration(
                      hintText: 'ffffff',
                      hintStyle: TextStyle(
                        color: colorTexto.withValues(alpha: 0.25),
                      ),
                      prefixText: '#',
                      prefixStyle: TextStyle(
                        color: colorTexto.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      final cleaned = val.trim().replaceAll('#', '');
                      if (cleaned.length == 6) {
                        final regExp = RegExp(r'^[0-9a-fA-F]{6}$');
                        if (regExp.hasMatch(cleaned)) {
                          final newColor = Color(int.parse('0xFF$cleaned'));
                          setState(() {
                            _hsvColor = HSVColor.fromColor(newColor);
                          });
                          widget.onColorChanged('#${cleaned.toUpperCase()}');
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
