import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:tseretnip/models/models.dart';
import 'package:tseretnip/post.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:tseretnip/theme/theme.dart';
import 'package:tseretnip/widgets/widgets.dart';
import '../services/core/services/supabase_repository.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final SupabaseRepository _repository = SupabaseRepository();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Account? _profile;
  List<Post> _posts = [];
  List<Post> _likedPosts = [];
  bool _isLoading = true;
  bool _isOwnProfile = false;
  bool _isEditing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _repository.currentUser;
      String targetUserId;

      if (widget.userId == null || widget.userId == currentUser?.id) {
        _isOwnProfile = true;
        _profile = await _repository.getCurrentProfile();
        targetUserId = currentUser!.id;
      } else {
        _isOwnProfile = false;
        _profile = await _repository.getProfileById(widget.userId!);
        targetUserId = widget.userId!;
      }

      if (_profile != null) {
        _usernameController.text = _profile!.username ?? '';
        _descriptionController.text = _profile!.description ?? '';
      }

      final posts = await _repository.getPostsByUserId(targetUserId);
      _likedPosts = await _repository.getLikedPosts();

      if (mounted) {
        setState(() => _posts = posts);
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${FlutterI18n.translate(context, 'profile.error_loading')}$e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isLiked(int postId) {
    return _likedPosts.any((post) => post.id == postId);
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(context, 'profile.avatar_updated'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${FlutterI18n.translate(context, 'profile.error_upload')}$e',
            ),
          ),
        );
      }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(context, 'profile.banner_updated'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${FlutterI18n.translate(context, 'profile.error_upload')}$e',
            ),
          ),
        );
      }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              FlutterI18n.translate(context, 'profile.profile_updated'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${FlutterI18n.translate(context, 'profile.error_update')}$e',
            ),
          ),
        );
      }
    }
  }

  void _showSettingsSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              FlutterI18n.translate(context, 'profile.settings'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Theme toggle
            _SettingsTile(
              icon: isDark ? AppIcon.sun : AppIcon.moon,
              title: FlutterI18n.translate(context, 'profile.theme'),
              subtitle: isDark
                  ? FlutterI18n.translate(context, 'profile.dark_mode')
                  : FlutterI18n.translate(context, 'profile.light_mode'),
              onTap: () {
                AdaptiveTheme.of(context).toggleThemeMode();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Language
            _SettingsTile(
              icon: AppIcon.info,
              title: FlutterI18n.translate(context, 'profile.language'),
              subtitle: Localizations.localeOf(context).languageCode == 'fr'
                  ? 'Français'
                  : 'English',
              onTap: () async {
                final currentLocale = Localizations.localeOf(context);
                final newLocale = currentLocale.languageCode == 'fr'
                    ? const Locale('en')
                    : const Locale('fr');
                await FlutterI18n.refresh(context, newLocale);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Logout
            _SettingsTile(
              icon: AppIcon.logout,
              title: FlutterI18n.translate(context, 'profile.logout'),
              isDestructive: true,
              onTap: () async {
                Navigator.pop(context);
                await _repository.signOut();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: AppLoader())
          : _profile == null
              ? Center(
                  child: Text(
                    FlutterI18n.translate(context, 'profile.error_loading'),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    slivers: [
                      // Banner & Avatar
                      SliverToBoxAdapter(
                        child: _buildHeader(context, isDark),
                      ),

                      // Profile Info
                      SliverToBoxAdapter(
                        child: _buildProfileInfo(context, isDark),
                      ),

                      // Posts section
                      SliverToBoxAdapter(
                        child: _buildPostsHeader(context, isDark),
                      ),

                      // Posts grid
                      _posts.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: AppEmptyState(
                                  message: FlutterI18n.translate(
                                    context,
                                    'profile.no_posts',
                                  ),
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final post = _posts[index];
                                  return PostWidget(
                                    key: ValueKey(post.id),
                                    post: post,
                                    initialIsLiked: _isLiked(post.id),
                                    repository: _repository,
                                  );
                                },
                                childCount: _posts.length,
                              ),
                            ),

                      // Bottom padding
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.bottom + 100,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner
        GestureDetector(
          onTap: _isOwnProfile && _isEditing ? _pickAndUploadBanner : null,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _profile!.banner != null && _profile!.banner!.isNotEmpty
                    ? NetworkImage(_profile!.banner!)
                    : const AssetImage('assets/images/default-banner.jpg')
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Back button (when viewing other profile)
        if (!_isOwnProfile)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  name: AppIcon.arrowLeft,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // Settings button (own profile)
        if (_isOwnProfile)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Row(
              children: [
                if (_isEditing)
                  GestureDetector(
                    onTap: _saveProfile,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const AppIcon(
                        name: AppIcon.check,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => setState(() => _isEditing = true),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const AppIcon(
                        name: AppIcon.edit,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showSettingsSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon(
                      name: AppIcon.settings,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Avatar
        Positioned(
          bottom: -50,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _isOwnProfile && _isEditing ? _pickAndUploadImage : null,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage:
                      _profile!.avatar != null && _profile!.avatar!.isNotEmpty
                          ? NetworkImage(_profile!.avatar!)
                          : const AssetImage('assets/images/default.png')
                              as ImageProvider,
                  child: _isOwnProfile && _isEditing
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: AppIcon(
                              name: AppIcon.camera,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        60,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
      ),
      child: Column(
        children: [
          // Username
          if (_isEditing && _isOwnProfile)
            TextField(
              controller: _usernameController,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: FlutterI18n.translate(context, 'profile.username_hint'),
                border: InputBorder.none,
              ),
            )
          else
            Text(
              _profile!.username ??
                  FlutterI18n.translate(context, 'profile.default_username'),
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),

          const SizedBox(height: 8),

          // Description
          if (_isEditing && _isOwnProfile)
            TextField(
              controller: _descriptionController,
              textAlign: TextAlign.center,
              maxLines: 3,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText:
                    FlutterI18n.translate(context, 'profile.description_hint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
            )
          else
            Text(
              _profile!.description ??
                  FlutterI18n.translate(context, 'profile.default_description'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

          const SizedBox(height: AppTheme.spacingMd),

          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatItem(
                  value: _posts.length.toString(),
                  label: FlutterI18n.translate(context, 'profile.posts_count'),
                ),
              ],
            ),
          ),

          // Cancel button when editing
          if (_isEditing && _isOwnProfile) ...[
            const SizedBox(height: AppTheme.spacingMd),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _usernameController.text = _profile!.username ?? '';
                  _descriptionController.text = _profile!.description ?? '';
                });
              },
              child: Text(
                FlutterI18n.translate(context, 'profile.cancel'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostsHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Row(
        children: [
          AppIcon(
            name: AppIcon.grid,
            size: 20,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 8),
          Text(
            FlutterI18n.translate(context, 'profile.my_posts'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            AppIcon(
              name: icon,
              size: 24,
              color: color,
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
