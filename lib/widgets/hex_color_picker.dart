import 'package:flutter/material.dart';

class HexColorPicker extends StatelessWidget {
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

  static final List<String> _pastelColors = [
    '#FFE0B2',
    '#F8BBD0',
    '#D1C4E9',
    '#C8E6C9',
    '#B3E5FC',
    '#FFF9C4',
    '#FFCCBC',
    '#E2E8F0',
    '#E0F7FA',
    '#D0F0C0',
  ];

  @override
  Widget build(BuildContext context) {
    final TextEditingController hexInputController = TextEditingController(
      text: currentColorHex.replaceFirst('#', ''),
    );
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorsToUse = customColors ?? _pastelColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colorsToUse.map((hexStr) {
            final isSelected = hexStr.toLowerCase() == currentColorHex.toLowerCase();
            final colorVal = Color(int.parse(hexStr.replaceFirst('#', '0xFF')));

            return GestureDetector(
              onTap: () {
                onColorChanged(hexStr);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorVal,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? (esOscuro ? Colors.white : const Color(0xFF0F172A))
                        : Colors.white.withValues(alpha: esOscuro ? 0.2 : 0.6),
                    width: isSelected ? 2.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? colorVal.withValues(alpha: esOscuro ? 0.4 : 0.3)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: isSelected ? 10 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: esOscuro ? Colors.black87 : Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(int.parse(currentColorHex.replaceFirst('#', '0xFF'))),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: esOscuro ? 0.15 : 0.5),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: hexInputController,
                style: TextStyle(
                  color: colorTexto,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLength: 6,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                decoration: InputDecoration(
                  hintText: 'Ej. FFE0B2',
                  hintStyle: TextStyle(
                    color: colorTexto.withValues(alpha: 0.3),
                  ),
                  prefixText: ' # ',
                  prefixStyle: TextStyle(
                    color: colorPrincipal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: esOscuro ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: esOscuro ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorPrincipal,
                      width: 1.0,
                    ),
                  ),
                ),
                onChanged: (val) {
                  final cleaned = val.trim().replaceAll('#', '');
                  if (cleaned.length == 6) {
                    final regExp = RegExp(r'^[0-9a-fA-F]{6}$');
                    if (regExp.hasMatch(cleaned)) {
                      onColorChanged('#${cleaned.toUpperCase()}');
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
