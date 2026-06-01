import 'dart:async';
import 'dart:convert';
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
      await _loadLocalDemoSession();
    }
  }

  Future<void> _loadLocalDemoSession() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('demo_user_session');
      if (userJson != null) {
        final Map<String, dynamic> userMap = json.decode(userJson);
        _currentUser = UsuarioApp.fromMap(userMap);
        _userStreamController.add(_currentUser);
      } else {
        _currentUser = null;
        _userStreamController.add(null);
      }
    } catch (e) {
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
      await Future.delayed(const Duration(milliseconds: 1500));
      _currentUser = const UsuarioApp(
        uid: 'demo_google_123',
        displayName: 'Alejandro Google',
        email: 'alejandro.demo@gmail.com',
        photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        provider: 'Google',
      );
      await _saveLocalDemoSession(_currentUser!);
      _userStreamController.add(_currentUser);
      return _currentUser;
    }
  }

  Future<UsuarioApp?> signInWithFacebook() async {
    if (_isFirebaseInitialized) {
      return null;
    } else {
      await Future.delayed(const Duration(milliseconds: 1500));
      _currentUser = const UsuarioApp(
        uid: 'demo_facebook_123',
        displayName: 'Alejandro Facebook',
        email: 'alejandro.fb.demo@gmail.com',
        photoUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=150&q=80',
        provider: 'Facebook',
      );
      await _saveLocalDemoSession(_currentUser!);
      _userStreamController.add(_currentUser);
      return _currentUser;
    }
  }

  Future<void> signOut() async {
    if (_isFirebaseInitialized) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('demo_user_session');
      _currentUser = null;
      _userStreamController.add(null);
    }
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
        await signOut(); // Fallback: asegurarse de cerrar sesión
        return false;
      }
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('demo_user_session');
      _currentUser = null;
      _userStreamController.add(null);
      return true;
    }
  }

  Future<void> _saveLocalDemoSession(UsuarioApp user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('demo_user_session', json.encode(user.toMap()));
  }

  Future<void> checkInitialSession() async {
    if (_isFirebaseInitialized) {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUser = UsuarioApp.fromFirebase(user);
        _userStreamController.add(_currentUser);
      } else {
        _currentUser = null;
        _userStreamController.add(null);
      }
    } else {
      await _loadLocalDemoSession();
    }
  }
}
