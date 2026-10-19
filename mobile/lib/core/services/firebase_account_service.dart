import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GisamAccount {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;

  const GisamAccount({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  factory GisamAccount.fromFirebase(User user) => GisamAccount(
        uid: user.uid,
        displayName: user.displayName ?? 'Usuario GISAM',
        email: user.email ?? '',
        photoUrl: user.photoURL,
      );
}

class GisamFirebaseConfig {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static Future<void> initialize() async {
    if (!isConfigured || Firebase.apps.isNotEmpty) return;

    final options = FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
      iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
    );
    await Firebase.initializeApp(options: options);
  }
}

class GisamAccountService {
  static const _googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const _googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const _googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: kIsWeb
        ? (_googleWebClientId.isEmpty ? null : _googleWebClientId)
        : defaultTargetPlatform == TargetPlatform.iOS
            ? (_googleIosClientId.isEmpty ? null : _googleIosClientId)
            : null,
    serverClientId:
        _googleServerClientId.isEmpty ? null : _googleServerClientId,
  );

  bool get isConfigured => GisamFirebaseConfig.isConfigured;

  GisamAccount? get currentAccount {
    if (Firebase.apps.isEmpty) return null;
    final user = FirebaseAuth.instance.currentUser;
    return user == null ? null : GisamAccount.fromFirebase(user);
  }

  Future<GisamAccount> signInWithGoogle() async {
    if (!isConfigured) {
      throw StateError(
        'Falta configurar Firebase. Revisa mobile/README.md y las variables FIREBASE_*.',
      );
    }
    await GisamFirebaseConfig.initialize();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw StateError('Inicio de sesión cancelado.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final user = result.user;
    if (user == null) {
      throw StateError('Firebase no devolvió un usuario autenticado.');
    }

    final profile =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final existing = await profile.get();
    await profile.set(
      {
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return GisamAccount.fromFirebase(user);
  }

  Future<void> signOut() async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
  }
}
