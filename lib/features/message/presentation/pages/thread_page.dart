import 'package:e_sera/features/message/domain/entities/chat_message.dart';
import 'package:e_sera/features/message/presentation/cubits/message_cubit.dart';
import 'package:e_sera/features/message/presentation/cubits/message_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThreadPage extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  const ThreadPage({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final TextEditingController messageController = TextEditingController();
  late final messageCubit = context.read<MessageCubit>();

  @override
  void initState() {
    super.initState();
    fetchThread();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void fetchThread() {
    messageCubit.fetchThread(
      currentUserId: widget.currentUserId,
      otherUserId: widget.otherUserId,
      otherUserName: widget.otherUserName,
    );
  }

  Future<void> sendMessage() async {
    final text = messageController.text;
    if (text.trim().isEmpty) {
      return;
    }

    messageController.clear();
    await messageCubit.sendMessage(
      senderId: widget.currentUserId,
      receiverId: widget.otherUserId,
      otherUserName: widget.otherUserName,
      text: text,
    );
  }

  void useSuggestedReply(String reply) {
    messageController.text = reply;
    messageController.selection = TextSelection.collapsed(offset: reply.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<MessageCubit, MessageState>(
              builder: (context, state) {
                if (state is MessageLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ThreadLoaded) {
                  if (state.messages.isEmpty) {
                    return const Center(child: Text("Start the conversation"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      return _MessageBubble(
                        key: ValueKey(message.id),
                        message: message,
                        isMine: message.senderId == widget.currentUserId,
                        onReplySelected: useSuggestedReply,
                      );
                    },
                  );
                }

                if (state is MessageError) {
                  return Center(child: Text(state.message));
                }

                return const SizedBox();
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "Message",
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.secondary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: "Send",
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final ValueChanged<String> onReplySelected;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.onReplySelected,
  });

  @override
  Widget build(BuildContext context) {
    final background = isMine
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.secondary;
    final foreground = isMine
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.inversePrimary;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(message.text, style: TextStyle(color: foreground)),
          ),
          if (!isMine)
            _SuggestedReplies(
              message: message.text,
              onReplySelected: onReplySelected,
            ),
        ],
      ),
    );
  }
}

class _SuggestedReplies extends StatefulWidget {
  final String message;
  final ValueChanged<String> onReplySelected;

  const _SuggestedReplies({
    required this.message,
    required this.onReplySelected,
  });

  @override
  State<_SuggestedReplies> createState() => _SuggestedRepliesState();
}

class _SuggestedRepliesState extends State<_SuggestedReplies> {
  bool isLoading = false;
  bool hasError = false;
  List<String> replies = const [];

  Future<void> loadReplies() async {
    if (isLoading || replies.isNotEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final suggestions = await context.read<MessageCubit>().suggestReplies(
        widget.message,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        replies = suggestions;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2, bottom: 6),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: replies.isEmpty
            ? OutlinedButton.icon(
                key: ValueKey("$isLoading-$hasError"),
                onPressed: isLoading ? null : loadReplies,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  foregroundColor: hasError
                      ? colorScheme.error
                      : colorScheme.primary,
                  side: BorderSide(
                    color: hasError
                        ? colorScheme.error
                        : colorScheme.primary.withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Icon(hasError ? Icons.refresh : Icons.auto_awesome),
                label: Text(hasError ? "Réessayer" : "Suggestions"),
              )
            : ConstrainedBox(
                key: ValueKey(replies.join("|")),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.82,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: replies
                      .map(
                        (reply) => ActionChip(
                          avatar: const Icon(Icons.auto_awesome, size: 16),
                          label: Text(reply),
                          labelStyle: TextStyle(color: colorScheme.primary),
                          backgroundColor: colorScheme.primary.withValues(
                            alpha: 0.08,
                          ),
                          side: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          onPressed: () => widget.onReplySelected(reply),
                        ),
                      )
                      .toList(),
                ),
              ),
      ),
    );
  }
}
