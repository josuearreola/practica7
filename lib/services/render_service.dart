import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message.dart';
import '../models/incident_report.dart';
import '../models/test_case.dart';

import 'package:uuid/uuid.dart';

enum RenderConnectionState {
  connected,
  connecting,
  disconnected,
}

class RenderService {
  static const String _keyRenderUrl = 'practica7_render_server_url';
  static const String _keyClientId = 'practica7_client_device_id';
  static String _serverUrl = 'https://practica7-9s0h.onrender.com';
  static String _clientId = '';

  static WebSocketChannel? _channel;
  static RenderConnectionState _connectionState = RenderConnectionState.disconnected;
  static Timer? _reconnectTimer;
  static Timer? _keepAliveTimer;
  static bool _isConnecting = false;

  static final StreamController<Map<String, dynamic>> _wsEventStream =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get events => _wsEventStream.stream;
  static RenderConnectionState get connectionState => _connectionState;
  static String get serverUrl => _serverUrl;
  static String get clientId => _clientId;

  static Future<void> init([String? preferredRole]) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_keyRenderUrl);

    var savedClientId = prefs.getString(_keyClientId);
    if (savedClientId == null || savedClientId.isEmpty) {
      savedClientId = const Uuid().v4();
      await prefs.setString(_keyClientId, savedClientId);
    }
    _clientId = savedClientId;

    if (savedUrl != null && savedUrl.isNotEmpty) {
      _serverUrl = savedUrl;
    } else if (kIsWeb) {
      try {
        if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') {
          final origin = Uri.base.origin;
          if (origin.isNotEmpty) {
            _serverUrl = origin;
          }
        }
      } catch (e) {
        debugPrint('[RenderService] Error detectando origen web: $e');
      }
    }

    connectWebSocket(preferredRole);
  }

  static Future<void> updateServerUrl(String newUrl) async {
    _serverUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRenderUrl, _serverUrl);

    _channel?.sink.close();
    connectWebSocket();
  }

  static void connectWebSocket([String? preferredRole]) {
    if (_isConnecting) return;
    _isConnecting = true;
    _connectionState = RenderConnectionState.connecting;

    try {
      final wsUrl = _getWebSocketUrl();
      debugPrint('[Render WS] Conectando a $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (data) {
          _isConnecting = false;
          _connectionState = RenderConnectionState.connected;
          _startKeepAlive();

          try {
            final Map<String, dynamic> parsed = jsonDecode(data as String);
            _wsEventStream.add(parsed);

            // Once initial_state arrives, request our dynamic turn role if not yet assigned
            if (parsed['type'] == 'initial_state') {
              requestRoleAssignment(preferredRole: preferredRole);
            }
          } catch (e) {
            debugPrint('[Render WS] Error decodificando evento: $e');
          }
        },
        onError: (error) {
          debugPrint('[Render WS] Error de conexión: $error');
          _onDisconnect();
        },
        onDone: () {
          debugPrint('[Render WS] Conexión cerrada.');
          _onDisconnect();
        },
      );
    } catch (e) {
      debugPrint('[Render WS] Excepción al conectar: $e');
      _onDisconnect();
    }
  }

  static void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_connectionState == RenderConnectionState.connected) {
        sendWsMessage('ping', {'clientId': _clientId});
      }
    });
  }

  static void _onDisconnect() {
    _isConnecting = false;
    _connectionState = RenderConnectionState.disconnected;
    _keepAliveTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      connectWebSocket();
    });
  }

  static String _getWebSocketUrl() {
    final clean = _serverUrl.replaceAll('https://', 'wss://').replaceAll('http://', 'ws://');
    return '$clean/ws';
  }

  static void requestRoleAssignment({String? preferredRole}) {
    final payload = <String, dynamic>{
      'clientId': _clientId,
    };
    if (preferredRole != null) {
      payload['preferredRole'] = preferredRole;
    }
    sendWsMessage('request_role', payload);
  }

  static void releaseRole() {
    sendWsMessage('release_role', {
      'clientId': _clientId,
    });
  }

  static void sendWsMessage(String type, Map<String, dynamic> data) {
    if (_channel != null && _connectionState == RenderConnectionState.connected) {
      final payload = jsonEncode({'type': type, ...data});
      _channel!.sink.add(payload);
    }
  }

  // --- REST HTTP Client for Render Backend ---

  // Health check
  static Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$_serverUrl/api/status')).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Messages
  static Future<List<ChatMessage>> fetchMessages() async {
    try {
      final res = await http.get(Uri.parse('$_serverUrl/api/messages')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[Render HTTP] fetchMessages error: $e');
    }
    return [];
  }

  static Future<bool> postMessage(ChatMessage message) async {
    try {
      final res = await http.post(
        Uri.parse('$_serverUrl/api/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message.toJson()),
      ).timeout(const Duration(seconds: 6));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('[Render HTTP] postMessage error: $e');
      return false;
    }
  }

  static Future<bool> clearMessagesOnServer() async {
    try {
      final res = await http.delete(Uri.parse('$_serverUrl/api/messages')).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Reports
  static Future<List<IncidentReport>> fetchReports() async {
    try {
      final res = await http.get(Uri.parse('$_serverUrl/api/reports')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        return list.map((r) => IncidentReport.fromJson(r as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[Render HTTP] fetchReports error: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> postReport(Map<String, dynamic> reportData) async {
    try {
      final res = await http.post(
        Uri.parse('$_serverUrl/api/reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reportData),
      ).timeout(const Duration(seconds: 6));

      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200 || res.statusCode == 201,
        'status': res.statusCode,
        'message': data['error'] ?? data['message'] ?? 'OK',
        'report': data['report'],
      };
    } catch (e) {
      return {
        'success': false,
        'status': 500,
        'message': 'Error de conexión con Render: $e',
      };
    }
  }

  static Future<bool> updatePriorityOnServer(String id, String priority) async {
    try {
      final res = await http.put(
        Uri.parse('$_serverUrl/api/reports/$id/priority'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'priority': priority}),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteReportOnServer(String id) async {
    try {
      final res = await http.delete(Uri.parse('$_serverUrl/api/reports/$id')).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updatePresenceOnServer(String role, bool isOnline) async {
    try {
      final res = await http.post(
        Uri.parse('$_serverUrl/api/devices/presence'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role, 'isOnline': isOnline}),
      ).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<TestCaseItem>> runMatrixOnServer(String code) async {
    try {
      final endpoint = code == 'ALL' ? '$_serverUrl/api/matrix/run-all' : '$_serverUrl/api/matrix/run/$code';
      final res = await http.post(Uri.parse(endpoint)).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> list = data['matrix'] ?? [];
        return list.map((t) => TestCaseItem.fromJson(t as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[Render HTTP] runMatrix error: $e');
    }
    return [];
  }
}
