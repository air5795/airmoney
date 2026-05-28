import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/estado_app.dart';
import '../../services/servicio_autenticacion.dart';
import '../pantalla_login.dart';
import 'subvistas/ajustes_apariencia.dart';
import 'subvistas/ajustes_cuentas.dart';
import 'subvistas/ajustes_categorias.dart';

class VistaAjustes extends StatefulWidget {
  const VistaAjustes({super.key});

  @override
  State<VistaAjustes> createState() => _VistaAjustesState();
}

class _VistaAjustesState extends State<VistaAjustes> {
  int _settingsSubView = 0;
  final ServicioAutenticacion _servicioAuth = ServicioAutenticacion();

  Future<void> _handleLogout() async {
    try {
      await _servicioAuth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PantallaLogin()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cerrar sesion'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);

    Widget cuerpoSettings;
    if (_settingsSubView == 1) {
      cuerpoSettings = AjustesApariencia(
        onBack: () {
          setState(() {
            _settingsSubView = 0;
          });
        },
      );
    } else if (_settingsSubView == 2) {
      cuerpoSettings = AjustesCuentas(
        onBack: () {
          setState(() {
            _settingsSubView = 0;
          });
        },
      );
    } else if (_settingsSubView == 3) {
      cuerpoSettings = AjustesCategorias(
        onBack: () {
          setState(() {
            _settingsSubView = 0;
          });
        },
      );
    } else {
      cuerpoSettings = _buildMainSettingsMenu(estadoApp);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: cuerpoSettings,
    );
  }

  Widget _buildMainSettingsMenu(EstadoApp estadoApp) {
    final user = _servicioAuth.currentUser;
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Perfil de usuario circular Liquid Glass
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorPrincipal.withValues(alpha: 0.1),
                border: Border.all(
                  color: esOscuro ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.70),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: esOscuro ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                    ? Image.network(
                        user.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          final displayName = user.displayName;
                          final initial = displayName.isNotEmpty
                              ? displayName.substring(0, 1).toUpperCase()
                              : 'U';
                          return Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorPrincipal,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          (user?.displayName ?? 'U').isNotEmpty
                              ? (user?.displayName ?? 'U').substring(0, 1).toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorPrincipal,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola,',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorTexto.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.displayName ?? 'Usuario',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorTexto,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05, end: 0, duration: 350.ms),
        const SizedBox(height: 28),
        // Bloque del menu de opciones Liquid Glass
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
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
                children: [
                  _buildSettingsMenuItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Cuentas',
                    subtitle: 'Gestionar, crear y editar cuentas',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      setState(() {
                        _settingsSubView = 2;
                      });
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0D0E15).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.category_rounded,
                    title: 'Categorías',
                    subtitle: 'Gestionar categorías y subcategorías',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      setState(() {
                        _settingsSubView = 3;
                      });
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0D0E15).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.color_lens_rounded,
                    title: 'Apariencia',
                    subtitle: 'Modo oscuro y color de acento',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      setState(() {
                        _settingsSubView = 1;
                      });
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0D0E15).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar Sesión',
                    subtitle: 'Salir de la cuenta actual',
                    color: Colors.redAccent,
                    esOscuro: esOscuro,
                    isDestructive: true,
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 110),
      ],
    );
  }

  Widget _buildSettingsMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool esOscuro,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDestructive
                          ? Colors.redAccent
                          : (esOscuro ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: esOscuro ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: esOscuro ? Colors.white.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.2),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
