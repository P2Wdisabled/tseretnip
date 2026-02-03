import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tseretnip/models/models.dart';
import 'package:tseretnip/post.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';
import 'package:tseretnip/theme/theme.dart';
import 'package:tseretnip/widgets/widgets.dart';

class LikesPage extends StatefulWidget {
  final Function(List<int>)? onUnlikedIdsChanged;

  const LikesPage({
    super.key,
    this.onUnlikedIdsChanged,
  });

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage>
    with SingleTickerProviderStateMixin {
  final SupabaseRepository _repository = SupabaseRepository();
  bool _isLoading = false;
  List<Post> _likedPosts = [];
  final Set<int> _unlikedIds = {};

  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    );
    _headerController.forward();
    _loadLikedPosts();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadLikedPosts() async {
    setState(() => _isLoading = true);
    try {
      final likedData = await _repository.getLikedPosts();

      if (mounted) {
        setState(() {
          _likedPosts = likedData;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading likes: $e')),
        );
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
    widget.onUnlikedIdsChanged?.call(_unlikedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: AppLoader())
                  : _likedPosts.isEmpty
                      ? Center(
                          child: AppEmptyState(
                            message: FlutterI18n.translate(
                              context,
                              'likes.no_likes',
                            ),
                            subtitle: FlutterI18n.translate(
                              context,
                              'likes.no_likes_subtitle',
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadLikedPosts,
                          child: ListView.builder(
                            padding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).padding.bottom + 100,
                            ),
                            itemCount: _likedPosts.length,
                            itemBuilder: (context, index) {
                              final post = _likedPosts[index];
                              final postId = post.id;

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(
                                  milliseconds: 300 + (index * 50),
                                ),
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
                                  initialIsLiked: true,
                                  repository: _repository,
                                  onLikeChanged: (isLiked) =>
                                      _onLikeChanged(postId, isLiked),
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

  Widget _buildHeader(BuildContext context, bool isDark) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_headerAnimation),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            Text(
              FlutterI18n.translate(context, 'likes.title'),
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 8),
            if (_likedPosts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.like.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      name: AppIcon.heartFilled,
                      size: 14,
                      color: AppColors.like,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_likedPosts.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.like,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
