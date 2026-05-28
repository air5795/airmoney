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

    final colorFondoDock = esOscuro
        ? const Color(0xFF0D0E15).withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.60);
        
    final colorBordeDock = esOscuro
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.65);

    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Panel de navegacion flotante acrilico
          Expanded(
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: esOscuro ? 0.25 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: colorFondoDock,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: colorBordeDock,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDockItem(context, 0, Icons.home_rounded, 'Inicio', estadoApp),
                        _buildDockItem(context, 1, Icons.receipt_long_rounded, 'Movimientos', estadoApp),
                        _buildDockItem(context, 2, Icons.bar_chart_rounded, 'Estadísticas', estadoApp),
                        _buildDockItem(context, 3, Icons.settings_rounded, 'Ajustes', estadoApp),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Boton flotante de agregar con brillo y sombra de color de acento
          GestureDetector(
            onTap: onAddPressed,
            child: Container(
              width: 60,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorPrincipal,
                    colorPrincipal.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorPrincipal.withValues(alpha: esOscuro ? 0.35 : 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    EstadoApp estadoApp,
  ) {
    final isSelected = selectedIndex == index;
    final activeColor = estadoApp.colorPrincipal;
    final esOscuro = estadoApp.esTemaOscuro;
    final inactiveColor = esOscuro
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFF0F172A).withValues(alpha: 0.45);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onIndexSelected(index);
          if (index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Seccion de Estadisticas en construccion'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: esOscuro ? 0.12 : 0.08)
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
