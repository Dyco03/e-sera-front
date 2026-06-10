import 'dart:convert';

import 'package:e_sera/core/config/app_config.dart';
import 'package:e_sera/features/post/domain/entitites/comment.dart';
import 'package:e_sera/features/post/domain/entitites/post.dart';
import 'package:e_sera/features/post/domain/repos/post_repo.dart';
import 'package:http/http.dart' as http;

class ApiPostRepo implements PostRepo {
  final http.Client client;

  ApiPostRepo(this.client);

  static const _headers = {"Content-Type": "application/json"};

  @override
  Future<String> translatePostText(String text, String targetLanguage) async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/translations/post"),
      headers: _headers,
      body: jsonEncode({"text": text, "targetLanguage": targetLanguage}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, "Post translation error"));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> &&
        decoded['translatedText'] is String) {
      return decoded['translatedText'];
    }

    throw Exception("Invalid translation response");
  }

  @override
  Future<String> summarizeText(String text) async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/ai/summarize"),
      headers: _headers,
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, "Post summary error"));
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded['summary'] is String) {
      return decoded['summary'];
    }

    throw Exception("Invalid summary response");
  }

  @override
  Future<List<Post>> fetchAllPosts() async {
    final response = await client.get(
      Uri.parse("${AppConfig.apiBaseUrl}/posts"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _parsePostList(response.body);
    }

    throw Exception(_errorMessage(response, "Post fetch error"));
  }

  @override
  Future<void> createPost(Post post) async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/posts"),
      headers: _headers,
      body: jsonEncode(_postToApiJson(post)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, "Post creation error"));
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    final response = await client.delete(
      Uri.parse("${AppConfig.apiBaseUrl}/posts/$postId"),
      headers: _headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, "Post deletion error"));
    }
  }

  @override
  Future<List<Post>> fetchPostsByUserId(String userId) async {
    final response = await client.get(
      Uri.parse("${AppConfig.apiBaseUrl}/users/$userId/posts"),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return _parsePostList(response.body);
    }

    throw Exception(_errorMessage(response, "User posts fetch error"));
  }

  @override
  Future<void> toggleLikePost(String postId, String userId) async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/posts/$postId/likes/toggle"),
      headers: _headers,
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, "Post like error"));
    }
  }

  @override
  Future<void> addComment(String postId, Comment comment) async {
    final response = await client.post(
      Uri.parse("${AppConfig.apiBaseUrl}/posts/$postId/comments"),
      headers: _headers,
      body: jsonEncode(_commentToApiJson(comment)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, "Comment creation error"));
    }
  }

  @override
  Future<void> deleteComment(String postId, String commentId) async {
    final response = await client.delete(
      Uri.parse("${AppConfig.apiBaseUrl}/posts/$postId/comments/$commentId"),
      headers: _headers,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _errorMessage(response, "Comment deletion error"),
      );
    }
  }

  List<Post> _parsePostList(String body) {
    final decoded = jsonDecode(body);
    final list = _unwrapList(decoded);
    return list.map((postJson) => _postFromApiJson(postJson)).toList();
  }

  List<dynamic> _unwrapList(dynamic decoded) {
    if (decoded is List<dynamic>) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final nested = decoded['posts'] ?? decoded['data'];
      if (nested is List<dynamic>) {
        return nested;
      }
    }

    throw Exception("Invalid API response");
  }

  Post _postFromApiJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw Exception("Invalid post API response");
    }

    final comments =
        (json['comments'] as List<dynamic>?)
            ?.map((commentJson) => _commentFromApiJson(commentJson))
            .toList() ??
        [];

    return Post(
      id: json['id'],
      userId: json['userId'],
      userName: json['name'] ?? json['userName'],
      text: json['text'],
      imageUrl: json['imageUrl'] ?? '',
      timestamp: _dateTimeFromApi(json['timestamp']),
      likes: List<String>.from(json['likes'] ?? []),
      comments: comments,
    );
  }

  Comment _commentFromApiJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw Exception("Invalid comment API response");
    }

    return Comment(
      id: json['id'],
      postId: json['postId'],
      userId: json['userId'],
      userName: json['userName'],
      text: json['text'],
      timestamp: _dateTimeFromApi(json['timestamp']),
    );
  }

  Map<String, dynamic> _postToApiJson(Post post) {
    return {
      'id': post.id,
      'userId': post.userId,
      'name': post.userName,
      'text': post.text,
      'imageUrl': post.imageUrl,
      'timestamp': post.timestamp.toIso8601String(),
      'likes': post.likes,
      'comments': post.comments.map(_commentToApiJson).toList(),
    };
  }

  Map<String, dynamic> _commentToApiJson(Comment comment) {
    return {
      'id': comment.id,
      'postId': comment.postId,
      'userId': comment.userId,
      'userName': comment.userName,
      'text': comment.text,
      'timestamp': comment.timestamp.toIso8601String(),
    };
  }

  DateTime _dateTimeFromApi(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is Map<String, dynamic> && value['_seconds'] is int) {
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }

    throw Exception("Invalid API timestamp");
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
