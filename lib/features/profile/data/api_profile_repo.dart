import 'dart:convert';

import 'package:e_sera/core/config/app_config.dart';
import 'package:e_sera/features/profile/domain/entities/profile_user.dart';
import 'package:e_sera/features/profile/domain/repos/profile_repo.dart';
import 'package:http/http.dart' as http;

class ApiProfileRepo implements ProfileRepo {
  final http.Client client;

  ApiProfileRepo(this.client);

  static const _headers = {"Content-Type": "application/json"};

  @override
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    final response = await client.get(
      Uri.parse("${AppConfig.apiBaseUrl}/profiles/$uid"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _parseProfile(response.body);
    }

    if (response.statusCode == 404) {
      return null;
    }

    throw Exception(_errorMessage(response, "Erreur récupération profil"));
  }

  @override
  Future<void> updateProfile(ProfileUser updateProfile) async {
    final response = await client.put(
      Uri.parse("${AppConfig.apiBaseUrl}/profiles/${updateProfile.uid}"),
      headers: _headers,
      body: jsonEncode(updateProfile.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, "Erreur mise à jour profil"));
    }
  }

  @override
  Future<void> toggleFollow(String currentUid, String targetUid) async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/profiles/$targetUid/follow-toggle"),
      headers: _headers,
      body: jsonEncode({"currentUid": currentUid}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, "Erreur follow profil"));
    }
  }

  ProfileUser? _parseProfile(String body) {
    if (body.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(body);
    if (decoded == null) {
      return null;
    }

    final data = _unwrapObject(decoded);
    return ProfileUser.fromJson(data);
  }

  Map<String, dynamic> _unwrapObject(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final nested = decoded['profile'] ?? decoded['user'] ?? decoded['data'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }

      return decoded;
    }

    throw Exception("Réponse API invalide");
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
