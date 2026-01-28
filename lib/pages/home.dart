import 'package:flutter/material.dart';
import 'package:tseretnip/models/models.dart';
import 'package:tseretnip/post.dart';
import 'package:tseretnip/pages/profile.dart';
import 'package:tseretnip/pages/likes_page.dart';
import 'package:tseretnip/pages/upload_photos_page.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseRepository _repository = SupabaseRepository();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<Post> _posts = [];
  List<Like> _likedPosts = [];

  // Pagination state
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadData(loadMore: true);
      }
    }
  }

  Future<void> _loadData({bool refresh = false, bool loadMore = false}) async {
    if (_isLoading) return;
    if (loadMore && !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      print('📡 Fetching posts from Supabase...');
      List<Map<String, dynamic>> newPostsData = [];

      if (refresh) {
        _currentPage = 0;
        _hasMore = true;
        // 1. On récupère d'abord les 3 plus récents
        newPostsData = await _repository.fetchRecentPosts();
      }

      // 2. On récupère la page actuelle basée sur le ratio
      final offset = _currentPage * _pageSize;
      final rankedPostsData = await _repository.fetchRankedPosts(
        offset: offset,
        limit: _pageSize,
      );

      // Filtrer pour éviter les doublons si un post récent est aussi bien classé par ratio
      final existingIds = newPostsData.map((p) => p['id']).toSet();
      final filteredRanked = rankedPostsData.where(
        (p) => !existingIds.contains(p['id']),
      ).toList();

      if (refresh) {
        newPostsData.addAll(filteredRanked);
      }

      if (rankedPostsData.length < _pageSize) {
        _hasMore = false;
      }

      if (mounted) {
        final likedData = await _repository.getLikedPosts();
        setState(() {
          if (refresh) {
            _posts = newPostsData.map((data) => Post.fromJson(data)).toList();
          } else {
            _posts.addAll(filteredRanked.map((data) => Post.fromJson(data)).toList());
          }
          _likedPosts = (likedData as List<dynamic>).map((data) => Like.fromJson(data as Map<String, dynamic>)).toList();
          _currentPage++;
        });
      }
    } catch (e) {
      print('❌ Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isLiked(int postId) {
    return _likedPosts.any((like) => like.postId == postId);
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
            icon: const Icon(Icons.add_circle, color: Colors.black87),
            tooltip: 'Upload Photo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UploadPhotosPage(),
                ),
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
                    (like) => unlikedIds.contains(like.postId),
                  );

                  for (var id in unlikedIds) {
                    final index = _posts.indexWhere((p) => p.id == id);
                    if (index != -1) {
                      final currentCount = _posts[index].likeCount;
                      if (currentCount > 0) {
                        _posts[index] = _posts[index].copyWith(
                          likeCount: currentCount - 1,
                        );
                      }
                    }
                  }
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _isLoading ? null : () => _loadData(refresh: true),
          ),
        ],
      ),
      body: _isLoading && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? const Center(child: Text('No posts yet.\nPull to refresh.'))
          : RefreshIndicator(
              onRefresh: () => _loadData(refresh: true),
              child: ListView.builder(
                itemCount: _posts.length + (_hasMore ? 1 : 0),
                controller: _scrollController,
                itemBuilder: (context, index) {
                  if (index == _posts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final post = _posts[index];
                  final postId = post.id;
                  final isLiked = _isLiked(postId);

                  return PostWidget(
                    key: ValueKey(postId),
                    post: post,
                    initialIsLiked: isLiked,
                    repository: _repository,
                    onDeleted: () {
                      setState(() {
                        _posts.removeWhere((p) => p.id == postId);
                        _likedPosts.removeWhere(
                          (like) => like.postId == postId,
                        );
                      });
                    },
                  );
                },
              ),
            ),
    );
  }
}
