import 'dart:convert';
import 'dart:typed_data';

class PartnerApplicationImage {
  const PartnerApplicationImage({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;

  String get dataUrl => 'data:$contentType;base64,${base64Encode(bytes)}';

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'contentType': contentType,
      'dataUrl': dataUrl,
    };
  }
}
