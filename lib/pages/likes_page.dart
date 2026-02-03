import 'package:flutter/material.dart';
import 'package:tseretnip/models/models.dart';
import 'package:tseretnip/post.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  final SupabaseRepository _repository = SupabaseRepository();
  bool _isLoading = false;
  List<Post> _likedPosts = [];
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

      if (mounted) {
        setState(() {
          _likedPosts = likedData;
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
          title: Text(
            FlutterI18n.translate(context, 'likes.title'),
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
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
            ? Center(
                child: Text(
                  FlutterI18n.translate(context, 'likes.no_likes'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _likedPosts.length,
                itemBuilder: (context, index) {
                  final post = _likedPosts[index];
                  final postId = post.id;

                  return PostWidget(
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
