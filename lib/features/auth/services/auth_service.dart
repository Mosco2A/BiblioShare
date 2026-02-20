import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Wrapper Firebase Auth pour BiblioShare
class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Phone Auth ──

  /// Déclenche la vérification par téléphone OTP
  static Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onError,
    required void Function(PhoneAuthCredential credential)
        onAutoVerification,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resendToken,
      verificationCompleted: onAutoVerification,
      verificationFailed: (FirebaseAuthException e) {
        onError(_mapAuthError(e.code));
      },
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  /// Vérifie le code OTP et connecte l'utilisateur
  static Future<UserCredential> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // ── Google Sign-In ──

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // Annulé par l'utilisateur

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  // ── Apple Sign-In ──

  static Future<UserCredential> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    return await _auth.signInWithCredential(oauthCredential);
  }

  // ── Anonymous ──

  static Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // ── Link Credential (upgrade anonymous → full account) ──

  static Future<UserCredential> linkWithCredential(
      AuthCredential credential) async {
    return await _auth.currentUser!.linkWithCredential(credential);
  }

  // ── Sign Out ──

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // ── Helpers ──

  /// Liste des providers liés au compte courant
  static List<String> get linkedProviders {
    return currentUser?.providerData
            .map((info) => info.providerId)
            .toList() ??
        [];
  }

  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  static String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'invalid-verification-code':
        return 'Code de vérification incorrect';
      case 'session-expired':
        return 'Session expirée. Renvoyez le code.';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec un autre mode de connexion';
      case 'credential-already-in-use':
        return 'Ce compte est déjà lié à un autre utilisateur';
      default:
        return 'Erreur d\'authentification ($code)';
    }
  }
}
