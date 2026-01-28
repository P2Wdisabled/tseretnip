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
    // Assuming Android 14+ or manual Pop handling is not strictly required if using WillPopScope logic
    // or simply wrapping in PopScope (available in newer Flutter).
    // We will use WillPopScope for broader compatibility or PopScope if on very new SDK.
    // Let's use PopScope as it is the modern standard.
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // This is a bit tricky with PopScope, actually Navigator.pop with result is better handled
        // by intercepting the back button or just standard Navigator push/pop contract.
        // However, system back button needs interception.
      },
      // Actually simpler: Just use WillPopScope or simply return result in Leading button.
      // But standard Android back button returns null result by default.
      // We need to intercept the pop.
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Likes'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
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
                itemCount: _likedPosts.length,
                itemBuilder: (context, index) {
                  final post = _likedPosts[index];
                  final postId = post['id'] as int;

                  return PostCard(
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
