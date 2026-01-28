import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        _showSnackBar('You must be signed in to upload.');
        return;
      }

      int successCount = 0;

      for (var i = 0; i < _selected.length; i++) {
        final xFile = _selected[i];
        final bytes = await xFile.readAsBytes();
        final safeName = xFile.name.isNotEmpty
            ? xFile.name.replaceAll(' ', '_')
            : 'photo.jpg';
        final fileName =
            '$userId/${DateTime.now().toIso8601String()}_$safeName';

        await client.storage.from('posts').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: xFile.mimeType ?? 'image/jpeg',
          ),
        );

        final imageUrl = client.storage.from('posts').getPublicUrl(fileName);

        await client.from('posts').insert({
          'user_id': userId,
          'image': imageUrl,
          'created_at': DateTime.now().toIso8601String(),
        });

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select photos and upload them to Supabase Storage.',
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
                    label: const Text('Select photos'),
                  ),
                  FilledButton.icon(
                    onPressed: _uploading ? null : _takePhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _clearSelection,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear selection'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Selected: ${_selected.length}',
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
                  label: Text(_uploading ? 'Uploading...' : 'Upload'),
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
