import 'package:e_sera/features/message/domain/entities/chat_message.dart';

class Conversation {
  final String otherUserId;
  final String otherUserName;
  final String otherUserEmail;
  final String otherUserProfileImageUrl;
  final ChatMessage lastMessage;

  Conversation({
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserEmail,
    required this.otherUserProfileImageUrl,
    required this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      otherUserId: json['otherUserId'],
      otherUserName: json['otherUserName'],
      otherUserEmail: json['otherUserEmail'],
      otherUserProfileImageUrl: json['otherUserProfileImageUrl'] ?? '',
      lastMessage: ChatMessage.fromJson(json['lastMessage']),
    );
  }
}
