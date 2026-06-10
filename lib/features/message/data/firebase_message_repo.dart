import 'package:e_sera/features/message/domain/entities/chat_message.dart';
import 'package:e_sera/features/message/domain/entities/conversation.dart';
import 'package:e_sera/features/message/domain/repos/message_repo.dart';

class FirebaseMessageRepo implements MessageRepo {
  @override
  Future<List<Conversation>> fetchConversations(String userId) async {
    throw UnimplementedError("Firebase messages are not configured");
  }

  @override
  Future<List<ChatMessage>> fetchThread(
    String currentUserId,
    String otherUserId,
  ) async {
    throw UnimplementedError("Firebase messages are not configured");
  }

  @override
  Future<ChatMessage> sendMessage(
    String senderId,
    String receiverId,
    String text,
  ) async {
    throw UnimplementedError("Firebase messages are not configured");
  }

  @override
  Future<List<String>> suggestReplies(String message) async {
    throw UnimplementedError("Firebase suggestions are not configured");
  }
}
