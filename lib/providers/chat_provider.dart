import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_role.dart';
import '../models/chat_attachment.dart';
import '../models/chat_message.dart';
import '../services/mock_data.dart';
import '../services/persistence_service.dart';
import '../services/render_service.dart';
import '../services/sync_service.dart';

class SendMessageResult {
  final bool success;
  final String message;
  final ChatMessage? createdMessage;

  SendMessageResult({
    required this.success,
    required this.message,
    this.createdMessage,
  });
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _lastSentNotification;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get lastSentNotification => _lastSentNotification;

  ChatProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Load local persistence
    final loaded = await PersistenceService.loadMessages();
    if (loaded.isEmpty) {
      _messages.addAll(MockData.getInitialMessages());
      await PersistenceService.saveMessages(_messages);
    } else {
      _messages.addAll(loaded);
    }

    _isLoading = false;
    notifyListeners();

    // 2. Try fetching from Render backend
    try {
      final remoteMessages = await RenderService.fetchMessages();
      if (remoteMessages.isNotEmpty) {
        _messages.clear();
        _messages.addAll(remoteMessages);
        await PersistenceService.saveMessages(_messages);
        notifyListeners();
      }
    } catch (_) {}

    // 3. Listen to local sync events
    SyncService.stream.listen((event) async {
      if (event.type == SyncEventType.newMessage ||
          event.type == SyncEventType.clearHistory ||
          event.type == SyncEventType.forceReload) {
        await reloadMessages();
      }
    });

    // 4. Listen to real-time Render WebSocket events
    RenderService.events.listen((event) async {
      final type = event['type'];
      final payload = event['payload'];

      if (type == 'new_message' && payload != null) {
        try {
          final msg = ChatMessage.fromJson(payload as Map<String, dynamic>);
          if (!_messages.any((m) => m.id == msg.id)) {
            _messages.add(msg);
            await PersistenceService.saveMessages(_messages);
            notifyListeners();
          }
        } catch (_) {}
      } else if (type == 'clear_history') {
        _messages.clear();
        await PersistenceService.saveMessages(_messages);
        notifyListeners();
      } else if (type == 'initial_state' && payload != null) {
        try {
          final list = payload['messages'] as List<dynamic>?;
          if (list != null && list.isNotEmpty) {
            _messages.clear();
            _messages.addAll(list.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)));
            await PersistenceService.saveMessages(_messages);
            notifyListeners();
          }
        } catch (_) {}
      }
    });
  }

  Future<void> reloadMessages() async {
    final loaded = await PersistenceService.loadMessages();
    _messages.clear();
    _messages.addAll(loaded);
    notifyListeners();
  }

  List<ChatMessage> getConversationBetween(AppRole deviceA, AppRole deviceB) {
    return _messages.where((m) {
      final isBetween = (m.senderRole == deviceA && m.receiverRole == deviceB) ||
          (m.senderRole == deviceB && m.receiverRole == deviceA);
      final isBroadcast = m.receiverRole == null;
      return isBetween || isBroadcast;
    }).toList();
  }

  int getMessageCountFor(AppRole role) {
    return _messages.where((m) => m.senderRole == role).length;
  }

  Map<AppRole, int> get allDeviceCounters {
    final map = <AppRole, int>{};
    for (final role in AppRole.values) {
      map[role] = getMessageCountFor(role);
    }
    return map;
  }

  int get totalMessagesCount => _messages.length;

  Future<SendMessageResult> sendMessage({
    required AppRole senderRole,
    required AppRole receiverRole,
    required String text,
    ChatAttachment? attachment,
    bool isOfflineSimulated = false,
  }) async {
    final trimmed = text.trim();

    if (trimmed.isEmpty && attachment == null) {
      return SendMessageResult(
        success: false,
        message: 'No se puede enviar un mensaje vacío. Escriba un texto o adjunte un archivo.',
      );
    }

    if (isOfflineSimulated) {
      return SendMessageResult(
        success: false,
        message: 'Error de red: No se pudo enviar el mensaje debido a pérdida de conexión (TC07).',
      );
    }

    final newMsg = ChatMessage(
      id: const Uuid().v4(),
      senderRole: senderRole,
      senderDeviceName: senderRole.deviceName,
      receiverRole: receiverRole,
      receiverDeviceName: receiverRole.deviceName,
      text: trimmed,
      attachment: attachment,
      timestamp: DateTime.now(),
    );

    _messages.add(newMsg);
    await PersistenceService.saveMessages(_messages);

    _lastSentNotification =
        'Mensaje enviado con éxito a ${receiverRole.shortDeviceName} a las ${newMsg.formattedTime}';

    // Broadcast locally and to Render
    await SyncService.broadcast(
      SyncEventType.newMessage,
      sender: senderRole.code,
      payload: newMsg.id,
    );

    // Send to Render backend (WebSocket + REST)
    RenderService.sendWsMessage('send_message', {'message': newMsg.toJson()});
    RenderService.postMessage(newMsg);

    notifyListeners();

    return SendMessageResult(
      success: true,
      message: _lastSentNotification!,
      createdMessage: newMsg,
    );
  }

  Future<void> clearHistory() async {
    _messages.clear();
    await PersistenceService.saveMessages(_messages);
    _lastSentNotification = 'Historial de mensajes vaciado correctamente.';

    await SyncService.broadcast(
      SyncEventType.clearHistory,
      sender: 'system',
    );

    RenderService.clearMessagesOnServer();

    notifyListeners();
  }

  Future<void> resetToMock() async {
    _messages.clear();
    _messages.addAll(MockData.getInitialMessages());
    await PersistenceService.saveMessages(_messages);
    notifyListeners();
  }

  void dismissNotification() {
    _lastSentNotification = null;
    notifyListeners();
  }
}
