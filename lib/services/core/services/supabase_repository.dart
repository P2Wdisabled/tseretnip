import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // -----------------------------------------------------------------------------
  // AUTH
  // -----------------------------------------------------------------------------

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }

  // -----------------------------------------------------------------------------
  // PHOTOS (POSTS)
  // -----------------------------------------------------------------------------

  /// Publishes a photo by uploading it to storage and creating a post record.
  Future<void> publishPhoto({
    required File imageFile,
    required String caption,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final String fileName =
        '${user.id}/${DateTime.now().toIso8601String()}.jpg';
    // Upload image to Supabase Storage bucket named 'posts'
    await _client.storage
        .from('posts')
        .upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    // Get public URL
    final String imageUrl = _client.storage
        .from('posts')
        .getPublicUrl(fileName);

    // Insert post record
    await _client.from('posts').insert({
      'user_id': user.id,
      'image_url': imageUrl,
      'caption': caption,
    });
  }

  /// Returns all photos (posts), ordered by creation date descending.
  Future<List<Map<String, dynamic>>> getPhotos() async {
    return await _client
        .from('posts')
        .select('*, likes(count)') // Join with profiles if needed
        .order('created_at', ascending: false);
  }

  Future<void> deletePhoto(int postId) async {
    await _client.from('posts').delete().eq('id', postId);
    // Note: To fully clean up, you should also delete the image from storage,
    // but that requires knowing the path or storing it in the DB.
  }

  // -----------------------------------------------------------------------------
  // LIKES
  // -----------------------------------------------------------------------------

  /// Returns all posts liked by the current user.
  Future<List<Map<String, dynamic>>> getLikedPosts() async {
    // Hardcoded user for testing
    const userId = "ac111517-5221-48e2-8843-78ee8a3cc6a3";

    // Select likes and join with posts to get post details
    return await _client
        .from('likes')
        .select('post_id, posts(*)')
        .eq('user_id', userId);
  }

  Future<void> likePost(int postId) async {
    // Hardcoded user for testing
    const userId = "ac111517-5221-48e2-8843-78ee8a3cc6a3";

    await _client.from('likes').insert({'user_id': userId, 'post_id': postId});
  }

  Future<void> unlikePost(int postId) async {
    // Hardcoded user for testing
    const userId = "ac111517-5221-48e2-8843-78ee8a3cc6a3";

    await _client
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('post_id', postId);
  }
}
