import 'package:flutter/material.dart';

class ChatAttachment {
  final String id;
  final String fileName;
  final String fileExtension;
  final int fileSizeBytes;
  final String mimeType;
  final String? base64Data;
  final bool isImage;

  const ChatAttachment({
    required this.id,
    required this.fileName,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.mimeType,
    this.base64Data,
    this.isImage = false,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  IconData get icon {
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) {
      return Icons.image_rounded;
    } else if (['pdf'].contains(ext)) {
      return Icons.picture_as_pdf_rounded;
    } else if (['log', 'txt'].contains(ext)) {
      return Icons.description_rounded;
    } else if (['zip', 'rar', '7z'].contains(ext)) {
      return Icons.folder_zip_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color get iconColor {
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    if (['png', 'jpg', 'jpeg', 'webp', 'gif'].contains(ext)) {
      return const Color(0xFF38BDF8);
    } else if (['pdf'].contains(ext)) {
      return const Color(0xFFF43F5E);
    } else if (['log', 'txt'].contains(ext)) {
      return const Color(0xFFFBBF24);
    }
    return const Color(0xFFA855F7);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'base64Data': base64Data,
      'isImage': isImage,
    };
  }

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileExtension: json['fileExtension'] as String? ?? '',
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      base64Data: json['base64Data'] as String?,
      isImage: json['isImage'] as bool? ?? false,
    );
  }

  // Predefined fast testing samples
  static List<ChatAttachment> get testSamples => [
    const ChatAttachment(
      id: 'att-01',
      fileName: 'captura_error_servidor_r740.png',
      fileExtension: 'png',
      fileSizeBytes: 348160,
      mimeType: 'image/png',
      isImage: true,
    ),
    const ChatAttachment(
      id: 'att-02',
      fileName: 'solicitud_acceso_nomina_firmada.pdf',
      fileExtension: 'pdf',
      fileSizeBytes: 1048576,
      mimeType: 'application/pdf',
      isImage: false,
    ),
    const ChatAttachment(
      id: 'att-03',
      fileName: 'diagnostico_red_vpn_fortinet.log',
      fileExtension: 'log',
      fileSizeBytes: 98304,
      mimeType: 'text/plain',
      isImage: false,
    ),
  ];
}
