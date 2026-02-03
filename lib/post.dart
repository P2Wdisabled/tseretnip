import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:tseretnip/models/models.dart';
import 'package:tseretnip/pages/profile.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tseretnip/theme/theme.dart';
import 'package:tseretnip/widgets/widgets.dart';

class PostWidget extends StatelessWidget {
  final Post post;
  final bool initialIsLiked;
  final SupabaseRepository repository;
  final Function(bool isLiked)? onLikeChanged;
  final VoidCallback? onDeleted;

  const PostWidget({
    super.key,
    required this.post,
    required this.initialIsLiked,
    required this.repository,
    this.onLikeChanged,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final imageSource = post.image;
    final postId = post.id;

    final author = post.author;
    final authorId = post.userId;
    final authorName = author?.username ?? 'Utilisateur';
    final authorAvatar = author?.avatar;
    final canDelete =
        authorId != null && repository.currentUser?.id == authorId;

    Future<void> handleDelete() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      try {
        await repository.deletePhoto(postId);
        onDeleted?.call();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted')));
      } catch (e) {
        print('❌ Error deleting post: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author header
          _AuthorHeader(
            authorId: authorId,
            authorName: authorName,
            authorAvatar: authorAvatar,
            showDelete: canDelete,
            onDelete: handleDelete,
          ),

          // Post image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppTheme.radiusLarge),
              bottomRight: Radius.circular(AppTheme.radiusLarge),
            ),
            child: Stack(
              children: [
                if (imageSource != null)
                  if (imageSource.startsWith('http'))
                    CachedNetworkImage(
                      imageUrl: imageSource,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                    )
                  else
                    Image.memory(
                      base64Decode(
                        imageSource.contains(',')
                            ? imageSource.split(',').last
                            : imageSource,
                      ),
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 350,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.error, size: 48)),
                      ),
                    )
                else
                  Container(
                    height: 350,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48),
                    ),
                  ),

                // Like button overlay at bottom
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _LikeBar(
                    postId: postId,
                    initialCount: post.likeCount,
                    initialIsLiked: initialIsLiked,
                    repository: repository,
                    onLikeChanged: onLikeChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorHeader extends StatelessWidget {
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final bool showDelete;
  final VoidCallback? onDelete;

  const _AuthorHeader({
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.showDelete = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: authorId),
          ),
        );
      },
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppTheme.radiusLarge),
        topRight: Radius.circular(AppTheme.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey[300],
                backgroundImage:
                    authorAvatar != null && authorAvatar!.isNotEmpty
                    ? NetworkImage(authorAvatar!)
                    : const AssetImage('assets/images/default.png')
                          as ImageProvider,
              ),
            ),
            const SizedBox(width: 12),

            // Author info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (showDelete)
              AnimatedIconButton(
                iconName: AppIcon.trash,
                onTap: onDelete ?? () {},
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
          ],
        ),
      ),
    );
  }
}

class _LikeBar extends StatefulWidget {
  final int postId;
  final int initialCount;
  final bool initialIsLiked;
  final SupabaseRepository repository;
  final Function(bool isLiked)? onLikeChanged;

  const _LikeBar({
    required this.postId,
    required this.initialCount,
    required this.initialIsLiked,
    required this.repository,
    this.onLikeChanged,
  });

  @override
  State<_LikeBar> createState() => _LikeBarState();
}

class _LikeBarState extends State<_LikeBar> with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likeCount;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showLottie = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likeCount = widget.initialCount;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _LikeBar oldWidget) {
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
        _showLottie = true;
      }
    });

    // Play animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Hide lottie after animation
    if (_isLiked) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showLottie = false);
      });
    }

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
        setState(() {
          _isLiked = previousLikedState;
          _likeCount = previousCount;
          _showLottie = false;
        });
        widget.onLikeChanged?.call(_isLiked);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: AppIcon(
                        name: _isLiked ? AppIcon.heartFilled : AppIcon.heart,
                        size: 24,
                        color: _isLiked ? AppColors.like : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                    if (_showLottie)
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Lottie.asset(
                          'assets/animations/heart_like.json',
                          repeat: false,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Text(
                    _formatCount(_likeCount),
                    key: ValueKey<int>(_likeCount),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
