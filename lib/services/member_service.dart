import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberService {

  static const String baseUrl =
      "http://10.79.198.214:5000";

  static final Dio _dio = Dio();

  static Future<String?> _getToken() async {

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return await user.getIdToken();
  }



  // CREATE MEMBER
  static Future<Map<String, dynamic>?> createMember({

    required String fullName,
    required String panNumber,
    required String phone,
    required String email,
    required String relationship,
    required String dateOfBirth,

  }) async {

    try {

      final token =
      await _getToken();

      if (token == null) {
        return null;
      }

      final response =
      await _dio.post(

        "$baseUrl/members/create",

        data: {

          "full_name": fullName,
          "pan_number": panNumber,
          "phone": phone,
          "email": email,
          "relationship": relationship,
          "date_of_birth": dateOfBirth,

        },

        options: Options(

          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      return response.data;

    } catch (e) {

      print(e);

      return null;
    }
  }



  // GET MEMBERS
  static Future<List<dynamic>> getMembers() async {

    try {

      final token =
      await _getToken();

      if (token == null) {
        return [];
      }

      final response =
      await _dio.get(

        "$baseUrl/members",

        options: Options(

          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      return response.data["members"] ?? [];

    } catch (e) {

      print(e);

      return [];
    }
  }



  // UPDATE MEMBER
  static Future<bool> updateMember({

    required String memberId,
    required String fullName,
    required String panNumber,
    required String phone,
    required String email,
    required String relationship,
    required String dateOfBirth,

  }) async {

    try {

      final token =
      await _getToken();

      if (token == null) {
        return false;
      }

      await _dio.put(

        "$baseUrl/members/update/$memberId",

        data: {

          "full_name": fullName,
          "pan_number": panNumber,
          "phone": phone,
          "email": email,
          "relationship": relationship,
          "date_of_birth": dateOfBirth,

        },

        options: Options(

          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      return true;

    } catch (e) {

      print(e);

      return false;
    }
  }



  // DELETE MEMBER
  static Future<bool> deleteMember(
      String memberId,
      ) async {

    try {

      final token =
      await _getToken();

      if (token == null) {
        return false;
      }

      await _dio.delete(

        "$baseUrl/members/delete/$memberId",

        options: Options(

          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      return true;

    } catch (e) {

      print(e);

      return false;
    }
  }
}