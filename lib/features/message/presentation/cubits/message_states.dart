import 'package:e_sera/features/message/domain/entities/chat_message.dart';
import 'package:e_sera/features/message/domain/entities/conversation.dart';

abstract class MessageState {}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class ConversationsLoaded extends MessageState {
  final List<Conversation> conversations;

  ConversationsLoaded(this.conversations);
}

class ThreadLoaded extends MessageState {
  final List<ChatMessage> messages;
  final String otherUserId;
  final String otherUserName;

  ThreadLoaded({
    required this.messages,
    required this.otherUserId,
    required this.otherUserName,
  });
}

class MessageError extends MessageState {
  final String message;

  MessageError(this.message);
}
