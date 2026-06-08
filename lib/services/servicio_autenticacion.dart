import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/usuario_app.dart';

class ServicioAutenticacion {
  static final ServicioAutenticacion _instance = ServicioAutenticacion._internal();
  factory ServicioAutenticacion() => _instance;

  ServicioAutenticacion._internal() {
    _checkFirebaseStatus();
  }

  bool _isFirebaseInitialized = false;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

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

  Future<UsuarioApp?> signInWithGoogle() async {
    if (_isFirebaseInitialized) {
      try {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) {
          _currentUser = UsuarioApp.fromFirebase(userCredential.user!);
          _userStreamController.add(_currentUser);
          return _currentUser;
        }
      } catch (e) {
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
    _currentUser = null;
    _userStreamController.add(null);
  }

  Future<bool> deleteFirebaseAccount() async {
    if (_isFirebaseInitialized && FirebaseAuth.instance.currentUser != null) {
      try {
        await FirebaseAuth.instance.currentUser!.delete();
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
    if (_isFirebaseInitialized) {
      try {
        // Esperar el primer evento de authStateChanges para garantizar que se restaure la sesión local
        final User? user = await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(
              const Duration(seconds: 2),
              onTimeout: () => FirebaseAuth.instance.currentUser,
            );
        if (user != null) {
          _currentUser = UsuarioApp.fromFirebase(user);
          _userStreamController.add(_currentUser);
        } else {
          _currentUser = null;
          _userStreamController.add(null);
        }
      } catch (e) {
        // Fallback en caso de error o timeout
        final User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          _currentUser = UsuarioApp.fromFirebase(user);
          _userStreamController.add(_currentUser);
        } else {
          _currentUser = null;
          _userStreamController.add(null);
        }
      }
    } else {
      _currentUser = null;
      _userStreamController.add(null);
    }
  }
}
