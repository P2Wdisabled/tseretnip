import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
      
      if (widget.userId == null || widget.userId == currentUser?.id) {
        // Load current user's profile
        _isOwnProfile = true;
        _profile = await _repository.getCurrentProfile();
      } else {
        // Load another user's profile
        _isOwnProfile = false;
        _profile = await _repository.getProfileById(widget.userId!);
      }

      if (_profile != null) {
        _usernameController.text = _profile!['username'] ?? '';
        _descriptionController.text = _profile!['description'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement du profil: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      appBar: AppBar(
        title: const Text('Profil'),
        actions: _isOwnProfile
            ? [
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _saveProfile,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profil introuvable'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: _isOwnProfile && _isEditing ? _pickAndUploadImage : null,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: _profile!['avatar'] != null && _profile!['avatar'].toString().isNotEmpty
                                  ? NetworkImage(_profile!['avatar'])
                                  : const AssetImage('assets/images/default.png') as ImageProvider,
                            ),
                            if (_isOwnProfile && _isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Username
                      if (_isEditing && _isOwnProfile)
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom d\'utilisateur',
                            border: OutlineInputBorder(),
                          ),
                        )
                      else
                        Text(
                          _profile!['username'] ?? 'Utilisateur',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      const SizedBox(height: 16),
                      
                      // description
                      if (_isEditing && _isOwnProfile)
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            hintText: 'Parlez-nous de vous...',
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _profile!['description'] ?? 'Aucune description',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      const SizedBox(height: 24),
                      
                      // Cancel button when editing
                      if (_isEditing && _isOwnProfile)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _usernameController.text = _profile!['username'] ?? '';
                              _descriptionController.text = _profile!['description'] ?? '';
                            });
                          },
                          child: const Text('Annuler'),
                        ),
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
