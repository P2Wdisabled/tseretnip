import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tseretnip/post.dart';
import '../services/core/services/supabase_repository.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // If null, show current user's profile

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseRepository _repository = SupabaseRepository();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _likedPosts = [];
  bool _isLoading = true;
  bool _isOwnProfile = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUser = _repository.currentUser;
      String targetUserId;
      
      if (widget.userId == null || widget.userId == currentUser?.id) {
        // Load current user's profile
        _isOwnProfile = true;
        _profile = await _repository.getCurrentProfile();
        targetUserId = currentUser!.id;
      } else {
        // Load another user's profile
        _isOwnProfile = false;
        _profile = await _repository.getProfileById(widget.userId!);
        targetUserId = widget.userId!;
      }

      if (_profile != null) {
        _usernameController.text = _profile!['username'] ?? '';
        _descriptionController.text = _profile!['description'] ?? '';
      }
      
      // Load user's posts
      final posts = await _repository.getPostsByUserId(targetUserId);
      
      // Load liked posts for current user to check like status
      if (_isOwnProfile) {
        _likedPosts = await _repository.getLikedPosts();
      } else {
        _likedPosts = await _repository.getLikedPosts();
      }
      
      if (mounted) {
        setState(() {
          _posts = posts;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement du profil: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isLiked(int postId) {
    return _likedPosts.any((element) => element['post_id'] == postId);
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    try {
      final File imageFile = File(image.path);
      final String imageUrl = await _repository.uploadProfilePicture(imageFile);
      
      await _repository.updateProfile(avatarUrl: imageUrl);
      
      await _loadProfile();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'upload: $e')),
      );
    }
  }

  Future<void> _pickAndUploadBanner() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    try {
      final File imageFile = File(image.path);
      final String imageUrl = await _repository.uploadBanner(imageFile);
      
      await _repository.updateProfile(bannerUrl: imageUrl);
      
      await _loadProfile();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bannière mise à jour!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'upload: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    try {
      await _repository.updateProfile(
        username: _usernameController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      
      setState(() => _isEditing = false);
      await _loadProfile();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: _isOwnProfile
            ? [
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: _saveProfile,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () async {
                    await _repository.signOut();
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ]
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profil introuvable'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Banner
                      GestureDetector(
                        onTap: _isOwnProfile && _isEditing ? _pickAndUploadBanner : null,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: _profile!['banner'] != null && _profile!['banner'].toString().isNotEmpty
                                      ? NetworkImage(_profile!['banner'])
                                      : const AssetImage('assets/images/default-banner.jpg') as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (_isOwnProfile && _isEditing)
                              Positioned(
                                top: 90,
                                right: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Avatar (overlapping banner)
                      Transform.translate(
                        offset: const Offset(0, -60),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _isOwnProfile && _isEditing ? _pickAndUploadImage : null,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 70,
                                      backgroundImage: _profile!['avatar'] != null && _profile!['avatar'].toString().isNotEmpty
                                          ? NetworkImage(_profile!['avatar'])
                                          : const AssetImage('assets/images/default.png') as ImageProvider,
                                    ),
                                  ),
                                  if (_isOwnProfile && _isEditing)
                                    Positioned(
                                      bottom: 5,
                                      right: 5,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Username
                            if (_isEditing && _isOwnProfile)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                child: TextField(
                                  controller: _usernameController,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    border: UnderlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                ),
                              )
                            else
                              Text(
                                _profile!['username'] ?? 'Utilisateur',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            const SizedBox(height: 12),
                            
                            // Description
                            if (_isEditing && _isOwnProfile)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                child: TextField(
                                  controller: _descriptionController,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.5,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Parlez-nous de vous...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(12)),
                                    ),
                                    contentPadding: EdgeInsets.all(16),
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                child: Text(
                                  _profile!['description'] ?? 'Aucune description',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    height: 1.6,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            
                            // Cancel button when editing
                            if (_isEditing && _isOwnProfile)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      _usernameController.text = _profile!['username'] ?? '';
                                      _descriptionController.text = _profile!['description'] ?? '';
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    side: const BorderSide(color: Colors.black26),
                                  ),
                                  child: Text(
                                    'Annuler',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Posts section
                      if (_posts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Text(
                                'Posts',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_posts.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._posts.map((post) {
                          final postId = post['id'] as int;
                          return Post(
                            key: ValueKey(postId),
                            post: post,
                            initialIsLiked: _isLiked(postId),
                            repository: _repository,
                          );
                        }),
                        const SizedBox(height: 24),
                      ] else if (!_isLoading) ...[
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Aucun post',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
