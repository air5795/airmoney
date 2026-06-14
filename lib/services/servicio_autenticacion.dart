import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_app.dart';

class ServicioAutenticacion {
  static final ServicioAutenticacion _instance = ServicioAutenticacion._internal();
  factory ServicioAutenticacion() => _instance;

  ServicioAutenticacion._internal() {
    _checkFirebaseStatus();
  }

  // Marca local de que existe una sesion de Google guardada en el dispositivo.
  // Permite al arranque saber si vale la pena esperar la restauracion del token.
  static const String _kSesionGoogleActiva = 'app_sesion_google_activa';

  bool _isFirebaseInitialized = false;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  bool _ultimoIntentoCancelado = false;
  /// True si el ultimo signInWithGoogle fallido fue porque el usuario
  /// cerro el selector de cuentas (no es un error real).
  bool get ultimoIntentoCancelado => _ultimoIntentoCancelado;

  /// True mientras PantallaLogin esta ejecutando su flujo completo de inicio de
  /// sesion (selector de Google, dialogo de conflicto de datos y sincronizacion).
  /// El AuthGate respeta este flag para NO cambiar de pantalla a mitad del
  /// proceso: la propia pantalla de login decide a donde navegar al terminar.
  bool loginEnProgreso = false;

  final StreamController<UsuarioApp?> _userStreamController = StreamController<UsuarioApp?>.broadcast();
  Stream<UsuarioApp?> get authStateChanges => _userStreamController.stream;

  UsuarioApp? _currentUser;
  UsuarioApp? get currentUser => _currentUser;

  /// Stream reactivo del estado de sesion para el AuthGate.
  /// Emite el usuario persistido en cuanto Firebase termina de hidratarlo
  /// (sin carreras de timeout) y mantiene [currentUser] sincronizado.
  /// Si Firebase no esta disponible, emite null (se mostrara el login).
  Stream<UsuarioApp?> get sesionStream {
    if (!_isFirebaseInitialized) {
      return Stream<UsuarioApp?>.value(null);
    }
    return FirebaseAuth.instance.authStateChanges().map((User? user) {
      if (user != null) {
        _currentUser = UsuarioApp.fromFirebase(user);
        _guardarMarcaSesion(true);
      } else {
        _currentUser = null;
      }
      return _currentUser;
    });
  }

  Future<void> _checkFirebaseStatus() async {
    try {
      Firebase.app();
      _isFirebaseInitialized = true;
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          _currentUser = UsuarioApp.fromFirebase(user);
          _userStreamController.add(_currentUser);
          _guardarMarcaSesion(true);
        } else {
          _currentUser = null;
          _userStreamController.add(null);
        }
      });
    } catch (e) {
      _isFirebaseInitialized = false;
      _currentUser = null;
      _userStreamController.add(null);
    }
  }

  Future<void> _guardarMarcaSesion(bool activa) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSesionGoogleActiva, activa);
    } catch (_) {
      // La marca es solo una optimizacion del arranque; no debe romper el flujo
    }
  }

  Future<UsuarioApp?> signInWithGoogle() async {
    _ultimoIntentoCancelado = false;
    if (_isFirebaseInitialized) {
      try {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          // El usuario cerro el selector de cuentas: no es un error
          _ultimoIntentoCancelado = true;
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) {
          _currentUser = UsuarioApp.fromFirebase(userCredential.user!);
          _userStreamController.add(_currentUser);
          await _guardarMarcaSesion(true);
          debugPrint('[Auth] Sesion Firebase establecida: uid=${userCredential.user!.uid}');
          return _currentUser;
        }
      } catch (e) {
        debugPrint('Error en signInWithGoogle: $e');
        return null;
      }
      return null;
    } else {
      // Firebase no esta inicializado, no se permite iniciar sesion en modo demo
      return null;
    }
  }

  /// Intenta reingresar SIN interaccion del usuario.
  ///
  /// Util cuando el almacenamiento cifrado de Firebase Auth no logra persistir
  /// la sesion (p. ej. en algunos dispositivos MIUI/HyperOS, donde el keystore
  /// falla con "FirebearStorageCryptoHelper"). Google Sign-In mantiene su
  /// propia persistencia en los Servicios de Google del sistema (mas robusta),
  /// asi que pedimos la cuenta recordada y reconstruimos la sesion de Firebase
  /// sin mostrar ninguna pantalla.
  Future<UsuarioApp?> intentarReingresoSilencioso() async {
    if (!_isFirebaseInitialized) return null;
    try {
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signInSilently().timeout(const Duration(seconds: 8));
      if (googleUser == null) {
        debugPrint('[Auth] Reingreso silencioso: no hay cuenta Google recordada');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 8));

      if (userCredential.user != null) {
        _currentUser = UsuarioApp.fromFirebase(userCredential.user!);
        _userStreamController.add(_currentUser);
        await _guardarMarcaSesion(true);
        debugPrint('[Auth] Reingreso silencioso OK: uid=${userCredential.user!.uid}');
        return _currentUser;
      }
    } catch (e) {
      debugPrint('[Auth] Reingreso silencioso fallo: $e');
    }
    return null;
  }

  Future<UsuarioApp?> signInWithFacebook() async {
    return null;
  }

  Future<UsuarioApp?> signInDemo() async {
    return null;
  }

  Future<void> signOut() async {
    if (_isFirebaseInitialized) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    }
    await _guardarMarcaSesion(false);
    _currentUser = null;
    _userStreamController.add(null);
  }

  Future<bool> deleteFirebaseAccount() async {
    if (_isFirebaseInitialized && FirebaseAuth.instance.currentUser != null) {
      try {
        await FirebaseAuth.instance.currentUser!.delete();
        await _guardarMarcaSesion(false);
        _currentUser = null;
        _userStreamController.add(null);
        return true;
      } catch (e) {
        debugPrint('Error al eliminar cuenta en Firebase Auth: $e');
        await signOut(); // Fallback: asegurarse de cerrar sesion
        return false;
      }
    } else {
      _currentUser = null;
      _userStreamController.add(null);
      return true;
    }
  }
}
