import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncEventType {
  newMessage,
  clearHistory,
  ticketCreated,
  ticketUpdated,
  ticketDeleted,
  agentStatusChanged,
  matrixUpdated,
  forceReload,
}

class SyncEvent {
  final SyncEventType type;
  final String sender;
  final String? payload;
  final int timestamp;

  SyncEvent({
    required this.type,
    required this.sender,
    this.payload,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sender': sender,
        'payload': payload,
        'timestamp': timestamp,
      };
}

class SyncService {
  static const String _keyLastSync = 'practica7_sync_version';
  static final StreamController<SyncEvent> _eventStream = StreamController<SyncEvent>.broadcast();
  static Timer? _pollTimer;
  static int _lastSeenTimestamp = 0;
  static bool _isPolling = false;

  static Stream<SyncEvent> get stream => _eventStream.stream;

  static void startPolling({VoidCallback? onExternalChange}) {
    if (_isPolling) return;
    _isPolling = true;
    _lastSeenTimestamp = DateTime.now().millisecondsSinceEpoch;

    _pollTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final serverVersion = prefs.getInt(_keyLastSync) ?? 0;
        if (serverVersion > _lastSeenTimestamp) {
          _lastSeenTimestamp = serverVersion;
          if (onExternalChange != null) {
            onExternalChange();
          }
          _eventStream.add(SyncEvent(
            type: SyncEventType.forceReload,
            sender: 'remote_tab',
            timestamp: serverVersion,
          ));
        }
      } catch (e) {
        debugPrint('Sync polling check error: $e');
      }
    });
  }

  static Future<void> broadcast(SyncEventType type, {required String sender, String? payload}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastSeenTimestamp = now;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastSync, now);
    } catch (e) {
      debugPrint('Sync broadcast write error: $e');
    }

    _eventStream.add(SyncEvent(
      type: type,
      sender: sender,
      payload: payload,
      timestamp: now,
    ));
  }

  static void dispose() {
    _pollTimer?.cancel();
    _isPolling = false;
  }
}
