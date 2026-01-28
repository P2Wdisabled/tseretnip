import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tseretnip/pages/profile.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';

class Post extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool initialIsLiked;
  final SupabaseRepository repository;
  final Function(bool isLiked)? onLikeChanged;

  const Post({
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
    
    // Author info from joined accounts table
    final author = post['accounts'] as Map<String, dynamic>?;
    final authorId = post['user_id'] as String?;
    final authorName = author?['username'] ?? 'Utilisateur';
    final authorAvatar = author?['avatar'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3), // Beige/cream color like Dribbble
        borderRadius: BorderRadius.circular(24),
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
          ),
          
          // Post image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Stack(
              children: [
                if (base64Image != null)
                  Image.memory(
                    base64Decode(
                      base64Image.contains(',')
                          ? base64Image.split(',').last
                          : base64Image,
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
                    initialCount: _getLikeCount(post),
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

class _AuthorHeader extends StatelessWidget {
  final String? authorId;
  final String authorName;
  final String? authorAvatar;

  const _AuthorHeader({
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (authorId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(userId: authorId),
            ),
          );
        }
      },
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
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
                backgroundColor: Colors.grey[300],
                backgroundImage: authorAvatar != null && authorAvatar!.isNotEmpty
                    ? NetworkImage(authorAvatar!)
                    : const AssetImage('assets/images/default.png') as ImageProvider,
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
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '@${authorName.toLowerCase().replaceAll(' ', '')}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black45,
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

class _LikeBarState extends State<_LikeBar> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likeCount = widget.initialCount;
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
      }
    });

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
        });
        widget.onLikeChanged?.call(_isLiked);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
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
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.black54,
                  size: 24,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatCount(_likeCount),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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
