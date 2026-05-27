import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberService {

  static const String baseUrl =
      "http://10.79.198.214:5000";

  static final Dio _dio = Dio();





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

            "Authorization":
            "Bearer $token",

          },
        ),
      );

      print(response.data);

      return response.data;

    } on DioException catch (e) {

      print("STATUS CODE: ${e.response?.statusCode}");
      print("RESPONSE DATA: ${e.response?.data}");
      print("ERROR MESSAGE: ${e.message}");

      return null;

    } catch (e) {

      print("Create Member Error: $e");

      return null;
    }
  }







  // GET MEMBERS
  static Future<List<dynamic>> getMembers() async {

    try {

      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {

        return [];
      }

      final token =
      await user.getIdToken();





      final response =
      await _dio.get(

        "$baseUrl/members",

        options: Options(

          headers: {

            "Authorization":
            "Bearer $token",

          },
        ),
      );





      print(response.data);

      return response.data["members"] ?? [];

    } catch (e) {

      print("Get Members Error: $e");

      return [];
    }
  }
}