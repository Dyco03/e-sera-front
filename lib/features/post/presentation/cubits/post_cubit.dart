import 'dart:typed_data';

import 'package:e_sera/features/post/domain/entitites/comment.dart';
import 'package:e_sera/features/post/domain/entitites/post.dart';
import 'package:e_sera/features/post/domain/repos/post_repo.dart';
import 'package:e_sera/features/post/presentation/cubits/post_states.dart';
import 'package:e_sera/features/storage/domain/storage_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PostCubit extends Cubit<PostStates> {
  final PostRepo postRepo;
  final StorageRepo storageRepo;

  PostCubit({required this.postRepo, required this.storageRepo})
    : super(PostsInitial());

  // create a new post
  Future<void> createPost(
    Post post, {
    String? imagePath,
    Uint8List? imageBytes,
  }) async {
    String? imageUrl;

    try {
      // handle image upload for mobile platforms (using file path)
      if (imagePath != null) {
        emit(PostUploading());
        imageUrl = await storageRepo.uploadPostImageMobile(imagePath);
      }
      // handle image upload for web platforms (using file bytes)
      else if (imageBytes != null) {
        emit(PostUploading());
        imageUrl = await storageRepo.uploadPostImageWeb(imageBytes);
      }

      // attach the image URL to the post
      final newPost = post.copyWith(imageUrl: imageUrl);

      // create post in the backend
      postRepo.createPost(newPost);

      // re-fetch all posts to emit a different state and avoid stuck loading
      fetchAllPosts();
    } catch (e) {
      emit(PostsError("Failed to create post : $e"));
      throw Exception("Failed to create post : $e");
    }
  }

  // fetch all posts
  Future<void> fetchAllPosts() async {
    try {
      emit(PostsLoading());
      final posts = await postRepo.fetchAllPosts();
      emit(PostsLoaded(posts));
    } catch (e) {
      emit(PostsError("Failed to fetch all posts : $e"));
    }
  }

  // delete a post
  Future<void> deletePost(String postId) async {
    try {
      await postRepo.deletePost(postId);
    } catch (e) {}
  }

  // toggle like on a post
  Future<void> toggleLikePost(String postId, String userId) async {
    try {
      await postRepo.toggleLikePost(postId, userId);
    } catch (e) {
      emit(PostsError("Failed to toggle like : $e"));
    }
  }

  // translate post text
  Future<String> translatePostText(String text, String targetLanguage) async {
    return postRepo.translatePostText(text, targetLanguage);
  }

  // summarize long text
  Future<String> summarizeText(String text) async {
    return postRepo.summarizeText(text);
  }

  // add a comment to a post
  Future<void> addComment(String postId, Comment comment) async {
    try {
      await postRepo.addComment(postId, comment);

      await fetchAllPosts();
    } catch (e) {
      emit(PostsError("Failed to add comment : $e"));
    }
  }

  // delete comment from a post
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await postRepo.deleteComment(postId, commentId);

      await fetchAllPosts();
    } catch (e) {
      emit(PostsError("Failed to delete comment : $e"));
    }
  }
}
