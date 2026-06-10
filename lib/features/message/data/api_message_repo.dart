import 'dart:convert';

import 'package:e_sera/core/config/app_config.dart';
import 'package:e_sera/features/message/domain/entities/chat_message.dart';
import 'package:e_sera/features/message/domain/entities/conversation.dart';
import 'package:e_sera/features/message/domain/repos/message_repo.dart';
import 'package:http/http.dart' as http;

class ApiMessageRepo implements MessageRepo {
  final http.Client client;

  ApiMessageRepo(this.client);

  static const _headers = {"Content-Type": "application/json"};

  @override
  Future<List<Conversation>> fetchConversations(String userId) async {
    final response = await client.get(
      Uri.parse("${AppConfig.apiBaseUrl}/messages/conversations/$userId"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final conversations = _unwrapList(decoded, 'conversations');
      return conversations.map((conversationJson) {
        if (conversationJson is Map<String, dynamic>) {
          return Conversation.fromJson(conversationJson);
        }

        throw Exception("Invalid conversation API response");
      }).toList();
    }

    throw Exception(_errorMessage(response, "Message fetch error"));
  }

  @override
  Future<List<ChatMessage>> fetchThread(
    String currentUserId,
    String otherUserId,
  ) async {
    final uri = Uri.parse("${AppConfig.apiBaseUrl}/messages/thread").replace(
      queryParameters: {
        "currentUserId": currentUserId,
        "otherUserId": otherUserId,
      },
    );

    final response = await client.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final messages = _unwrapList(decoded, 'messages');
      return messages.map((messageJson) {
        if (messageJson is Map<String, dynamic>) {
          return ChatMessage.fromJson(messageJson);
        }

        throw Exception("Invalid message API response");
      }).toList();
    }

    throw Exception(_errorMessage(response, "Thread fetch error"));
  }

  @override
  Future<ChatMessage> sendMessage(
    String senderId,
    String receiverId,
    String text,
  ) async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/messages"),
      headers: _headers,
      body: jsonEncode({
        "senderId": senderId,
        "receiverId": receiverId,
        "text": text,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ChatMessage.fromJson(decoded);
      }

      throw Exception("Invalid message API response");
    }

    throw Exception(_errorMessage(response, "Message send error"));
  }

  @override
  Future<List<String>> suggestReplies(String message) async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/ai/suggest-replies"),
      headers: _headers,
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final replies = decoded['replies'];
        if (replies is List<dynamic>) {
          return replies
              .whereType<String>()
              .map((reply) => reply.trim())
              .where((reply) => reply.isNotEmpty)
              .take(3)
              .toList();
        }
      }

      throw Exception("Invalid suggestions API response");
    }

    throw Exception(_errorMessage(response, "Suggested replies error"));
  }

  List<dynamic> _unwrapList(dynamic decoded, String key) {
    if (decoded is List<dynamic>) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final nested = decoded[key] ?? decoded['data'];
      if (nested is List<dynamic>) {
        return nested;
      }
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
