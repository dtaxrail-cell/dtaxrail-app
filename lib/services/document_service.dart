import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DocumentService {

  static const String baseUrl =
      "http://10.79.198.214:5000";

  static final Dio _dio = Dio();

  static Future<Map<String, dynamic>?> uploadDocumentDirect({

    required String filingId,
    required String documentType,
    required String filePath,
    required String fileName,

    ProgressCallback? onSendProgress,

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

      FormData formData =
      FormData.fromMap({

        "document":
        await MultipartFile.fromFile(

          filePath,
          filename: fileName,
        ),

        "filing_id": filingId,

        "document_type": documentType,
      });

      final response =
      await _dio.post(

        "$baseUrl/documents/upload",

        data: formData,

        onSendProgress: onSendProgress,

        options: Options(

          headers: {

            "Authorization":
            "Bearer $token",
          },
        ),
      );

      print(response.data);

      return response.data;

    } catch (e) {

      print("Direct Upload Error: $e");

      return null;
    }
  }
}