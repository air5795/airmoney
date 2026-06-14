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
import 'subvistas/ajustes_tipo_cambio.dart';
import 'subvistas/ajustes_seguridad.dart';
import 'subvistas/ajustes_voz.dart';
import 'subvistas/ajustes_notificacion_fija.dart';
import 'subvistas/ajustes_sincronizacion.dart';
import 'subvistas/ajustes_respaldos.dart';
import '../../widgets/interactive_scale.dart';

class VistaAjustes extends StatefulWidget {
  const VistaAjustes({super.key});

  @override
  State<VistaAjustes> createState() => _VistaAjustesState();
}

class _VistaAjustesState extends State<VistaAjustes> {
  bool _isDeleting = false;
  final ServicioAutenticacion _servicioAuth = ServicioAutenticacion();

  Future<void> _handleLogout() async {
    try {
      final estadoApp = Provider.of<EstadoApp>(context, listen: false);
      await _servicioAuth.signOut();
      await estadoApp.clearAllData();
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

  Future<void> _showClearLocalDataConfirmation() async {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              '¿Borrar datos locales?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: colorTexto,
              ),
            ),
            content: Text(
              'Esta acción borrará permanentemente todos tus datos financieros de este dispositivo. No podrás recuperarlos si no has sincronizado con la nube.',
              style: TextStyle(
                color: colorTexto.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: colorTexto.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await estadoApp.clearAllData();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const PantallaLogin()),
                  );
                },
                child: const Text(
                  'Borrar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteAccountConfirmation() async {
    final estadoApp = Provider.of<EstadoApp>(context, listen: false);
    final user = _servicioAuth.currentUser;
    if (user == null) return;

    final esOscuro = estadoApp.esTemaOscuro;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              '¿Eliminar tu cuenta?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: colorTexto,
              ),
            ),
            content: Text(
              'Esta acción borrará permanentemente todos tus datos financieros de la nube y tu cuenta. Esta acción no se puede deshacer.',
              style: TextStyle(
                color: colorTexto.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: colorTexto.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  final mainNavigator = Navigator.of(this.context);
                  Navigator.of(context).pop(); // Cerrar diálogo de confirmación
                  
                  setState(() {
                    _isDeleting = true;
                  });

                  try {
                    final uid = user.uid;
                    await estadoApp.eliminarDatosNubeYLocal(uid);
                    await _servicioAuth.deleteFirebaseAccount();

                    mainNavigator.pushReplacement(
                      MaterialPageRoute(builder: (_) => const PantallaLogin()),
                    );
                  } catch (e) {
                    debugPrint('Error al eliminar la cuenta: $e');
                    if (!mounted) return;
                    setState(() {
                      _isDeleting = false;
                    });
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al eliminar la cuenta. Inténtalo de nuevo.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);

    Widget cuerpoSettings;
    if (estadoApp.selectedSettingsSubView == 1) {
      cuerpoSettings = AjustesApariencia(
        onBack: () {
          estadoApp.selectedSettingsSubView = 0;
        },
      );
    } else if (estadoApp.selectedSettingsSubView == 2) {
      cuerpoSettings = AjustesCuentas(
        onBack: () {
          estadoApp.selectedSettingsSubView = 0;
        },
      );
    } else if (estadoApp.selectedSettingsSubView == 3) {
      cuerpoSettings = AjustesCategorias(
        onBack: () {
          estadoApp.selectedSettingsSubView = 0;
        },
      );
    } else if (estadoApp.selectedSettingsSubView == 4) {
      cuerpoSettings = AjustesTipoCambio(
        onBack: () {
          estadoApp.selectedSettingsSubView = 0;
        },
      );
    } else if (estadoApp.selectedSettingsSubView == 5) {
      cuerpoSettings = AjustesSeguridad(
        onBack: () {
          estadoApp.selectedSettingsSubView = 0;
        },
      );
    } else if (estadoApp.selectedSettingsSubView == 6) {
      cuerpoSettings = AjustesVoz(
        onBack: () {
          estadoApp.selectedSettingsSubView = 0;
        },
      );
    } else if (estadoApp.selectedSettingsSubView == 7) {
      cuerpoSettings = AjustesNotificacionFija(
        onBack: () {
          estadoApp.selectedSettingsSubView = 0;
        },
      );
    } else if (estadoApp.selectedSettingsSubView == 8) {
      cuerpoSettings = AjustesSincronizacion(
        onBack: () {
          estadoApp.selectedSettingsSubView = 0;
        },
      );
    } else if (estadoApp.selectedSettingsSubView == 9) {
      cuerpoSettings = AjustesRespaldos(
        onBack: () {
          estadoApp.selectedSettingsSubView = 0;
        },
      );
    } else {
      cuerpoSettings = _buildMainSettingsMenu(estadoApp);
    }

    if (_isDeleting) {
      final esOscuro = estadoApp.esTemaOscuro;
      final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 150.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: estadoApp.colorPrincipal,
                strokeWidth: 3.5,
              ),
              const SizedBox(height: 24),
              Text(
                'Eliminando tu cuenta...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorTexto,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Borrando datos financieros de forma permanente...',
                style: TextStyle(
                  fontSize: 12,
                  color: colorTexto.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
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
        const SizedBox(height: 20),
        // Bento Card: Estado de Sincronización y Seguridad de Datos
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: esOscuro
                  ? const Color(0xFF0E0E0E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: esOscuro
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: esOscuro ? 0.20 : 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ESTADO DE DATOS Y SEGURIDAD',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: colorTexto.withValues(alpha: 0.5),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: esOscuro ? 0.15 : 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, size: 10, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'AES-256 Cifrado',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorPrincipal.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_done_rounded,
                        color: colorPrincipal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sincronización en la Nube',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: colorTexto,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user != null
                                ? 'Copia de seguridad activa y sincronizada'
                                : 'Modo Sin Conexión',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorTexto.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
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
                    ? const Color(0xFF0A0A0A).withValues(alpha: 0.45)
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
                      estadoApp.selectedSettingsSubView = 2;
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.category_rounded,
                    title: 'Categorías',
                    subtitle: 'Gestionar categorías y subcategorías',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      estadoApp.selectedSettingsSubView = 3;
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.color_lens_rounded,
                    title: 'Apariencia',
                    subtitle: 'Modo oscuro y color de acento',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      estadoApp.selectedSettingsSubView = 1;
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.currency_exchange_rounded,
                    title: 'Tipo de Cambio',
                    subtitle: 'Configurar tasa referencial del dolar',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      estadoApp.selectedSettingsSubView = 4;
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.security_rounded,
                    title: 'Seguridad',
                    subtitle: 'Huella digital y código PIN de acceso',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      estadoApp.selectedSettingsSubView = 5;
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.psychology_rounded,
                    title: 'Asistente de Voz',
                    subtitle: 'Configurar API Key de Google Gemini',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      estadoApp.selectedSettingsSubView = 6;
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notificación Fija',
                    subtitle: 'Mostrar resumen financiero persistente en el celular',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      estadoApp.selectedSettingsSubView = 7;
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.sync_rounded,
                    title: 'Sincronización',
                    subtitle: 'Gestionar copia de seguridad en la nube',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      estadoApp.selectedSettingsSubView = 8;
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                  ),
                  _buildSettingsMenuItem(
                    icon: Icons.backup_rounded,
                    title: 'Respaldos',
                    subtitle: 'Exportar e importar datos locales',
                    color: colorPrincipal,
                    esOscuro: esOscuro,
                    onTap: () {
                      estadoApp.selectedSettingsSubView = 9;
                    },
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: esOscuro
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                  ),
                  if (user == null) ...[
                    _buildSettingsMenuItem(
                      icon: Icons.cloud_upload_rounded,
                      title: 'Vincular Cuenta (Google)',
                      subtitle: 'Sincronizar tus datos locales con la nube',
                      color: colorPrincipal,
                      esOscuro: esOscuro,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PantallaLogin()),
                        );
                      },
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: esOscuro
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                    ),
                    _buildSettingsMenuItem(
                      icon: Icons.delete_sweep_rounded,
                      title: 'Borrar Datos Locales',
                      subtitle: 'Limpiar base de datos local de este dispositivo',
                      color: Colors.redAccent,
                      esOscuro: esOscuro,
                      isDestructive: true,
                      onTap: _showClearLocalDataConfirmation,
                    ),
                  ] else ...[
                    _buildSettingsMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Cerrar Sesión',
                      subtitle: 'Salir de la cuenta actual',
                      color: Colors.redAccent,
                      esOscuro: esOscuro,
                      isDestructive: true,
                      onTap: _handleLogout,
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: esOscuro
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFF0A0A0A).withValues(alpha: 0.05),
                    ),
                    _buildSettingsMenuItem(
                      icon: Icons.delete_forever_rounded,
                      title: 'Eliminar Cuenta',
                      subtitle: 'Borrar permanentemente todos tus datos',
                      color: Colors.redAccent,
                      esOscuro: esOscuro,
                      isDestructive: true,
                      onTap: _showDeleteAccountConfirmation,
                    ),
                  ],
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
    return InteractiveScale(
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
