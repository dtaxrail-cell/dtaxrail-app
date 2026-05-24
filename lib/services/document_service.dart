import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class DocumentService {

  static const String baseUrl = "http://10.79.198.214:5000";

  static final Dio _dio = Dio();

  // FILE PICKER UPLOAD
  static Future<Map<String, dynamic>?> uploadDocument() async {

    try {

      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result == null) {
        print("No file selected");
        return null;
      }

      final file = result.files.single;

      FormData formData = FormData.fromMap({
        "document": await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        ),
      });

      final response = await _dio.post(
        "$baseUrl/documents/upload",
        data: formData,
      );

      print(response.data);

      return response.data;

    } catch (e) {

      print("Upload Error: $e");

      return null;
    }
  }

  // CAMERA UPLOAD
  static Future<Map<String, dynamic>?> uploadFromCamera() async {

    try {

      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
      );

      if (image == null) {
        print("No image captured");
        return null;
      }

      FormData formData = FormData.fromMap({
        "document": await MultipartFile.fromFile(
          image.path,
          filename: image.name,
        ),
      });

      final response = await _dio.post(
        "$baseUrl/documents/upload",
        data: formData,
      );

      print(response.data);

      return response.data;

    } catch (e) {

      print("Camera Upload Error: $e");

      return null;
    }
  }
}