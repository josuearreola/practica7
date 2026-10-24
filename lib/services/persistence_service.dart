import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/incident_report.dart';
import '../models/test_case.dart';

class PersistenceService {
  static const String _keyReports = 'practica7_firestore_reports';
  static const String _keyMessages = 'practica7_chat_messages';
  static const String _keyTestCases = 'practica7_test_matrix';
  static const String _keyOfflineMode = 'practica7_simulated_offline';
  static const String _keyAgentConnected = 'practica7_agent_connected';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- Reports (Simulated Firestore Collection) ---
  static Future<List<IncidentReport>> loadReports() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyReports);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .map((item) => IncidentReport.fromJson(item as Map<String, dynamic>))
          .where((r) => !['REP001', 'REP002', 'REP003', 'REP004'].contains(r.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveReports(List<IncidentReport> reports) async {
    final prefs = await _instance;
    final raw = jsonEncode(reports.map((r) => r.toJson()).toList());
    await prefs.setString(_keyReports, raw);
  }

  // --- Messages ---
  static Future<List<ChatMessage>> loadMessages() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyMessages);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .where((m) => !['msg-001', 'msg-002', 'msg-003', 'msg-004'].contains(m.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await _instance;
    final raw = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(_keyMessages, raw);
  }

  // --- Test Cases Matrix ---
  static Future<List<TestCaseItem>> loadTestCases() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyTestCases);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((item) => TestCaseItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveTestCases(List<TestCaseItem> tests) async {
    final prefs = await _instance;
    final raw = jsonEncode(tests.map((t) => t.toJson()).toList());
    await prefs.setString(_keyTestCases, raw);
  }

  // --- Agent Connected Flag ---
  static Future<bool> loadAgentConnected() async {
    final prefs = await _instance;
    return prefs.getBool(_keyAgentConnected) ?? true;
  }

  static Future<void> saveAgentConnected(bool connected) async {
    final prefs = await _instance;
    await prefs.setBool(_keyAgentConnected, connected);
  }

  // --- Simulated Offline Mode (TC07) ---
  static Future<bool> loadOfflineMode() async {
    final prefs = await _instance;
    return prefs.getBool(_keyOfflineMode) ?? false;
  }

  static Future<void> saveOfflineMode(bool isOffline) async {
    final prefs = await _instance;
    await prefs.setBool(_keyOfflineMode, isOffline);
  }

  // Clear all
  static Future<void> clearAll() async {
    final prefs = await _instance;
    await prefs.clear();
  }
}
