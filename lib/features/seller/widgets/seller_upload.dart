import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// A picked file ready to be uploaded: raw bytes plus metadata.
class PickedUpload {
  const PickedUpload({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

/// Helpers for picking images and documents for the seller suite.
class SellerUploadPicker {
  const SellerUploadPicker._();

  static final ImagePicker _imagePicker = ImagePicker();

  /// Picks a single image from the gallery. Returns `null` if cancelled.
  static Future<PickedUpload?> pickGalleryImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    return PickedUpload(
      bytes: bytes,
      fileName: _safeName(picked.name, fallback: 'photo.jpg'),
      contentType: _contentTypeFor(picked.name),
    );
  }

  /// Picks a document (image or PDF) for KYC uploads.
  static Future<PickedUpload?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;
    return PickedUpload(
      bytes: bytes,
      fileName: _safeName(file.name, fallback: 'document'),
      contentType: _contentTypeFor(file.name),
    );
  }

  static String _safeName(String name, {required String fallback}) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
