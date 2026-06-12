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

  final StreamController<UsuarioApp?> _userStreamController = StreamController<UsuarioApp?>.broadcast();
  Stream<UsuarioApp?> get authStateChanges => _userStreamController.stream;

  UsuarioApp? _currentUser;
  UsuarioApp? get currentUser => _currentUser;

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

  Future<void> checkInitialSession() async {
    if (!_isFirebaseInitialized) {
      _currentUser = null;
      _userStreamController.add(null);
      return;
    }

    // 1. Verificar si ya tenemos el usuario cargado en memoria
    if (_currentUser != null) {
      return;
    }

    // 2. Verificar si FirebaseAuth ya tiene el usuario cargado de forma síncrona
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      _currentUser = UsuarioApp.fromFirebase(firebaseUser);
      _userStreamController.add(_currentUser);
      return;
    }

    // 3. Esperar la restauración asíncrona del token nativo.
    //    Si la marca local indica que había una sesión guardada, esperar con
    //    generosidad (la restauración puede tardar en arranques en frío);
    //    si no, solo una ventana corta para no demorar el primer arranque.
    bool habiaSesion = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      habiaSesion = prefs.getBool(_kSesionGoogleActiva) ?? false;
    } catch (_) {}

    final Duration maxEspera = habiaSesion
        ? const Duration(seconds: 10)
        : const Duration(milliseconds: 800);

    final User? user = await _esperarRestauracionDeSesion(maxEspera);

    if (user != null) {
      _currentUser = UsuarioApp.fromFirebase(user);
      _userStreamController.add(_currentUser);
      await _guardarMarcaSesion(true);
    } else {
      _currentUser = null;
      _userStreamController.add(null);
    }
  }

  Future<User?> _esperarRestauracionDeSesion(Duration maxEspera) async {
    final completer = Completer<User?>();
    StreamSubscription<User?>? subscription;

    subscription = FirebaseAuth.instance.authStateChanges().listen((User? u) {
      if (u != null && !completer.isCompleted) {
        completer.complete(u);
      }
    });

    Future.delayed(maxEspera, () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    final User? user = await completer.future;
    await subscription.cancel();
    return user;
  }
}
