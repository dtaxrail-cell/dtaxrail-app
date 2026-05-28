import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
class FilingService {


  static final Dio _dio = Dio();

  static Future<String?> _getToken() async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {

      return null;
    }

    return await user.getIdToken();
  }



  // ==========================================
  // CREATE FILING
  // ==========================================
  static Future<Map<String, dynamic>?> createFiling({

    required String filingType,
    required String assessmentYear,
    required String notes,
    required String memberId,

  }) async {

    try {

      final token =
      await _getToken();

      if (token == null) {
        return null;
      }

      final response =
      await _dio.post(

        "${ApiConfig.baseUrl}/filings/create",

        data: {

          "filing_type": filingType,
          "assessment_year": assessmentYear,
          "notes": notes,
          "member_id": memberId,

        },

        options: Options(

          headers: {

            "Authorization":
            "Bearer $token",

          },
        ),
      );

      return response.data;

    } catch (e) {

      print("Create Filing Error: $e");

      return null;
    }
  }



  // ==========================================
  // GET CUSTOMER FILINGS
  // ==========================================
  static Future<List<dynamic>>
  getCustomerFilings() async {

    try {

      final token =
      await _getToken();

      if (token == null) {
        return [];
      }

      final response =
      await _dio.get(

        "${ApiConfig.baseUrl}/filings/customer/all",

        options: Options(

          headers: {

            "Authorization":
            "Bearer $token",

          },
        ),
      );

      return response.data["filings"] ?? [];

    } catch (e) {

      print("Get Customer Filings Error: $e");

      return [];
    }
  }
}