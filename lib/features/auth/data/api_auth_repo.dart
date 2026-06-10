import 'dart:convert';

import 'package:e_sera/core/config/app_config.dart';
import 'package:e_sera/features/auth/domain/entities/app_user.dart';
import 'package:e_sera/features/auth/domain/repos/auth_repo.dart';
import 'package:http/http.dart' as http;

class ApiAuthRepo implements AuthRepo {
  final http.Client client;

  ApiAuthRepo(this.client);

  static const _headers = {"Content-Type": "application/json"};

  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/auth/login"),
      headers: _headers,
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      return _parseUser(response.body);
    }

    throw Exception(_errorMessage(response, "Login error"));
  }

  @override
  Future<AppUser?> registerWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/auth/register"),
      headers: _headers,
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseUser(response.body);
    }

    throw Exception(_errorMessage(response, "Registration error"));
  }

  @override
  Future<void> logout() async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/auth/logout"),
      headers: _headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, "Logout error"));
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final response = await client.get(
      Uri.parse("${AppConfig.apiBaseUrl}/auth/me"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _parseUser(response.body);
    }

    if (response.statusCode == 401 || response.statusCode == 404) {
      return null;
    }

    throw Exception(_errorMessage(response, "Current user error"));
  }

  AppUser? _parseUser(String body) {
    if (body.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(body);
    if (decoded == null) {
      return null;
    }

    final data = _unwrapObject(decoded);
    return AppUser.fromJson(data);
  }

  Map<String, dynamic> _unwrapObject(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final nested = decoded['user'] ?? decoded['data'];
      if (nested is Map<String, dynamic>) {
        return nested;
      }

      return decoded;
    }

    throw Exception("Invalid API response");
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
