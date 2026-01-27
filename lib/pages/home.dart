import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tseretnip/pages/likes_page.dart';
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
        final liked = await _repository.getLikedPosts();

        setState(() {
          _posts = posts;
          _likedPosts = liked;
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

  int _getLikeCount(Map<String, dynamic> post) {
    try {
      final likesData = post['likes'] as List<dynamic>?;
      if (likesData != null && likesData.isNotEmpty) {
        return likesData[0]['count'] as int;
      }
    } catch (e) {
      print('Error parsing like count: $e');
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinterest Clone'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () async {
              final unlikedIds = await Navigator.of(context).push<List<int>>(
                MaterialPageRoute(builder: (context) => const LikesPage()),
              );

              if (unlikedIds != null && unlikedIds.isNotEmpty) {
                // Locally update state for better UX (Dynamic/Cached feel)
                setState(() {
                  // 1. Remove from _likedPosts
                  _likedPosts.removeWhere(
                    (element) => unlikedIds.contains(element['post_id']),
                  );

                  // 2. Update count in _posts
                  for (var id in unlikedIds) {
                    final index = _posts.indexWhere((p) => p['id'] == id);
                    if (index != -1) {
                      final currentCount = _getLikeCount(_posts[index]);
                      if (currentCount > 0) {
                        _posts[index]['likes'] = [
                          {'count': currentCount - 1},
                        ];
                      }
                    }
                  }
                });

                // Optionally reload to be perfectly safe, but local update provides the dynamic feel
                // _loadData();
              }
            },
          ),
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
                  final isLiked = _isLiked(postId);

                  return PostCard(
                    key: ValueKey(postId),
                    post: post,
                    initialIsLiked: isLiked,
                    repository: _repository,
                  );
                },
              ),
            ),
    );
  }
}

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool initialIsLiked;
  final SupabaseRepository repository;
  final Function(bool isLiked)? onLikeChanged;

  const PostCard({
    super.key,
    required this.post,
    required this.initialIsLiked,
    required this.repository,
    this.onLikeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final base64Image = post['image'] as String?;
    final postId = post['id'] as int;

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
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 300,
                child: Center(child: Icon(Icons.error)),
              ),
            )
          else
            const SizedBox(height: 300, child: Center(child: Text('No image'))),
          // Like button
          PostActionsBar(
            postId: postId,
            initialCount: _getLikeCount(post),
            initialIsLiked: initialIsLiked,
            repository: repository,
            onLikeChanged: onLikeChanged,
          ),
        ],
      ),
    );
  }

  int _getLikeCount(Map<String, dynamic> post) {
    try {
      final likesData = post['likes'] as List<dynamic>?;
      if (likesData != null && likesData.isNotEmpty) {
        return likesData[0]['count'] as int;
      }
    } catch (e) {
      print('Error parsing like count: $e');
    }
    return 0;
  }
}

class PostActionsBar extends StatefulWidget {
  final int postId;
  final int initialCount;
  final bool initialIsLiked;
  final SupabaseRepository repository;
  final Function(bool isLiked)? onLikeChanged;

  const PostActionsBar({
    super.key,
    required this.postId,
    required this.initialCount,
    required this.initialIsLiked,
    required this.repository,
    this.onLikeChanged,
  });

  @override
  State<PostActionsBar> createState() => _PostActionsBarState();
}

class _PostActionsBarState extends State<PostActionsBar> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likeCount = widget.initialCount;
  }

  @override
  void didUpdateWidget(covariant PostActionsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIsLiked != oldWidget.initialIsLiked ||
        widget.initialCount != oldWidget.initialCount) {
      _isLiked = widget.initialIsLiked;
      _likeCount = widget.initialCount;
    }
  }

  Future<void> _toggleLike() async {
    final previousLikedState = _isLiked;
    final previousCount = _likeCount;

    setState(() {
      if (_isLiked) {
        _likeCount--;
        _isLiked = false;
      } else {
        _likeCount++;
        _isLiked = true;
      }
    });

    // Notify parent about optimistic update
    widget.onLikeChanged?.call(_isLiked);

    try {
      if (previousLikedState) {
        await widget.repository.unlikePost(widget.postId);
      } else {
        await widget.repository.likePost(widget.postId);
      }
    } catch (e) {
      print('❌ Like toggle failed: $e');
      if (mounted) {
        // Rollback
        setState(() {
          _isLiked = previousLikedState;
          _likeCount = previousCount;
        });
        // Notify rollback
        widget.onLikeChanged?.call(_isLiked);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          const Spacer(),
          Text(_likeCount.toString()),
          IconButton(
            onPressed: _toggleLike,
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
