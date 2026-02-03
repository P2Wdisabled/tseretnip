import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';
import 'package:tseretnip/theme/theme.dart';
import 'package:tseretnip/widgets/widgets.dart';

class UploadPhotosPage extends StatefulWidget {
  const UploadPhotosPage({super.key});

  @override
  State<UploadPhotosPage> createState() => _UploadPhotosPageState();
}

class _UploadPhotosPageState extends State<UploadPhotosPage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selected = <XFile>[];
  final int _maxPhotos = 10;

  bool _uploading = false;
  bool _showSuccess = false;

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
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (!mounted || images.isEmpty) return;

    setState(() {
      final remaining = _maxPhotos - _selected.length;
      _selected.addAll(images.take(remaining));
    });
  }

  Future<void> _takePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!mounted || image == null) return;

    if (_selected.length < _maxPhotos) {
      setState(() => _selected.add(image));
    }
  }

  void _removePhoto(int index) {
    setState(() => _selected.removeAt(index));
  }

  Future<void> _uploadImages() async {
    if (_selected.isEmpty) {
      _showSnackBar(FlutterI18n.translate(context, 'upload.select_warning'));
      return;
    }

    setState(() => _uploading = true);

    try {
      final repository = SupabaseRepository();
      final userId = repository.currentUser?.id;
      if (userId == null) {
        _showSnackBar(FlutterI18n.translate(context, 'upload.signin_warning'));
        return;
      }

      int successCount = 0;
      for (var file in _selected) {
        await repository.publishPhoto(imageFile: File(file.path));
        successCount++;
      }

      if (!mounted) return;

      setState(() {
        _uploading = false;
        _showSuccess = true;
      });

      // Show success animation then clear
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        setState(() {
          _showSuccess = false;
          _selected.clear();
        });

        _showSnackBar(
          FlutterI18n.translate(
            context,
            'upload.success_message',
            translationParams: {'count': successCount.toString()},
          ),
        );
      }
    } catch (error) {
      _showSnackBar(
        '${FlutterI18n.translate(context, 'upload.failure_message')}$error',
      );
      setState(() => _uploading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                _buildHeader(context, isDark),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: AppTheme.spacingMd,
                      right: AppTheme.spacingMd,
                      bottom: MediaQuery.of(context).padding.bottom + 120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview area
                        _buildPreviewArea(context, isDark),

                        const SizedBox(height: AppTheme.spacingLg),

                        // Selected photos carousel
                        if (_selected.isNotEmpty) ...[
                          _buildPhotosCarousel(context, isDark),
                          const SizedBox(height: AppTheme.spacingLg),
                        ],

                        // Action buttons
                        _buildActionButtons(context, isDark),

                        const SizedBox(height: AppTheme.spacingLg),

                        // Upload button
                        _buildUploadButton(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Success overlay
            if (_showSuccess)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Lottie.asset(
                        'assets/animations/success.json',
                        width: 150,
                        height: 150,
                        repeat: false,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        FlutterI18n.translate(context, 'upload.upload_complete'),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
        child: Column(
          children: [
            Text(
              FlutterI18n.translate(context, 'upload.title'),
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              FlutterI18n.translate(context, 'upload.select_button'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea(BuildContext context, bool isDark) {
    return AnimatedContainer(
      duration: AppTheme.animationNormal,
      height: 200,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.cardGradientDark
            : AppColors.cardGradientLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          width: 2,
        ),
      ),
      child: _selected.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    name: AppIcon.image,
                    size: 48,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    FlutterI18n.translate(context, 'upload.no_photos'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 2),
              child: PageView.builder(
                itemCount: _selected.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<Uint8List>(
                    future: _selected[index].readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: AppLoader(size: 30));
                      }
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildPhotosCarousel(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              FlutterI18n.translate(context, 'upload.selected_photos'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                '${_selected.length} / $_maxPhotos',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selected.length + (_selected.length < _maxPhotos ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _selected.length) {
                // Add more button
                return GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Center(
                      child: AppIcon(
                        name: AppIcon.plus,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }

              return _PhotoThumbnail(
                file: _selected[index],
                onRemove: () => _removePhoto(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isDark) {
    return Column(
      children: [
        AppOptionButton(
          title: FlutterI18n.translate(context, 'upload.select_photos_title'),
          subtitle: FlutterI18n.translate(context, 'upload.select_photos_subtitle'),
          icon: AppIcon(
            name: AppIcon.image,
            color: AppColors.primary,
          ),
          onTap: _uploading ? () {} : _pickImages,
        ),
        const SizedBox(height: 12),
        AppOptionButton(
          title: FlutterI18n.translate(context, 'upload.take_photo_title'),
          subtitle: FlutterI18n.translate(context, 'upload.take_photo_subtitle'),
          icon: AppIcon(
            name: AppIcon.camera,
            color: AppColors.primary,
          ),
          onTap: _uploading ? () {} : _takePhoto,
        ),
      ],
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: AppTheme.animationNormal,
        width: double.infinity,
        child: AppGradientButton(
          text: _uploading
              ? FlutterI18n.translate(context, 'upload.uploading_button')
              : '${FlutterI18n.translate(context, 'upload.validate_button')} (${_selected.length})',
          onPressed: _selected.isEmpty || _uploading ? null : _uploadImages,
          isLoading: _uploading,
          icon: _uploading
              ? null
              : const AppIcon(
                  name: AppIcon.upload,
                  size: 20,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _PhotoThumbnail({
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    color: AppColors.surfaceLight,
                    child: const Center(child: AppLoader(size: 20)),
                  );
                }
                return Image.memory(
                  snapshot.data!,
                  width: 80,
                  height: 100,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  name: AppIcon.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
