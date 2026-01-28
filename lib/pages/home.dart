import 'package:flutter/material.dart';
import 'package:tseretnip/post.dart';
import 'package:tseretnip/pages/profile.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tseretnip',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black87),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.black87),
            onPressed: () async {
              final unlikedIds = await Navigator.of(context).push<List<int>>(
                MaterialPageRoute(builder: (context) => const LikesPage()),
              );

              if (unlikedIds != null && unlikedIds.isNotEmpty) {
                setState(() {
                  _likedPosts.removeWhere(
                    (element) => unlikedIds.contains(element['post_id']),
                  );

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
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
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
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  final postId = post['id'] as int;
                  final isLiked = _isLiked(postId);

                  return Post(
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
