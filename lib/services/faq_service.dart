import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class FaqService {

  static Future<List<dynamic>> getFaqs() async {

    try {

      final response = await http.get(

        Uri.parse(
          '${ApiConfig.baseUrl}/faqs',
        ),

      );

      if (response.statusCode == 200) {

        final data =
        jsonDecode(response.body);

        return data['faqs'] ?? [];
      }

      return [];

    } catch (e) {

      print(e);

      return [];
    }
  }
}