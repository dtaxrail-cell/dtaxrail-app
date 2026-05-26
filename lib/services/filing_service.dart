import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FilingService {

  static const String baseUrl =
      "http://10.79.198.214:5000";

  static final Dio _dio = Dio();

  static Future<Map<String, dynamic>?> createFiling({

    required String filingType,
    required String assessmentYear,
    required String notes,

    required String memberName,
    required String memberPan,
    required String memberPhone,
    required String memberEmail,
    required String relationship,

  }) async {

    try {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {

        print("No logged in user");

        return null;
      }

      final token =
      await user.getIdToken();





      final response =
      await _dio.post(

        "$baseUrl/filings/create",

        data: {

          "filing_type": filingType,
          "assessment_year": assessmentYear,
          "notes": notes,

          "member_name": memberName,
          "member_pan": memberPan,
          "member_phone": memberPhone,
          "member_email": memberEmail,
          "relationship": relationship,

        },

        options: Options(

          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );






      print(response.data);

      return response.data;

    } catch (e) {

      print("Create Filing Error: $e");

      return null;
    }
  }
}