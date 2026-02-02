import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tseretnip/services/core/services/supabase_repository.dart';

class UploadPhotosPage extends StatefulWidget {
  const UploadPhotosPage({super.key});

  @override
  State<UploadPhotosPage> createState() => _UploadPhotosPageState();
}

class _UploadPhotosPageState extends State<UploadPhotosPage> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selected = <XFile>[];

  bool _uploading = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (!mounted) {
      return;
    }
    if (images.isEmpty) {
      return;
    }
    setState(() {
      _selected
        ..clear()
        ..addAll(images);
    });
  }

  void _clearSelection() {
    setState(() {
      _selected.clear();
    });
  }

  Future<void> _uploadImages() async {
    if (_selected.isEmpty) {
      _showSnackBar(FlutterI18n.translate(context, 'upload.select_warning'));
      return;
    }

    setState(() {
      _uploading = true;
    });

    try {
      final repository = SupabaseRepository();
      if (repository.currentUser == null) {
        _showSnackBar(FlutterI18n.translate(context, 'upload.signin_warning'));
        return;
      }

      int successCount = 0;

      for (var i = 0; i < _selected.length; i++) {
        final xFile = _selected[i];
        final file = File(xFile.path);

        await repository.publishPhoto(imageFile: file);
        successCount++;
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        FlutterI18n.translate(
          context,
          'upload.success_message',
          translationParams: {'count': successCount.toString()},
        ),
      );

      // Clear selection after successful upload
      _clearSelection();
    } catch (error) {
      _showSnackBar(
        '${FlutterI18n.translate(context, 'upload.failure_message')}$error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'upload.title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                FlutterI18n.translate(context, 'upload.description'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _uploading ? null : _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      FlutterI18n.translate(context, 'upload.select_button'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _clearSelection,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                      FlutterI18n.translate(context, 'upload.clear_button'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${FlutterI18n.translate(context, 'upload.selected_count')}${_selected.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              if (_selected.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selected.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final file = _selected[index];
                    return _PhotoPreviewCard(file: file);
                  },
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _uploading ? null : _uploadImages,
                  icon: _uploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _uploading
                        ? FlutterI18n.translate(
                            context,
                            'upload.uploading_button',
                          )
                        : FlutterI18n.translate(
                            context,
                            'upload.upload_button',
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPreviewCard extends StatelessWidget {
  const _PhotoPreviewCard({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<Uint8List>(
                future: file.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 72,
                      height: 72,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox(
                      width: 72,
                      height: 72,
                      child: Icon(Icons.broken_image_outlined),
                    );
                  }
                  return Image.memory(
                    snapshot.data!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file.mimeType ?? 'image',
                    style: Theme.of(context).textTheme.bodySmall,
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
