class UsuarioApp {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String provider;

  const UsuarioApp({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.provider,
  });

  factory UsuarioApp.fromFirebase(dynamic firebaseUser) {
    return UsuarioApp(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? 'Usuario de AIRMONEY',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      provider: 'google',
    );
  }

  Map<String, String?> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
    };
  }

  factory UsuarioApp.fromMap(Map<String, dynamic> map) {
    return UsuarioApp(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? 'Usuario de AIRMONEY',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      provider: map['provider'] ?? 'demo',
    );
  }
}
