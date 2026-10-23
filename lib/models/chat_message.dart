import 'package:intl/intl.dart';
import 'app_role.dart';
import 'chat_attachment.dart';

class ChatMessage {
  final String id;
  final AppRole senderRole;
  final String senderDeviceName;
  final AppRole? receiverRole;
  final String? receiverDeviceName;
  final String text;
  final ChatAttachment? attachment;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderRole,
    required this.senderDeviceName,
    this.receiverRole,
    this.receiverDeviceName,
    required this.text,
    this.attachment,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedTime {
    return DateFormat('hh:mm:ss a').format(timestamp);
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }

  bool get hasAttachment => attachment != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderRole': senderRole.code,
      'senderDeviceName': senderDeviceName,
      'receiverRole': receiverRole?.code,
      'receiverDeviceName': receiverDeviceName,
      'text': text,
      'attachment': attachment?.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderRole: AppRole.fromString(json['senderRole'] as String?),
      senderDeviceName: json['senderDeviceName'] as String? ?? 'Dispositivo',
      receiverRole: json['receiverRole'] != null
          ? AppRole.fromString(json['receiverRole'] as String)
          : null,
      receiverDeviceName: json['receiverDeviceName'] as String?,
      text: json['text'] as String? ?? '',
      attachment: json['attachment'] != null
          ? ChatAttachment.fromJson(json['attachment'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
