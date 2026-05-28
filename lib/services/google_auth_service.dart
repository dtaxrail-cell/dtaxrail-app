import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class GoogleAuthService {

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final GoogleSignIn _googleSignIn =
  GoogleSignIn();

  // GOOGLE LOGIN
  static Future<UserCredential?>
  signInWithGoogle() async {

    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount?
      googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication
      googleAuth =
      await googleUser.authentication;

      final credential =
      GoogleAuthProvider.credential(

        accessToken:
        googleAuth.accessToken,

        idToken:
        googleAuth.idToken,
      );

      return await _auth
          .signInWithCredential(
        credential,
      );

    } catch (e) {

      print(e);

      return null;
    }
  }

  // SYNC CUSTOMER TO BACKEND
  static Future<void>
  syncCustomerToBackend(
      String token,
      ) async {

    try {

      final dio = Dio();

      await dio.post(
        '${ApiConfig.baseUrl}/auth/sync-customer',

        options: Options(

          headers: {

            'Authorization':
            'Bearer $token',
          },
        ),

      );

      print(
        "Customer synced to backend",
      );

    } catch (e) {

      print(e);
    }
  }

  // LOGOUT
  static Future<void> logout() async {

    await _googleSignIn.signOut();

    await _auth.signOut();
  }
}