import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_sera/core/presentation/pages/image_viewer_page.dart';
import 'package:e_sera/features/auth/domain/entities/app_user.dart';
import 'package:e_sera/features/auth/presentation/components/my_text_filed.dart';
import 'package:e_sera/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:e_sera/features/post/domain/entitites/comment.dart';
import 'package:e_sera/features/post/domain/entitites/post.dart';
import 'package:e_sera/features/post/presentation/components/comment_tile.dart';
import 'package:e_sera/features/post/presentation/cubits/post_cubit.dart';
import 'package:e_sera/features/post/presentation/cubits/post_states.dart';
import 'package:e_sera/features/profile/domain/entities/profile_user.dart';
import 'package:e_sera/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:e_sera/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final void Function()? onDeletePressed;

  const PostTile({
    super.key,
    required this.post,
    required this.onDeletePressed,
  });

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  static const int _longTextThreshold = 240;

  // cubits
  late final profileCubit = context.read<ProfileCubit>();
  late final postCubit = context.read<PostCubit>();

  bool isOwnPost = false;

  // current user
  AppUser? currentUser;

  // post user
  ProfileUser? postUser;

  String? translatedText;
  String? translatedLanguage;
  bool isTranslating = false;
  bool isPostExpanded = false;
  bool isTranslationExpanded = false;
  bool isSummarizingPost = false;
  bool isSummarizingTranslation = false;
  String? postSummary;
  String? translationSummary;

  // on startup,
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getCurrentUser();
    fetchPostUser();
  }

  void getCurrentUser() {
    final authCubit = context.read<AuthCubit>();
    currentUser = authCubit.currentUser;
    isOwnPost = (widget.post.userId == currentUser!.uid);
  }

  Future<void> fetchPostUser() async {
    final fetchedUser = await profileCubit.getUserProfile(widget.post.userId);
    if (!mounted) return;
    if (fetchedUser != null) {
      setState(() {
        postUser = fetchedUser;
      });
    }
  }

  /*
  LIKES
  */

  // user tapped like button
  void toggleLikePost() {
    // current like status
    final isLiked = widget.post.likes.contains(currentUser!.uid);

    // optimistically update the like state to avoid refreshing on each like
    setState(() {
      if (isLiked) {
        widget.post.likes.remove(currentUser!.uid); // unlike
      } else {
        widget.post.likes.add(currentUser!.uid); // like
      }
    });

    // update like
    postCubit.toggleLikePost(widget.post.id, currentUser!.uid).catchError((
      error,
    ) {
      /* If there is an error, revert to the original values so the like state
      does not stay updated when Firestore was not updated.
      */
      setState(() {
        if (isLiked) {
          widget.post.likes.add(currentUser!.uid); // revert unlike
        } else {
          widget.post.likes.remove(currentUser!.uid); // revert like
        }
      });
    });
  }

  /*

    COMMENT


  */
  // comment text controller
  final commentTextController = TextEditingController();

  Future<void> openTranslationLanguageMenu() async {
    if (widget.post.text.trim().isEmpty) {
      return;
    }

    final language = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Translate into"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop("Malagasy"),
            child: const Text("Malagasy"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop("French"),
            child: const Text("Français"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop("English"),
            child: const Text("Anglais"),
          ),
        ],
      ),
    );

    if (language == null) {
      return;
    }

    await translatePost(language);
  }

  Future<void> translatePost(String language) async {
    setState(() {
      isTranslating = true;
    });

    try {
      final translation = await postCubit.translatePostText(
        widget.post.text,
        language,
      );
      if (!mounted) return;
      setState(() {
        translatedText = translation;
        translatedLanguage = language;
        translationSummary = null;
        isTranslationExpanded = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Translation of the post impossible : $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isTranslating = false;
        });
      }
    }
  }

  Future<void> summarizePostText() async {
    if (widget.post.text.trim().isEmpty) {
      return;
    }

    await summarizeText(text: widget.post.text, isTranslation: false);
  }

  Future<void> summarizeTranslationText() async {
    final text = translatedText;
    if (text == null) {
      return;
    }

    await summarizeText(text: text, isTranslation: true);
  }

  Future<void> summarizeText({
    required String text,
    required bool isTranslation,
  }) async {
    setState(() {
      if (isTranslation) {
        isSummarizingTranslation = true;
      } else {
        isSummarizingPost = true;
      }
    });

    try {
      final summary = await postCubit.summarizeText(text);
      if (!mounted) return;
      setState(() {
        if (isTranslation) {
          translationSummary = summary;
        } else {
          postSummary = summary;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Impossible to resume : $e")));
    } finally {
      if (mounted) {
        setState(() {
          if (isTranslation) {
            isSummarizingTranslation = false;
          } else {
            isSummarizingPost = false;
          }
        });
      }
    }
  }

  Widget buildAiTextBlock({
    required String text,
    required bool isExpanded,
    required bool isSummarizing,
    required VoidCallback onToggleExpanded,
    required VoidCallback onSummarize,
    String? title,
    String? summary,
    VoidCallback? onCloseBlock,
    VoidCallback? onCloseSummary,
  }) {
    final isLongText = text.length > _longTextThreshold;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || onCloseBlock != null)
              Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (onCloseBlock != null)
                    IconButton(
                      onPressed: onCloseBlock,
                      icon: const Icon(Icons.close),
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      tooltip: "Fermer",
                    ),
                ],
              ),
            Text(
              text,
              maxLines: isLongText && !isExpanded ? 4 : null,
              overflow: isLongText && !isExpanded
                  ? TextOverflow.ellipsis
                  : TextOverflow.visible,
              style: TextStyle(
                color: title == null
                    ? Theme.of(context).colorScheme.inversePrimary
                    : Theme.of(context).colorScheme.primary,
                fontSize: title == null ? 15 : 14,
                fontStyle: title == null ? FontStyle.normal : FontStyle.italic,
                fontWeight: title == null ? FontWeight.w400 : FontWeight.normal,
              ),
            ),
            if (isLongText)
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: onToggleExpanded,
                    child: Text(isExpanded ? "Less" : "More"),
                  ),
                  TextButton.icon(
                    onPressed: isSummarizing ? null : onSummarize,
                    icon: isSummarizing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(isSummarizing ? "..." : "Resume"),
                  ),
                ],
              ),
            if (summary != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Resume : $summary",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (onCloseSummary != null)
                      IconButton(
                        onPressed: onCloseSummary,
                        icon: const Icon(Icons.close),
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        tooltip: "close the resume",
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // open comment box -> user wants to type a new comment
  void openNewCommentBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add a new comment"),
        content: MyTextFiled(
          controller: commentTextController,
          hintText: "Type a comment",
          obscureText: false,
        ),
        actions: [
          // cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              addComment();
              Navigator.of(context).pop();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void addComment() {
    // create a new comment
    final newComment = Comment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      postId: widget.post.id,
      userId: currentUser!.uid,
      userName: currentUser!.name,
      text: commentTextController.text,
      timestamp: DateTime.now(),
    );

    // add comment using cubit
    if (commentTextController.text.isNotEmpty) {
      postCubit.addComment(widget.post.id, newComment);
    }
  }

  @override
  void dispose() {
    commentTextController.dispose();
    super.dispose();
  }

  // show options for deletion
  void showOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post?"),
        actions: [
          // cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          // delete button
          TextButton(
            onPressed: () {
              widget.onDeletePressed!();
              Navigator.of(context).pop();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    final hasCaption = widget.post.text.trim().isNotEmpty;
    final hasImage = widget.post.imageUrl.trim().isNotEmpty;
    final profileImageUrl = postUser?.profileImageUrl.trim() ?? '';
    final hasProfileImage = profileImageUrl.isNotEmpty;

    return Container(
      color: Theme.of(context).colorScheme.secondary,
      child: Column(
        children: [
          // Top section: profile picture / name / delete button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(uid: widget.post.userId),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // profile picture
                  hasProfileImage
                      ? GestureDetector(
                          onTap: () => ImageViewerPage.open(
                            context,
                            imageUrl: profileImageUrl,
                            title: widget.post.userName,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: profileImageUrl,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person),
                            imageBuilder: (context, imageProvider) => Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const Icon(Icons.person),

                  const SizedBox(width: 10),
                  // name
                  Expanded(
                    child: Text(
                      widget.post.userName,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // delete button
                  if (isOwnPost)
                    GestureDetector(
                      onTap: showOptions,
                      child: Icon(
                        Icons.delete,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (hasCaption)
            buildAiTextBlock(
              text: widget.post.text,
              isExpanded: isPostExpanded,
              isSummarizing: isSummarizingPost,
              summary: postSummary,
              onCloseSummary: () {
                setState(() {
                  postSummary = null;
                });
              },
              onToggleExpanded: () {
                setState(() {
                  isPostExpanded = !isPostExpanded;
                });
              },
              onSummarize: summarizePostText,
            ),

          if (translatedText != null)
            buildAiTextBlock(
              title: translatedLanguage,
              text: translatedText!,
              isExpanded: isTranslationExpanded,
              isSummarizing: isSummarizingTranslation,
              summary: translationSummary,
              onCloseBlock: () {
                setState(() {
                  translatedText = null;
                  translatedLanguage = null;
                  translationSummary = null;
                  isTranslationExpanded = false;
                });
              },
              onCloseSummary: () {
                setState(() {
                  translationSummary = null;
                });
              },
              onToggleExpanded: () {
                setState(() {
                  isTranslationExpanded = !isTranslationExpanded;
                });
              },
              onSummarize: summarizeTranslationText,
            ),

          // image
          if (hasImage)
            GestureDetector(
              onTap: () =>
                  ImageViewerPage.open(context, imageUrl: widget.post.imageUrl),
              child: CachedNetworkImage(
                imageUrl: widget.post.imageUrl,
                height: 430,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(height: 430),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),

          // buttons -> like, comment, timestamp
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Row(
                    children: [
                      // like button
                      GestureDetector(
                        onTap: toggleLikePost,
                        child: Icon(
                          widget.post.likes.contains(currentUser!.uid)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: widget.post.likes.contains(currentUser!.uid)
                              ? Colors.blue
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),

                      // like count
                      Text(
                        widget.post.likes.length.toString(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // comment button
                GestureDetector(
                  onTap: openNewCommentBox,
                  child: Icon(
                    Icons.comment,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                Text(
                  widget.post.comments.length.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(width: 12),

                if (hasCaption)
                  TextButton.icon(
                    onPressed: isTranslating
                        ? null
                        : openTranslationLanguageMenu,
                    icon: isTranslating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.translate),
                    label: Text(isTranslating ? "..." : "Translate"),
                  ),

                if (hasCaption) const SizedBox(width: 8),

                // timestamp
                Expanded(
                  child: Text(
                    widget.post.timestamp.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),

          // COMMENT SECTION
          BlocBuilder<PostCubit, PostStates>(
            builder: (context, state) {
              // LOADED
              if (state is PostsLoaded) {
                // final individual post
                final post = state.posts.firstWhere(
                  (post) => (post.id == widget.post.id),
                );

                if (post.comments.isNotEmpty) {
                  // how many comments to show
                  int showCommentCount = post.comments.length;

                  // comment section
                  return ListView.builder(
                    itemCount: showCommentCount,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      // get individual comment
                      final comment = post.comments[index];

                      // comment tile UI
                      return CommentTile(comment: comment);
                    },
                  );
                }
              }

              // LOADING
              if (state is PostsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              // ERROR
              else if (state is PostsError) {
                return Center(child: Text(state.message));
              } else {
                return const SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }
}
