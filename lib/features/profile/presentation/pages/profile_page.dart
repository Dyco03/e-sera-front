import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_sera/core/presentation/pages/image_viewer_page.dart';
import 'package:e_sera/features/auth/domain/entities/app_user.dart';
import 'package:e_sera/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:e_sera/features/message/presentation/pages/thread_page.dart';
import 'package:e_sera/features/post/presentation/components/post_tile.dart';
import 'package:e_sera/features/post/presentation/cubits/post_cubit.dart';
import 'package:e_sera/features/post/presentation/cubits/post_states.dart';
import 'package:e_sera/features/profile/presentation/components/bio_box.dart';
import 'package:e_sera/features/profile/presentation/components/follow_button.dart';
import 'package:e_sera/features/profile/presentation/components/profile_stats.dart';
import 'package:e_sera/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:e_sera/features/profile/presentation/cubits/profile_states.dart';
import 'package:e_sera/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:e_sera/features/profile/presentation/pages/follower_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfilePage extends StatefulWidget {
  final String uid;

  const ProfilePage({super.key, required this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // cubits
  late final authcubit = context.read<AuthCubit>();
  late final profileCubit = context.read<ProfileCubit>();

  // current user
  late AppUser? currentUser = authcubit.currentUser;

  // posts
  int postCount = 0;

  // on startup

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // load user profile data
    profileCubit.fetchUserProfile(widget.uid);
  }

  /*

  FOLLOW / UNFOLLOW

  */

  void followButtonPressed() {
    final profileState = profileCubit.state;
    if (profileState is! ProfileLoaded) {
      return; // return if the profile is not loaded
    }

    final profileUser = profileState.profileUser;
    final isFollowing = profileUser.followers.contains(currentUser!.uid);

    // optimistically update UI
    setState(() {
      // unfollow
      if (isFollowing) {
        profileUser.followers.remove(currentUser!.uid);
      }
      // follow
      else {
        profileUser.followers.add(currentUser!.uid);
      }
    });

    profileCubit.toggleFollow(currentUser!.uid, widget.uid).catchError((error) {
      // revert update if there's an error
      setState(() {
        // unfollow
        if (isFollowing) {
          profileUser.followers.add(currentUser!.uid);
        }
        // follow
        else {
          profileUser.followers.remove(currentUser!.uid);
        }
      });
    });
  }

  // BUILD UI
  @override
  Widget build(BuildContext context) {
    // is own post
    bool isOwnPost = (widget.uid == currentUser!.uid);

    // scaffold
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        // loaded
        if (state is ProfileLoaded) {
          final user = state.profileUser;
          // scaffold
          return Scaffold(
            // app bar
            appBar: AppBar(
              title: Text(user.name),
              foregroundColor: Theme.of(context).colorScheme.primary,
              actions: [
                // edit profile button
                if (isOwnPost)
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(user: user),
                      ),
                    ),
                    icon: const Icon(Icons.settings),
                  ),
              ],
            ),

            // body
            body: ListView(
              children: [
                // email
                Center(
                  child: Text(
                    user.email,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // profile picture
                GestureDetector(
                  onTap: () => ImageViewerPage.open(
                    context,
                    imageUrl: user.profileImageUrl,
                    title: user.name,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: user.profileImageUrl,
                    // loading
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),

                    // error -> failed to load
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),

                    // loaded
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                      height: 120,
                      width: 120,
                    ),
                  ),
                ), // cached network image

                const SizedBox(height: 25),

                // profile stats
                ProfileStats(
                  postCount: postCount,
                  followerCount: user.followers.length,
                  followingCount: user.followers.length,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowerPage(
                        followers: user.followers,
                        following: user.following,
                      ),
                    ),
                  ),
                ),

                // follow button
                if (!isOwnPost)
                  FollowButton(
                    onPressed: followButtonPressed,
                    isFollowing: user.followers.contains(currentUser!.uid),
                  ),

                if (!isOwnPost)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ThreadPage(
                            currentUserId: currentUser!.uid,
                            otherUserId: user.uid,
                            otherUserName: user.name,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Message"),
                    ),
                  ),

                // bio box
                Padding(
                  padding: const EdgeInsets.only(left: 25),
                  child: Row(
                    children: [
                      Text(
                        "Bio",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                BioBox(text: user.bio),

                // posts
                Padding(
                  padding: const EdgeInsets.only(left: 25, top: 25),
                  child: Row(
                    children: [
                      Text(
                        "Posts",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // list of posts from this user
                BlocBuilder<PostCubit, PostStates>(
                  builder: (context, state) {
                    // posts loaded
                    if (state is PostsLoaded) {
                      // filter posts by user id
                      final userPosts = state.posts
                          .where((post) => post.userId == widget.uid)
                          .toList();

                      postCount = userPosts.length;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: postCount,
                        itemBuilder: (context, index) {
                          // get individual post
                          final post = userPosts[index];

                          // return as post tile UI
                          return PostTile(
                            post: post,
                            onDeletePressed: () =>
                                context.read<PostCubit>().deletePost(post.id),
                          );
                        },
                      );
                    }
                    // posts loading
                    else if (state is PostsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else {
                      return const Center(child: Text("No post.."));
                    }
                  },
                ),
              ],
            ),
          );
        }
        // loading
        else if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return const Center(child: Text("No profil found.."));
        }
      },
    );
  }
}
