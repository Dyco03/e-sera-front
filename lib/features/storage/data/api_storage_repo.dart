import 'dart:convert';
import 'dart:typed_data';

import 'package:e_sera/core/config/app_config.dart';
import 'package:e_sera/features/storage/domain/storage_repo.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class ApiStorageRepo implements StorageRepo {
  final http.Client client;

  ApiStorageRepo(this.client);

  @override
  Future<String?> uploadProfileImageMobile(String path) {
    return _uploadFile(
      endpoint: "${AppConfig.apiBaseUrl}/storage/profile-images",
      fieldName: "file",
      path: path,
    );
  }

  @override
  Future<String?> uploadProfileImageWeb(Uint8List fileBytes) {
    return _uploadBytes(
      endpoint: "${AppConfig.apiBaseUrl}/storage/profile-images",
      fieldName: "file",
      fileBytes: fileBytes,
      fileName: "profile_image.jpg",
    );
  }

  @override
  Future<String?> uploadPostImageMobile(String path) {
    return _uploadFile(
      endpoint: "${AppConfig.apiBaseUrl}/storage/post-images",
      fieldName: "file",
      path: path,
    );
  }

  @override
  Future<String?> uploadPostImageWeb(Uint8List fileBytes) {
    return _uploadBytes(
      endpoint: "${AppConfig.apiBaseUrl}/storage/post-images",
      fieldName: "file",
      fileBytes: fileBytes,
      fileName: "post_image.jpg",
    );
  }

  Future<String?> _uploadFile({
    required String endpoint,
    required String fieldName,
    required String path,
  }) async {
    final request = http.MultipartRequest("POST", Uri.parse(endpoint));
    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        path,
        filename: p.basename(path),
      ),
    );

    return _sendMultipart(request);
  }

  Future<String?> _uploadBytes({
    required String endpoint,
    required String fieldName,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest("POST", Uri.parse(endpoint));
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, fileBytes, filename: fileName),
    );

    return _sendMultipart(request);
  }

  Future<String?> _sendMultipart(http.MultipartRequest request) async {
    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final url = decoded['url'] ?? decoded['publicUrl'] ?? decoded['data'];
        return url?.toString();
      }

      throw Exception("Réponse upload API invalide");
    }

    throw Exception(_errorMessage(response, "Erreur upload image"));
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['detail'] ?? decoded['message'] ?? decoded['error'];
        if (message != null) {
          return "$fallback: $message";
        }
      }
    } catch (_) {}

    return "$fallback (${response.statusCode})";
  }
}
