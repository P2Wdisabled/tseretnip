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
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    // Insérer dans la table accounts si l'utilisateur est créé
    final String userId = response.user!.id;
    if (response.user != null) {
      print("coucou");
      try {
        await _client.from('accounts').insert({
          'id': userId,
          'username': username,
        });
      } catch (e) {
        print("Erreur lors de l'insertion dans accounts: $e");
      }
    }

    return response;
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

    try {
      final response = await _client
          .from('accounts')
          .select()
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      print('Erreur getCurrentProfile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    try {
      final response = await _client
          .from('accounts')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      print('Erreur getProfileById: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    String? username,
    String? description,
    String? avatarUrl,
    String? bannerUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final Map<String, dynamic> updates = {};
    if (username != null) updates['username'] = username;
    if (description != null) updates['description'] = description;
    if (avatarUrl != null) updates['avatar'] = avatarUrl;
    if (bannerUrl != null) updates['banner'] = bannerUrl;

    if (updates.isNotEmpty) {
      await _client.from('accounts').update(updates).eq('id', user.id);
    }
  }

  Future<String> uploadProfilePicture(File imageFile) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final String fileName =
        '${user.id}/avatar_${DateTime.now().toIso8601String()}.jpg';

    await _client.storage
        .from('avatars')
        .upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final String imageUrl = _client.storage
        .from('avatars')
        .getPublicUrl(fileName);

    return imageUrl;
  }

  Future<String> uploadBanner(File imageFile) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final String fileName =
        '${user.id}/banner_${DateTime.now().toIso8601String()}.jpg';

    await _client.storage
        .from('banner')
        .upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final String imageUrl = _client.storage
        .from('banner')
        .getPublicUrl(fileName);

    return imageUrl;
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
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    // Select likes and join with posts to get post details
    return await _client
        .from('likes')
        .select('post_id, posts(*, likes(count))')
        .eq('user_id', user.id);
  }

  Future<void> likePost(int postId) async {
    // Hardcoded user for testing
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('likes').insert({'user_id': user.id, 'post_id': postId});
  }

  Future<void> unlikePost(int postId) async {
    // Hardcoded user for testing
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client
        .from('likes')
        .delete()
        .eq('user_id', user.id)
        .eq('post_id', postId);
  }
}
