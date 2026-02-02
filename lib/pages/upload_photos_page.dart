import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<void> _takePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!mounted) {
      return;
    }
    if (image == null) {
      return;
    }
    setState(() {
      _selected
        ..clear()
        ..add(image);
    });
  }

  void _clearSelection() {
    setState(() {
      _selected.clear();
    });
  }

  Future<void> _uploadImages() async {
    if (_selected.isEmpty) {
      _showSnackBar('Select at least one photo.');
      return;
    }

    setState(() {
      _uploading = true;
    });

    try {
      final repository = SupabaseRepository();
      final userId = repository.currentUser?.id;
      if (userId == null) {
        _showSnackBar('You must be signed in to upload.');
        return;
      }

      int successCount = 0;

      for (var i = 0; i < _selected.length; i++) {
        final file = _selected[i];

        await repository.publishPhoto(imageFile: File(file.path));

        successCount++;
      }

      if (!mounted) {
        return;
      }

      _showSnackBar('Uploaded $successCount photo(s).');

      // Clear selection after successful upload
      _clearSelection();
    } catch (error) {
      _showSnackBar('Upload failed: $error');
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
      appBar: AppBar(title: const Text('Upload Photos')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Select photos to upload.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 12),
              if (_selected.isEmpty)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_outlined),
                          SizedBox(height: 8),
                          Text('No photos selected'),
                        ],
                      ),
                    ),
                  ),
                )
              else
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
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: const Color(0xFFF5E6D3),
                      ),
                      onPressed: _uploading ? null : _pickImages,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Select photos',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: const Color(0xFFF5E6D3),
                      ),
                      onPressed: _uploading ? null : _takePhoto,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.photo_camera_outlined,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Take photo',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.black26),
                        backgroundColor: const Color(0xFFF5E6D3),
                      ),
                      onPressed: _uploading ? null : _clearSelection,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Clear selection',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: FilledButton.icon(
                    onPressed: _uploading ? null : _uploadImages,
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: const Color(0xFFF5E6D3),
                    ),
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black87,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.cloud_upload_outlined,
                            color: Colors.black87,
                          ),
                    label: Text(_uploading ? 'Uploading...' : 'Upload'),
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
