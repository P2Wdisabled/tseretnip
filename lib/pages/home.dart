import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseRepository _repository = SupabaseRepository();
  bool _isLoading = false;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _likedPosts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('🔄 Starting to load posts...');
    setState(() => _isLoading = true);
    try {
      print('📡 Fetching posts from Supabase...');
      final posts = await _repository.getPhotos();
      print('✅ Received ${posts.length} posts');

      // Print first post for debugging
      if (posts.isNotEmpty) {
        print('📸 First post: ${posts[0].keys}');
        print('📸 Has image: ${posts[0].containsKey('image')}');
      }

      if (mounted) {
        setState(() {
          _posts = posts;
          _likedPosts = []; // Simplified - ignoring likes for now
        });
        print('✨ UI updated with ${_posts.length} posts');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading posts: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isLiked(int postId) {
    return _likedPosts.any((element) => element['post_id'] == postId);
  }

  Future<void> _toggleLike(int postId) async {
    // Check if user is authenticated
    if (_repository.currentUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to like posts')),
      );
      return;
    }

    try {
      if (_isLiked(postId)) {
        await _repository.unlikePost(postId);
      } else {
        await _repository.likePost(postId);
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Like failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinterest Clone'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? const Center(child: Text('No posts yet.\nPull to refresh.'))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final postId = post['id'] as int;
                  final base64Image = post['image'] as String?;
                  final isLiked = _isLiked(postId);

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image - decode base64
                        if (base64Image != null)
                          Image.memory(
                            base64Decode(
                              base64Image.contains(',')
                                  ? base64Image.split(',').last
                                  : base64Image,
                            ),
                            height: 300,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox(
                                  height: 300,
                                  child: Center(child: Icon(Icons.error)),
                                ),
                          )
                        else
                          const SizedBox(
                            height: 300,
                            child: Center(child: Text('No image')),
                          ),
                        // Like button
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              const Spacer(),
                              IconButton(
                                onPressed: () => _toggleLike(postId),
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
