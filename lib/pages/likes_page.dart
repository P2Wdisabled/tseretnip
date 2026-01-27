import 'package:flutter/material.dart';
import 'package:tseretnip/pages/home.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  final SupabaseRepository _repository = SupabaseRepository();
  bool _isLoading = false;
  List<Map<String, dynamic>> _likedPosts = [];

  @override
  void initState() {
    super.initState();
    _loadLikedPosts();
  }

  Future<void> _loadLikedPosts() async {
    setState(() => _isLoading = true);
    try {
      final likedData = await _repository.getLikedPosts();

      // Transform data: Supabase returns {post_id: ..., posts: {...}}
      // We need to extract 'posts' and flatten it for PostCard
      final List<Map<String, dynamic>> posts = [];
      for (var item in likedData) {
        if (item['posts'] != null) {
          final post = item['posts'] as Map<String, dynamic>;
          posts.add(post);
        }
      }

      if (mounted) {
        setState(() {
          _likedPosts = posts;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading likes: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Likes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likedPosts.isEmpty
          ? const Center(child: Text('No liked posts yet.'))
          : ListView.builder(
              itemCount: _likedPosts.length,
              itemBuilder: (context, index) {
                final post = _likedPosts[index];
                final postId = post['id'] as int;

                // On this page, items are by definition liked initially.
                // If user unlikes, the PostCard handles the state locally.
                // If they refresh, it will disappear.
                return PostCard(
                  key: ValueKey(postId),
                  post: post,
                  initialIsLiked: true,
                  repository: _repository,
                );
              },
            ),
    );
  }
}
