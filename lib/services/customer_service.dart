import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/api_config.dart';

class CustomerService {

  static final Dio _dio = Dio();

  static Future<Map<String, dynamic>?> getProfile() async {

    try {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        return null;
      }

      final token =
      await user.getIdToken();

      final response =
      await _dio.get(

        "${ApiConfig.baseUrl}/customers/me",

        options: Options(
          headers: {
            "Authorization":
            "Bearer $token",
          },
        ),
      );

      return response.data["customer"];

    } catch (e) {

      print(e);

      return null;
    }
  }
}