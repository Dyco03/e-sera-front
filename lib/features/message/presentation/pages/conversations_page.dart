import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_sera/core/presentation/pages/image_viewer_page.dart';
import 'package:e_sera/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:e_sera/features/message/domain/entities/conversation.dart';
import 'package:e_sera/features/message/presentation/cubits/message_cubit.dart';
import 'package:e_sera/features/message/presentation/cubits/message_states.dart';
import 'package:e_sera/features/message/presentation/pages/thread_page.dart';
import 'package:e_sera/features/search/presentation/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  late final messageCubit = context.read<MessageCubit>();
  late final currentUser = context.read<AuthCubit>().currentUser;

  @override
  void initState() {
    super.initState();
    fetchConversations();
  }

  void fetchConversations() {
    final user = currentUser;
    if (user != null) {
      messageCubit.fetchConversations(user.uid);
    }
  }

  Future<void> openThread(Conversation conversation) async {
    final user = currentUser;
    if (user == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThreadPage(
          currentUserId: user.uid,
          otherUserId: conversation.otherUserId,
          otherUserName: conversation.otherUserName,
        ),
      ),
    );

    fetchConversations();
  }

  String previewFor(Conversation conversation) {
    final mine = conversation.lastMessage.senderId == currentUser?.uid;
    final prefix = mine ? "You: " : "";
    return "$prefix${conversation.lastMessage.text}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        foregroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            tooltip: "New message",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            ),
            icon: const Icon(Icons.edit_square),
          ),
        ],
      ),
      body: BlocBuilder<MessageCubit, MessageState>(
        builder: (context, state) {
          if (state is MessageLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConversationsLoaded) {
            final conversations = state.conversations;
            if (conversations.isEmpty) {
              return const Center(child: Text("No messages yet"));
            }

            return ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.secondary,
              ),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final profileImageUrl = conversation.otherUserProfileImageUrl
                    .trim();
                final hasProfileImage = profileImageUrl.isNotEmpty;
                return ListTile(
                  leading: GestureDetector(
                    onTap: hasProfileImage
                        ? () => ImageViewerPage.open(
                            context,
                            imageUrl: profileImageUrl,
                            title: conversation.otherUserName,
                          )
                        : null,
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      backgroundImage: hasProfileImage
                          ? CachedNetworkImageProvider(profileImageUrl)
                          : null,
                      child: hasProfileImage
                          ? null
                          : Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                    ),
                  ),
                  title: Text(conversation.otherUserName),
                  subtitle: Text(
                    previewFor(conversation),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () => openThread(conversation),
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
    );
  }
}
