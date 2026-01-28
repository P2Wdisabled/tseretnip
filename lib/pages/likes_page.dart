import 'package:flutter/material.dart';
import 'package:tseretnip/post.dart';
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
  final Set<int> _unlikedIds = {};

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

  void _onLikeChanged(int postId, bool isLiked) {
    if (!isLiked) {
      _unlikedIds.add(postId);
    } else {
      _unlikedIds.remove(postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Mes Likes',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              Navigator.of(context).pop(_unlikedIds.toList());
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _likedPosts.isEmpty
            ? const Center(child: Text('No liked posts yet.'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _likedPosts.length,
                itemBuilder: (context, index) {
                  final post = _likedPosts[index];
                  final postId = post['id'] as int;

                  return Post(
                    key: ValueKey(postId),
                    post: post,
                    initialIsLiked: true,
                    repository: _repository,
                    onLikeChanged: (isLiked) => _onLikeChanged(postId, isLiked),
                  );
                },
              ),
      ),
    );
  }
}
