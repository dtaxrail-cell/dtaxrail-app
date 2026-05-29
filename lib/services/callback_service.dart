import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../config/api_config.dart';

class CallbackService {
  static Future<bool> requestCallback({
    required String phone,
    required String issue,
  }) async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        return false;
      }

      final token =
      await user.getIdToken();

      final response =
      await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/callbacks/create',
        ),
        headers: {
          'Content-Type':
          'application/json',
          'Authorization':
          'Bearer $token',
        },
        body: jsonEncode({
          'phone': phone,
          'issue': issue,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }
}