import 'dart:io';
import 'dart:typed_data';

import 'package:e_sera/features/storage/domain/storage_repo.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageRepo implements StorageRepo {
  final storage = Supabase.instance;

  /*

  PROFILE PICTURES -upload images to storage

  */

  @override
  Future<String?> uploadProfileImageMobile(String path) {
    return _uploadFile(path, "profile_images");
  }

  @override
  Future<String?> uploadProfileImageWeb(Uint8List fileBytes) {
    return _uploadFileBytes(fileBytes, "profile_images");
  }

  /*

  POST PICTURES -upload images to storage

  */

  @override
  Future<String?> uploadPostImageMobile(String path) {
    return _uploadFile(path, "post_images");
  }

  @override
  Future<String?> uploadPostImageWeb(Uint8List fileBytes) {
    return _uploadFileBytes(fileBytes, "post_images");
  }

  /*
  

  HELPER METHODS - to upload files to storage

  */

  // mobile platforms (file)
  Future<String?> _uploadFile(String path, String folder) async {
    try {
      final file = File(path);

      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${p.basename(path)}";

      final fullPath = '$folder/$fileName';

      final response = await storage.client.storage
          .from('eserabucket')
          .upload(fullPath, file);

      if (response.isEmpty) {
        throw Exception('Error of upload');
      }

      final publicUrl = storage.client.storage
          .from('eserabucket')
          .getPublicUrl(fullPath);

      return publicUrl;
    } catch (e) {
      print("upload error: $e");
      return null;
    }
  }

  //web platforms (bytes)
  Future<String?> _uploadFileBytes(Uint8List fileBytes, String folder) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final fullPath = '$folder/$fileName';

      final response = await storage.client.storage
          .from('eserabucket')
          .uploadBinary(fullPath, fileBytes);

      if (response.isEmpty) {
        throw Exception('Error of upload');
      }

      final publicUrl = storage.client.storage
          .from('eserabucket')
          .getPublicUrl(fullPath);

      return publicUrl;
    } catch (e) {
      print("upload error: $e");
      return null;
    }
  }
}
