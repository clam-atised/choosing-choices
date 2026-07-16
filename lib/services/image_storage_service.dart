import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../platform/file_storage.dart';
import '../theme/layout_constants.dart';

class ImageStorageService {
  ImageStorageService._();

  static final ImageStorageService instance = ImageStorageService._();

  final ImagePicker _picker = ImagePicker();

  static const CropAspectRatio cardAspectRatio = CropAspectRatio(
    ratioX: 3,
    ratioY: 4,
  );

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

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: cardAspectRatio,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop photo',
          lockAspectRatio: true,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: 'Crop photo',
          aspectRatioLockEnabled: true,
        ),
        if (context.mounted) _buildWebCropUiSettings(context),
      ],
    );

    if (croppedFile == null) {
      return null;
    }

    if (kIsWeb) {
      return croppedFile.path;
    }

    return _saveToAppDirectory(croppedFile.path);
  }

  Future<void> deleteImageIfExists(String? path) async {
    if (path == null || kIsWeb) {
      return;
    }

    await deleteFileIfExists(path);
  }

  WebUiSettings _buildWebCropUiSettings(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    const dialogChromeHeight = 220.0;
    const pageChromeHeight = 184.0;
    const horizontalInset = 48.0;

    final usePageStyle =
        !isPhoneSize(context) || mediaSize.height < 680;

    final chromeHeight =
        usePageStyle ? pageChromeHeight : dialogChromeHeight;
    final cropperHeight = (mediaSize.height - chromeHeight)
        .clamp(280, 900)
        .toInt();
    final cropperWidth = (mediaSize.width - horizontalInset)
        .clamp(280, 900)
        .toInt();

    return WebUiSettings(
      context: context,
      initialAspectRatio: 3 / 4,
      presentStyle:
          usePageStyle ? WebPresentStyle.page : WebPresentStyle.dialog,
      viewwMode: WebViewMode.mode_3,
      guides: true,
      cropBoxMovable: true,
      cropBoxResizable: true,
      highlight: true,
      modal: true,
      size: CropperSize(
        width: cropperWidth,
        height: cropperHeight,
      ),
    );
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

  Future<String> _saveToAppDirectory(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDirPath = '${directory.path}/card_images';
    await ensureDirectory(imagesDirPath);

    final extension = sourcePath.split('.').last;
    final destinationPath =
        '$imagesDirPath/card_${DateTime.now().microsecondsSinceEpoch}.$extension';
    await copyFile(sourcePath, destinationPath);
    return destinationPath;
  }
}
