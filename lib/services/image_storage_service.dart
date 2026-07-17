import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../platform/file_storage.dart';
import '../theme/layout_constants.dart';
import '../widgets/image_crop_page.dart';

class ImageStorageService {
  ImageStorageService._();

  static final ImageStorageService instance = ImageStorageService._();

  final ImagePicker _picker = ImagePicker();

  static const double cardAspectRatio = kCardPhotoWidth / kCardPhotoHeight;

  @visibleForTesting
  String? testImagePath;

  @visibleForTesting
  bool useTestImage = false;

  Future<String?> pickAndSaveImage(BuildContext context) async {
    if (useTestImage) {
      return testImagePath;
    }

    final source = await _pickImageSource(context);
    if (source == null) {
      return null;
    }

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (pickedFile == null) {
      return null;
    }

    final imageBytes = await pickedFile.readAsBytes();
    if (!context.mounted) {
      return null;
    }

    final cropResult = await showImageCropPage(
      context,
      imageBytes: imageBytes,
    );
    if (cropResult == null) {
      return null;
    }

    return saveImageBytes(
      cropResult.bytes,
      extension: _extensionFromPath(pickedFile.path),
    );
  }

  Future<void> deleteImageIfExists(String? path) async {
    if (path == null || kIsWeb) {
      return;
    }

    await deleteFileIfExists(path);
  }

  Future<ImageSource?> _pickImageSource(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  String _extensionFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (extension == 'png') {
      return 'png';
    }
    return 'jpg';
  }
}
