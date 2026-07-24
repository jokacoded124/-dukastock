import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'cloudinary_config.dart';

/// Handles uploading product photos to Cloudinary via their unsigned upload
/// API and returning a public HTTPS URL to save on the Firestore product
/// document. No Firebase Storage / Blaze billing account required.
class CloudinaryUploadService {
  static Future<String> uploadProductImage(File file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = 'dukastock_products'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;

    if (secureUrl == null) {
      throw Exception('Cloudinary response did not include a URL');
    }

    return secureUrl;
  }
}
