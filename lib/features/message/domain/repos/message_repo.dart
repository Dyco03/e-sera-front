import 'package:e_sera/features/message/domain/entities/chat_message.dart';
import 'package:e_sera/features/message/domain/entities/conversation.dart';

abstract class MessageRepo {
  Future<List<Conversation>> fetchConversations(String userId);
  Future<List<ChatMessage>> fetchThread(
    String currentUserId,
    String otherUserId,
  );
  Future<ChatMessage> sendMessage(
    String senderId,
    String receiverId,
    String text,
  );
  Future<List<String>> suggestReplies(String message);
}
