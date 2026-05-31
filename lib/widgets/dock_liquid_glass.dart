import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/estado_app.dart';

class DockLiquidGlass extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexSelected;
  final VoidCallback onAddPressed;

  const DockLiquidGlass({
    super.key,
    required this.selectedIndex,
    required this.onIndexSelected,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;

    // Colores de fondo de alta gama con opacidad calibrada para solidez
    final colorFondoDock = esOscuro
        ? const Color(0xFF0D0E15).withValues(alpha: 0.75)
        : Colors.white.withValues(alpha: 0.88);
        
    // Bordes micro-delgados sumamente sutiles
    final colorBordeDock = esOscuro
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: esOscuro ? 0.20 : 0.04),
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colorFondoDock,
                borderRadius: BorderRadius.circular(33),
                border: Border.all(
                  color: colorBordeDock,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDockItem(0, Icons.home_rounded, 'Inicio', estadoApp),
                  _buildDockItem(1, Icons.receipt_long_rounded, 'Movimientos', estadoApp),
                  _buildAddDockButton(colorPrincipal, esOscuro),
                  _buildDockItem(2, Icons.bar_chart_rounded, 'Estadísticas', estadoApp),
                  _buildDockItem(3, Icons.settings_rounded, 'Ajustes', estadoApp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddDockButton(Color colorPrincipal, bool esOscuro) {
    return GestureDetector(
      onTap: onAddPressed,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorPrincipal,
          boxShadow: [
            BoxShadow(
              color: colorPrincipal.withValues(alpha: esOscuro ? 0.30 : 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 24,
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
    final isSelected = selectedIndex == index;
    final activeColor = estadoApp.colorPrincipal;
    final esOscuro = estadoApp.esTemaOscuro;
    final inactiveColor = esOscuro
        ? Colors.white.withValues(alpha: 0.40)
        : const Color(0xFF0F172A).withValues(alpha: 0.45);

    return Expanded(
      child: GestureDetector(
        onTap: () => onIndexSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: esOscuro ? 0.10 : 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
