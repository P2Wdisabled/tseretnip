import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tseretnip/models/models.dart';
import 'package:tseretnip/post.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';
import 'package:tseretnip/theme/theme.dart';
import 'package:tseretnip/widgets/widgets.dart';

class HomePage extends StatefulWidget {
  final List<int>? pendingUnlikedIds;
  final VoidCallback? onLikesSynced;

  const HomePage({
    super.key,
    this.pendingUnlikedIds,
    this.onLikesSynced,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final SupabaseRepository _repository = SupabaseRepository();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<Post> _posts = [];
  List<Like> _likedPosts = [];

  // Pagination state
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  // Animation
  late AnimationController _titleController;
  late Animation<double> _titleAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _titleAnimation = CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOutBack,
    );
    _titleController.forward();
    _loadData(refresh: true);
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync unliked posts from likes page
    if (widget.pendingUnlikedIds != null && 
        widget.pendingUnlikedIds != oldWidget.pendingUnlikedIds) {
      _syncUnlikedPosts(widget.pendingUnlikedIds!);
    }
  }

  void _syncUnlikedPosts(List<int> unlikedIds) {
    setState(() {
      _likedPosts.removeWhere((like) => unlikedIds.contains(like.postId));
      for (var id in unlikedIds) {
        final index = _posts.indexWhere((p) => p.id == id);
        if (index != -1) {
          final currentCount = _posts[index].likeCount;
          if (currentCount > 0) {
            _posts[index] = _posts[index].copyWith(likeCount: currentCount - 1);
          }
        }
      }
    });
    widget.onLikesSynced?.call();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
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
        newPostsData = await _repository.fetchRecentPosts();
      }

      final offset = _currentPage * _pageSize;
      final rankedPostsData = await _repository.fetchRankedPosts(
        offset: offset,
        limit: _pageSize,
      );

      final existingIds = newPostsData.map((p) => p['id']).toSet();
      final filteredRanked = rankedPostsData
          .where((p) => !existingIds.contains(p['id']))
          .toList();

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
            _posts.addAll(
              filteredRanked.map((data) => Post.fromJson(data)).toList(),
            );
          }
          _likedPosts = (likedData as List<dynamic>)
              .map((data) => Like.fromJson(data as Map<String, dynamic>))
              .toList();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(context, isDark),
            
            // Content
            Expanded(
              child: _isLoading && _posts.isEmpty
                  ? const Center(child: AppLoader())
                  : _posts.isEmpty
                      ? Center(
                          child: AppEmptyState(
                            message: FlutterI18n.translate(context, 'home.no_posts'),
                            subtitle: FlutterI18n.translate(context, 'home.no_posts_subtitle'),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => _loadData(refresh: true),
                          child: ListView.builder(
                            itemCount: _posts.length + (_hasMore ? 1 : 0),
                            controller: _scrollController,
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).padding.bottom + 100,
                            ),
                            itemBuilder: (context, index) {
                              if (index == _posts.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: AppLoader(size: 40)),
                                );
                              }

                              final post = _posts[index];
                              final postId = post.id;
                              final isLiked = _isLiked(postId);

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (index * 50)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: PostWidget(
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
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          // Animated Title
          ScaleTransition(
            scale: _titleAnimation,
            child: Text(
              'Tseretnip',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark 
                    ? AppColors.textPrimaryDark 
                    : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const Spacer(),
          // Refresh button with animation
          _AnimatedRefreshButton(
            isLoading: _isLoading,
            onTap: () => _loadData(refresh: true),
          ),
        ],
      ),
    );
  }
}

class _AnimatedRefreshButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _AnimatedRefreshButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<_AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedRefreshButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      child: RotationTransition(
        turns: _controller,
        child: AppIcon(
          name: AppIcon.reload,
          size: 24,
          color: widget.isLoading 
              ? AppColors.textTertiaryLight 
              : null,
        ),
      ),
    );
  }
}
