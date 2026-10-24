import '../models/chat_message.dart';
import '../models/incident_report.dart';

/// Sin datos simulados ni tickets pre-generados.
/// Todo es nuevo y redactado directamente por el usuario desde cero.
class MockData {
  static List<IncidentReport> getInitialReports() {
    return [];
  }

  static List<ChatMessage> getInitialMessages() {
    return [];
  }
}
