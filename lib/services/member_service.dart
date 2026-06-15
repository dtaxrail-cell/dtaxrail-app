import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

class MemberService {

  static final Dio _dio = Dio();

  static Future<String?> _getToken() async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }



  // CREATE MEMBER
  static Future<Map<String, dynamic>?> createMember({

    required String? fullName,
    required String? panNumber,
    required String  phone,
    required String? email,
    required String  relationship,
    required String? dateOfBirth,
    String? incomeTaxPassword,

  }) async {

    try {

      final token = await _getToken();
      if (token == null) return null;

      // Build body — omit null fields entirely so backend never gets ""
      final Map<String, dynamic> body = {
        "phone"        : phone,
        "relationship" : relationship,
      };
      if (fullName          != null) body["full_name"]            = fullName;
      if (panNumber         != null) body["pan_number"]           = panNumber;
      if (email             != null) body["email"]                = email;
      if (dateOfBirth       != null) body["date_of_birth"]        = dateOfBirth;
      if (incomeTaxPassword != null) body["income_tax_password"]  = incomeTaxPassword;

      print("CREATE MEMBER REQUEST: $body");

      final response = await _dio.post(
        "${ApiConfig.baseUrl}/members/create",
        data   : body,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      print("CREATE MEMBER RESPONSE: ${response.data}");
      return response.data;

    } on DioException catch (e) {
      print("CREATE MEMBER ERROR: ${e.response?.statusCode} — ${e.response?.data}");
      return null;
    } catch (e) {
      print("CREATE MEMBER UNKNOWN ERROR: $e");
      return null;
    }
  }



  // GET MEMBERS
  static Future<List<dynamic>> getMembers() async {

    try {

      final token = await _getToken();
      if (token == null) return [];

      final response = await _dio.get(
        "${ApiConfig.baseUrl}/members",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data["members"] ?? [];

    } on DioException catch (e) {
      print("GET MEMBERS ERROR: ${e.response?.statusCode} — ${e.response?.data}");
      return [];
    } catch (e) {
      print("GET MEMBERS UNKNOWN ERROR: $e");
      return [];
    }
  }



  // UPDATE MEMBER
  static Future<bool> updateMember({

    required String  memberId,
    required String? fullName,
    required String? panNumber,
    required String  phone,
    required String? email,
    required String  relationship,
    required String? dateOfBirth,
    String? incomeTaxPassword,

  }) async {

    try {

      final token = await _getToken();
      if (token == null) return false;

      // Build body — omit null fields entirely
      final Map<String, dynamic> body = {
        "phone"        : phone,
        "relationship" : relationship,
      };
      if (fullName          != null) body["full_name"]            = fullName;
      if (panNumber         != null) body["pan_number"]           = panNumber;
      if (email             != null) body["email"]                = email;
      if (dateOfBirth       != null) body["date_of_birth"]        = dateOfBirth;
      if (incomeTaxPassword != null) body["income_tax_password"]  = incomeTaxPassword;

      print("UPDATE MEMBER REQUEST: $body");

      await _dio.put(
        "${ApiConfig.baseUrl}/members/update/$memberId",
        data   : body,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return true;

    } on DioException catch (e) {
      print("UPDATE MEMBER ERROR: ${e.response?.statusCode} — ${e.response?.data}");
      return false;
    } catch (e) {
      print("UPDATE MEMBER UNKNOWN ERROR: $e");
      return false;
    }
  }



  // DELETE MEMBER
  static Future<bool> deleteMember(String memberId) async {

    try {

      final token = await _getToken();
      if (token == null) return false;

      await _dio.delete(
        "${ApiConfig.baseUrl}/members/delete/$memberId",
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return true;

    } on DioException catch (e) {
      print("DELETE MEMBER ERROR: ${e.response?.statusCode} — ${e.response?.data}");
      return false;
    } catch (e) {
      print("DELETE MEMBER UNKNOWN ERROR: $e");
      return false;
    }
  }
}