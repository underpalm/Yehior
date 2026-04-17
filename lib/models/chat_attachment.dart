import 'dart:typed_data';

enum AttachmentType { image, document }

class ChatAttachment {
  final AttachmentType type;
  final String fileName;
  final Uint8List bytes;
  final String? mimeType;

  /// For images: base64-encoded data
  /// For documents: extracted text content
  final String processedContent;

  ChatAttachment({
    required this.type,
    required this.fileName,
    required this.bytes,
    required this.processedContent,
    this.mimeType,
  });

  bool get isImage => type == AttachmentType.image;
}
