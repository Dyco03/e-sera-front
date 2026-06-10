import 'package:e_sera/features/post/domain/entitites/comment.dart';
import 'package:e_sera/features/post/domain/entitites/post.dart';

abstract class PostRepo {
  Future<String> translatePostText(String text, String targetLanguage);
  Future<String> summarizeText(String text);
  Future<List<Post>> fetchAllPosts();
  Future<void> createPost(Post post);
  Future<void> deletePost(String postId);
  Future<List<Post>> fetchPostsByUserId(String userId);
  Future<void> toggleLikePost(String postId, String userId);
  Future<void> addComment(String postId, Comment comment);
  Future<void> deleteComment(String postId, String commentId);
}
