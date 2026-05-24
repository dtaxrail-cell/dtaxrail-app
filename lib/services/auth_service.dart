import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static User? get currentUser =>
      _auth.currentUser;

  // EMAIL SIGNUP
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {

    return await _auth
        .createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // EMAIL LOGIN
  static Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {

    return await _auth
        .signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // LOGOUT
  static Future<void> logout() async {
    await _auth.signOut();
  }
}