import 'package:e_sera/features/message/domain/entities/chat_message.dart';
import 'package:e_sera/features/message/domain/repos/message_repo.dart';
import 'package:e_sera/features/message/presentation/cubits/message_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageCubit extends Cubit<MessageState> {
  final MessageRepo messageRepo;

  MessageCubit({required this.messageRepo}) : super(MessageInitial());

  Future<void> fetchConversations(String userId) async {
    try {
      emit(MessageLoading());
      final conversations = await messageRepo.fetchConversations(userId);
      emit(ConversationsLoaded(conversations));
    } catch (e) {
      emit(MessageError("Error fetching conversations"));
    }
  }

  Future<void> fetchThread({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
  }) async {
    try {
      emit(MessageLoading());
      final messages = await messageRepo.fetchThread(
        currentUserId,
        otherUserId,
      );
      emit(
        ThreadLoaded(
          messages: messages,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        ),
      );
    } catch (e) {
      emit(MessageError("Error fetching messages"));
    }
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String otherUserName,
    required String text,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return;
    }

    try {
      final currentState = state;
      if (currentState is ThreadLoaded) {
        final pendingMessages = List<ChatMessage>.from(currentState.messages);
        emit(
          ThreadLoaded(
            messages: pendingMessages,
            otherUserId: receiverId,
            otherUserName: otherUserName,
          ),
        );
      }

      await messageRepo.sendMessage(senderId, receiverId, cleanText);
      final messages = await messageRepo.fetchThread(senderId, receiverId);
      emit(
        ThreadLoaded(
          messages: messages,
          otherUserId: receiverId,
          otherUserName: otherUserName,
        ),
      );
    } catch (e) {
      emit(MessageError("Error sending message"));
    }
  }

  Future<List<String>> suggestReplies(String message) {
    return messageRepo.suggestReplies(message);
  }
}
