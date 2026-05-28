
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
class DocumentService {


static final Dio _dio = Dio();

// ==========================================
// PICK + UPLOAD DOCUMENT
// ==========================================
static Future<bool> pickAndUploadDocument({

required String filingId,
required String documentType,

}) async {

try {

final result =
await FilePicker.pickFiles(
type: FileType.any,
);

if (result == null) {
return false;
}

final file =
result.files.single;

final user =
FirebaseAuth.instance.currentUser;

if (user == null) {
return false;
}

final token =
await user.getIdToken();

FormData formData =
FormData.fromMap({

"document":
await MultipartFile.fromFile(

file.path!,

filename:
file.name,
),

"filing_id":
filingId,

"document_type":
documentType,
});

await _dio.post(

  "${ApiConfig.baseUrl}/documents/upload",

data: formData,

options: Options(

headers: {

"Authorization":
"Bearer $token",
},
),
);

return true;

} catch (e) {

print("Upload Error: $e");

return false;
}
}

// ==========================================
// CAMERA CAPTURE + UPLOAD
// ==========================================
static Future<bool> captureAndUploadDocument({

required String filingId,
required String documentType,

}) async {

try {

final picker = ImagePicker();

final image =
await picker.pickImage(

source: ImageSource.camera,

imageQuality: 70,
);

if (image == null) {
return false;
}

final user =
FirebaseAuth.instance.currentUser;

if (user == null) {
return false;
}

final token =
await user.getIdToken();

FormData formData =
FormData.fromMap({

"document":
await MultipartFile.fromFile(

image.path,

filename:
"camera_document.jpg",
),

"filing_id":
filingId,

"document_type":
documentType,
});

await _dio.post(

  "${ApiConfig.baseUrl}/documents/upload",

data: formData,

options: Options(

headers: {

"Authorization":
"Bearer $token",
},
),
);

return true;

} catch (e) {

print("Camera Upload Error: $e");

return false;
}
}

// ==========================================
// DIRECT UPLOAD
// ==========================================
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

"filing_id":
filingId,

"document_type":
documentType,
});

final response =
await _dio.post(

  "${ApiConfig.baseUrl}/documents/upload",

data: formData,

onSendProgress:
onSendProgress,

options: Options(

headers: {

"Authorization":
"Bearer $token",
},
),
);

return response.data;

} catch (e) {

print("Direct Upload Error: $e");

return null;
}
}
}
