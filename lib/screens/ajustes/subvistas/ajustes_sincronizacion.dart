import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/estado_app.dart';
import '../../../services/servicio_autenticacion.dart';
import '../../../widgets/interactive_scale.dart';

class AjustesSincronizacion extends StatefulWidget {
  final VoidCallback onBack;

  const AjustesSincronizacion({
    super.key,
    required this.onBack,
  });

  @override
  State<AjustesSincronizacion> createState() => _AjustesSincronizacionState();
}

class _AjustesSincronizacionState extends State<AjustesSincronizacion> {
  bool _isSyncing = false;

  Future<void> _ejecutarSincronizacion(EstadoApp estadoApp) async {
    final user = ServicioAutenticacion().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo Sin Conexión. Vincula tu cuenta para poder sincronizar.'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      final bool syncSuccess = await estadoApp.sincronizarConNube(user.uid);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(syncSuccess
              ? 'Sincronización manual completada con éxito.'
              : 'No se pudo sincronizar. Verifica tu conexión a internet.'),
          backgroundColor: syncSuccess ? const Color(0xFF10B981) : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error inesperado al sincronizar.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorTexto = esOscuro ? Colors.white : const Color(0xFF0F172A);
    final colorSecundario = esOscuro ? const Color(0xFF64748B) : const Color(0xFF475569);
    final user = ServicioAutenticacion().currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            InteractiveScale(
              onTap: widget.onBack,
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
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Sincronización',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colorTexto,
            letterSpacing: -0.8,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          'COPIA DE SEGURIDAD EN TIEMPO REAL',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colorTexto.withValues(alpha: 0.4),
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 24),

        // Bento card principal de explicación
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorPrincipal.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          user != null ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                          color: colorPrincipal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user != null ? 'Respaldo en la Nube Activo' : 'Modo Sin Conexión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorTexto,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user != null ? user.email : 'Tus datos solo se guardan en este dispositivo.',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorSecundario,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¿Qué hace la sincronización manual?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorTexto,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este botón fuerza una conexión manual instantánea con el servidor en la nube. Si has tenido cortes de internet o si usas la aplicación en múltiples dispositivos, esta acción forzará la descarga del último estado guardado y restablecerá la escucha en tiempo real de tus transacciones y cuentas.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorSecundario,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  InteractiveScale(
                    onTap: _isSyncing ? null : () => _ejecutarSincronizacion(estadoApp),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isSyncing
                            ? colorPrincipal.withValues(alpha: 0.6)
                            : colorPrincipal,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: colorPrincipal.withValues(alpha: esOscuro ? 0.3 : 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isSyncing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sync_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Sincronizar Ahora',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 450.ms, delay: 150.ms),
        const SizedBox(height: 100),
      ],
    );
  }
}
