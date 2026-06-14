import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/estado_app.dart';
import '../services/servicio_autenticacion.dart';
import '../models/usuario_app.dart';
import 'pantalla_splash.dart';
import 'pantalla_login.dart';
import 'pantalla_bloqueo.dart';
import 'pantalla_principal.dart';
import 'onboarding/pantalla_idioma.dart';

/// Guardia de autenticacion en la raiz de la app.
///
/// Resuelve UNA vez si hay sesion persistida (con paciencia ante arranques en
/// frio) y luego reacciona a cambios (login / logout). Reemplaza la antigua
/// logica imperativa del splash y elimina la "carrera contra el timeout".
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final ServicioAutenticacion _auth = ServicioAutenticacion();
  StreamSubscription<UsuarioApp?>? _sub;

  bool _prefsListas = false;
  bool _sesionResuelta = false;
  UsuarioApp? _usuario;

  @override
  void initState() {
    super.initState();
    final estado = Provider.of<EstadoApp>(context, listen: false);
    _iniciar(estado);
  }

  Future<void> _iniciar(EstadoApp estado) async {
    // Cargar preferencias locales + un minimo breve de splash (se solapan).
    await Future.wait([
      estado.initFuture,
      Future<void>.delayed(const Duration(milliseconds: 700)),
    ]);
    if (!mounted) return;
    setState(() => _prefsListas = true);
    _resolverSesion();
  }

  Future<void> _resolverSesion() async {
    if (!_auth.isFirebaseInitialized) {
      debugPrint('[AuthGate] Firebase NO inicializado -> login');
      _resolver(null);
      return;
    }

    // Escuchar el stream para reaccionar a cambios (login/logout/restauracion).
    _sub = _auth.sesionStream.listen((u) {
      debugPrint('[AuthGate] evento sesion: ${u?.uid ?? "null"} | yaResuelta=$_sesionResuelta');
      if (_sesionResuelta) {
        // Ya resuelto: reaccion en vivo (logout te saca, re-login te entra).
        if (mounted) setState(() => _usuario = u);
      } else if (u != null) {
        _resolver(u);
      }
      // Si aun no resolvimos y u==null, esperamos al intento silencioso.
    });

    // 1. Comprobacion sincrona: si la sesion esta persistida, entra al instante.
    final User? actual = FirebaseAuth.instance.currentUser;
    debugPrint('[AuthGate] currentUser sincrono: ${actual?.uid ?? "null"}');
    if (actual != null) {
      _resolver(UsuarioApp.fromFirebase(actual));
      return;
    }

    // 2. Reingreso silencioso (clave en MIUI: Firebase Auth no logra persistir
    //    su token, pero Google Sign-In si recuerda la cuenta). Reconstruye la
    //    sesion sin mostrar nada. Mientras tanto, seguimos en el splash.
    final UsuarioApp? reingreso = await _auth.intentarReingresoSilencioso();
    if (!mounted) return;
    debugPrint('[AuthGate] reingreso silencioso: ${reingreso?.uid ?? "null"}');

    // 3. Resolver con el resultado (si el listener ya resolvio, esto es inocuo).
    if (!_sesionResuelta) {
      _resolver(reingreso);
    }
  }

  void _resolver(UsuarioApp? u) {
    if (!mounted) return;
    setState(() {
      _usuario = u;
      _sesionResuelta = true;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsListas || !_sesionResuelta) {
      return const PantallaSplash();
    }
    // Con sesion y sin un login en curso -> entrar a la app.
    if (_usuario != null && !_auth.loginEnProgreso) {
      return _SesionActiva(user: _usuario!);
    }
    // Sin sesion (o login en curso: mantener login montado para que termine).
    return const PantallaLogin();
  }
}

/// Subarbol que se muestra cuando hay una sesion activa al arrancar en frio.
///
/// 1. Si aun no hay datos locales (onboarding sin completar), sincroniza con la
///    nube antes de decidir el destino (evita rehacer onboarding y duplicar
///    cuentas en un dispositivo nuevo).
/// 2. Aplica el candado local (PIN/huella) si esta configurado.
/// 3. Enruta a Principal o al onboarding.
class _SesionActiva extends StatefulWidget {
  final UsuarioApp user;
  const _SesionActiva({required this.user});

  @override
  State<_SesionActiva> createState() => _SesionActivaState();
}

class _SesionActivaState extends State<_SesionActiva> {
  late final EstadoApp _estado;
  // Capturado UNA sola vez: cambiar el ajuste de seguridad estando dentro no
  // debe bloquear la sesion actual; aplica en el siguiente arranque.
  late final bool _requiereBloqueo;
  bool _desbloqueado = false;
  bool _bootstrapListo = false;
  bool _errorSync = false;

  @override
  void initState() {
    super.initState();
    _estado = Provider.of<EstadoApp>(context, listen: false);
    _requiereBloqueo = _estado.biometricEnabled || _estado.pinEnabled;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Solo bloqueamos el arranque sincronizando si aun no hay datos locales.
    // En el caso normal, PantallaPrincipal sincroniza en segundo plano.
    if (!_estado.hasCompletedOnboarding) {
      final bool ok = await _estado.sincronizarConNube(widget.user.uid);
      if (!mounted) return;
      if (!ok && !_estado.hasCompletedOnboarding) {
        setState(() {
          _errorSync = true;
          _bootstrapListo = true;
        });
        return;
      }
    }
    if (mounted) setState(() => _bootstrapListo = true);
  }

  void _reintentar() {
    setState(() {
      _errorSync = false;
      _bootstrapListo = false;
    });
    _bootstrap();
  }

  Future<void> _cerrarSesion() async {
    await ServicioAutenticacion().signOut();
    // El AuthGate reacciona al stream (sesion null) y muestra el login.
  }

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapListo) {
      return const PantallaSplash();
    }

    if (_errorSync) {
      return _PantallaErrorSync(
        onReintentar: _reintentar,
        onCerrarSesion: _cerrarSesion,
      );
    }

    if (_requiereBloqueo && !_desbloqueado) {
      return PantallaBloqueo(
        onUnlocked: () {
          if (mounted) setState(() => _desbloqueado = true);
        },
      );
    }

    return _estado.hasCompletedOnboarding
        ? const PantallaPrincipal()
        : const PantallaIdioma();
  }
}

/// Pantalla mostrada cuando, en un dispositivo sin datos locales, no se pudo
/// descargar la copia de la nube (sin conexion). Permite reintentar o salir.
class _PantallaErrorSync extends StatelessWidget {
  final VoidCallback onReintentar;
  final Future<void> Function() onCerrarSesion;

  const _PantallaErrorSync({
    required this.onReintentar,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorPrincipal = estadoApp.colorPrincipal;
    final colorFondo = esOscuro ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
    final colorTexto = esOscuro ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final colorSecundario = esOscuro ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: colorSecundario.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'No pudimos cargar tus datos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorTexto,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Necesitamos descargar tu copia de seguridad desde la nube. '
                  'Revisa tu conexion a internet e intenta de nuevo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: colorSecundario,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onReintentar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrincipal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => onCerrarSesion(),
                  child: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorSecundario.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
