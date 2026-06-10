import 'dart:convert';

import 'package:e_sera/core/config/app_config.dart';
import 'package:e_sera/features/profile/domain/entities/profile_user.dart';
import 'package:e_sera/features/search/domain/search_repo.dart';
import 'package:http/http.dart' as http;

class ApiSearchRepo implements SearchRepo {
  final http.Client client;

  ApiSearchRepo(this.client);

  static const _headers = {"Content-Type": "application/json"};

  @override
  Future<List<ProfileUser?>> searchUsers(String query) async {
    final uri = Uri.parse(
      "${AppConfig.apiBaseUrl}/search/users",
    ).replace(queryParameters: {"q": query});

    final response = await client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final users = _unwrapList(decoded);
      return users.map((userJson) {
        if (userJson is Map<String, dynamic>) {
          return ProfileUser.fromJson(userJson);
        }

        throw Exception("Utilisateur API invalide");
      }).toList();
    }

    throw Exception(_errorMessage(response, "Erreur recherche users"));
  }

  List<dynamic> _unwrapList(dynamic decoded) {
    if (decoded is List<dynamic>) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final nested = decoded['users'] ?? decoded['data'];
      if (nested is List<dynamic>) {
        return nested;
      }
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
