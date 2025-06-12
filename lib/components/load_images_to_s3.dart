import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<String?> uploadImageToS3(File imageFile, String fileName) async {
  try {
    // 1. Pobierz presigned URL do uploadu od backendu
    final uploadUrlResponse = await http.get(
      Uri.parse(
        'https://diet-app-backend-rdbj.onrender.com/get_upload_signed_url?key=meals/$fileName',
      ),
    );

    if (uploadUrlResponse.statusCode != 200) {
      print('Błąd pobierania presigned URL: ${uploadUrlResponse.body}');
      return null;
    }

    final uploadUrl =
        (jsonDecode(uploadUrlResponse.body) as Map<String, dynamic>)['url']
            as String;

    final bytes = await imageFile.readAsBytes();

    final uploadResponse = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': 'image/jpeg'},
      body: bytes,
    );

    if (uploadResponse.statusCode == 200) {
      print('Obraz został pomyślnie przesłany do S3');
      return 'meals/$fileName';
    } else {
      print('Błąd uploadu do S3: ${uploadResponse.statusCode}');
      return null;
    }
  } catch (e) {
    print('Błąd uploadu: $e');
    return null;
  }
}

Future<String?> fetchSignedUrl(String key) async {
  final url = Uri.parse(
    'https://diet-app-backend-rdbj.onrender.com/get_signed_url?key=$key',
  );
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['url'] as String?;
  } else {
    return null;
  }
}
