import 'package:flutter/material.dart';
import '../models/app_role.dart';
import '../models/incident_report.dart';
import '../services/mock_data.dart';
import '../services/persistence_service.dart';
import '../services/render_service.dart';
import '../services/sync_service.dart';

class IncidentOperationResult {
  final bool success;
  final String message;
  final IncidentReport? report;

  IncidentOperationResult({
    required this.success,
    required this.message,
    this.report,
  });
}

class IncidentProvider extends ChangeNotifier {
  final List<IncidentReport> _reports = [];
  bool _isLoading = false;
  String? _lastOperationMessage;

  List<IncidentReport> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get lastOperationMessage => _lastOperationMessage;

  IncidentProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // 1. Load local persistence
    final loaded = await PersistenceService.loadReports();
    if (loaded.isEmpty) {
      _reports.addAll(MockData.getInitialReports());
      await PersistenceService.saveReports(_reports);
    } else {
      _reports.addAll(loaded);
    }

    _isLoading = false;
    notifyListeners();

    // 2. Fetch from Render backend
    try {
      final remoteReports = await RenderService.fetchReports();
      if (remoteReports.isNotEmpty) {
        _reports.clear();
        _reports.addAll(remoteReports);
        await PersistenceService.saveReports(_reports);
        notifyListeners();
      }
    } catch (_) {}

    // 3. Listen to local sync events
    SyncService.stream.listen((event) async {
      if (event.type == SyncEventType.ticketCreated ||
          event.type == SyncEventType.ticketUpdated ||
          event.type == SyncEventType.ticketDeleted ||
          event.type == SyncEventType.forceReload) {
        await reloadReports();
      } else if (event.type == SyncEventType.agentStatusChanged) {
        if (event.payload == 'disconnected') {
          await handleAgentDisconnection();
        }
      }
    });

    // 4. Listen to real-time Render WebSocket events
    RenderService.events.listen((event) async {
      final type = event['type'];
      final payload = event['payload'];

      if (type == 'ticket_created' && payload != null) {
        try {
          final rep = IncidentReport.fromJson(payload as Map<String, dynamic>);
          final idx = _reports.indexWhere((r) => r.id.toUpperCase() == rep.id.toUpperCase());
          if (idx == -1) {
            _reports.insert(0, rep);
          } else {
            _reports[idx] = rep;
          }
          await PersistenceService.saveReports(_reports);
          notifyListeners();
        } catch (_) {}
      } else if (type == 'ticket_updated' && payload != null) {
        try {
          final rep = IncidentReport.fromJson(payload as Map<String, dynamic>);
          final idx = _reports.indexWhere((r) => r.id.toUpperCase() == rep.id.toUpperCase());
          if (idx != -1) {
            _reports[idx] = rep;
            await PersistenceService.saveReports(_reports);
            notifyListeners();
          }
        } catch (_) {}
      } else if (type == 'ticket_deleted' && payload != null) {
        final id = payload['id'] as String?;
        if (id != null) {
          _reports.removeWhere((r) => r.id.toUpperCase() == id.toUpperCase());
          await PersistenceService.saveReports(_reports);
          notifyListeners();
        }
      } else if (type == 'agent_status_changed' && payload != null) {
        final reportsList = payload['reports'] as List<dynamic>?;
        if (reportsList != null) {
          _reports.clear();
          _reports.addAll(reportsList.map((r) => IncidentReport.fromJson(r as Map<String, dynamic>)));
          await PersistenceService.saveReports(_reports);
          notifyListeners();
        }
      } else if (type == 'initial_state' && payload != null) {
        final list = payload['reports'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          _reports.clear();
          _reports.addAll(list.map((r) => IncidentReport.fromJson(r as Map<String, dynamic>)));
          await PersistenceService.saveReports(_reports);
          notifyListeners();
        }
      }
    });
  }

  Future<void> reloadReports() async {
    final loaded = await PersistenceService.loadReports();
    _reports.clear();
    _reports.addAll(loaded);
    notifyListeners();
  }

  // TC01, TC02, TC03 - Create Report
  Future<IncidentOperationResult> createReport({
    required String id,
    required String title,
    required String equipment,
    required String description,
    required IncidentCategory category,
    IncidentPriority priority = IncidentPriority.media,
    AppRole assignedRole = AppRole.agente,
    AppRole reportedByRole = AppRole.usuario1,
    bool isDirectToAdmin = false,
    bool isOfflineSimulated = false,
  }) async {
    // TC07: Pérdida de conexión check
    if (isOfflineSimulated) {
      return IncidentOperationResult(
        success: false,
        message: 'Error de red (TC07): No se pudo sincronizar la operación debido a pérdida de conexión.',
      );
    }

    final trimmedId = id.trim().toUpperCase();
    final trimmedTitle = title.trim();
    final trimmedEquipment = equipment.trim();
    final trimmedDesc = description.trim();

    // TC02: Campos vacíos check
    if (trimmedEquipment.isEmpty || trimmedDesc.isEmpty) {
      return IncidentOperationResult(
        success: false,
        message: 'Error de validación (TC02): El equipo y la descripción son campos obligatorios.',
      );
    }

    if (trimmedId.isEmpty) {
      return IncidentOperationResult(
        success: false,
        message: 'Error de validación: El ID del reporte es obligatorio.',
      );
    }

    // TC03: Identificador repetido check
    final exists = _reports.any((r) => r.id.toUpperCase() == trimmedId);
    if (exists) {
      return IncidentOperationResult(
        success: false,
        message: 'Error de duplicidad (TC03): El ID "$trimmedId" ya existe. Se evita la sobrescritura accidental.',
      );
    }

    final newReport = IncidentReport(
      id: trimmedId,
      title: trimmedTitle.isEmpty ? 'Reporte $trimmedId' : trimmedTitle,
      equipment: trimmedEquipment,
      description: trimmedDesc,
      category: category,
      priority: priority,
      status: isDirectToAdmin ? IncidentStatus.escaladoAdmin : IncidentStatus.abierto,
      assignedRole: isDirectToAdmin ? AppRole.admin : assignedRole,
      reportedByRole: reportedByRole,
      isDirectToAdmin: isDirectToAdmin,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _reports.insert(0, newReport);
    await PersistenceService.saveReports(_reports);

    _lastOperationMessage = 'Reporte ${newReport.id} registrado exitosamente.';
    await SyncService.broadcast(
      SyncEventType.ticketCreated,
      sender: reportedByRole.code,
      payload: newReport.id,
    );

    // Sync to Render backend
    RenderService.postReport(newReport.toJson());

    notifyListeners();

    return IncidentOperationResult(
      success: true,
      message: 'Reporte registrado y almacenado correctamente en la persistencia.',
      report: newReport,
    );
  }

  // TC04 - Actualización (Prioridad)
  Future<IncidentOperationResult> updatePriority(String reportId, IncidentPriority newPriority, {bool isOfflineSimulated = false}) async {
    if (isOfflineSimulated) {
      return IncidentOperationResult(
        success: false,
        message: 'Error de red (TC07): No se pudo actualizar el reporte por pérdida de conexión.',
      );
    }

    final index = _reports.indexWhere((r) => r.id.toUpperCase() == reportId.toUpperCase());
    if (index == -1) {
      return IncidentOperationResult(
        success: false,
        message: 'Reporte no encontrado.',
      );
    }

    final oldReport = _reports[index];
    final updated = oldReport.copyWith(
      priority: newPriority,
      updatedAt: DateTime.now(),
    );

    _reports[index] = updated;
    await PersistenceService.saveReports(_reports);

    _lastOperationMessage = 'Prioridad de ${updated.id} actualizada a ${newPriority.displayName}.';
    await SyncService.broadcast(
      SyncEventType.ticketUpdated,
      sender: 'system',
      payload: updated.id,
    );

    // Sync to Render
    RenderService.updatePriorityOnServer(reportId, newPriority.name);

    notifyListeners();

    return IncidentOperationResult(
      success: true,
      message: 'Prioridad actualizada exitosamente.',
      report: updated,
    );
  }

  // TC05 - Eliminación
  Future<IncidentOperationResult> deleteReport(String reportId, {bool isOfflineSimulated = false}) async {
    if (isOfflineSimulated) {
      return IncidentOperationResult(
        success: false,
        message: 'Error de red (TC07): No se pudo eliminar el reporte por pérdida de conexión.',
      );
    }

    final index = _reports.indexWhere((r) => r.id.toUpperCase() == reportId.toUpperCase());
    if (index == -1) {
      return IncidentOperationResult(
        success: false,
        message: 'Reporte no encontrado para eliminar.',
      );
    }

    final removed = _reports.removeAt(index);
    await PersistenceService.saveReports(_reports);

    _lastOperationMessage = 'Reporte ${removed.id} eliminado correctamente.';
    await SyncService.broadcast(
      SyncEventType.ticketDeleted,
      sender: 'system',
      payload: removed.id,
    );

    // Sync to Render
    RenderService.deleteReportOnServer(reportId);

    notifyListeners();

    return IncidentOperationResult(
      success: true,
      message: 'El reporte ${removed.id} fue eliminado y ya no aparece como registro activo.',
      report: removed,
    );
  }

  // TC06 - Documento Inexistente query
  IncidentReport? getReportById(String reportId) {
    try {
      final match = _reports.firstWhere((r) => r.id.toUpperCase() == reportId.toUpperCase());
      return match;
    } catch (e) {
      return null;
    }
  }

  // Reasignar casos cuando el Agente se desconecta
  Future<int> handleAgentDisconnection() async {
    int escalatedCount = 0;
    for (int i = 0; i < _reports.length; i++) {
      if (_reports[i].assignedRole == AppRole.agente &&
          _reports[i].status != IncidentStatus.resuelto &&
          _reports[i].status != IncidentStatus.cerrado) {
        _reports[i] = _reports[i].copyWith(
          assignedRole: AppRole.admin,
          status: IncidentStatus.escaladoAdmin,
          resolutionNotes: 'Escalado automáticamente al Administrador por desconexión del Agente.',
          updatedAt: DateTime.now(),
        );
        escalatedCount++;
      }
    }

    if (escalatedCount > 0) {
      await PersistenceService.saveReports(_reports);
      _lastOperationMessage = '$escalatedCount reportes del Agente han sido escalados al Administrador.';
      notifyListeners();
    }
    return escalatedCount;
  }

  Future<void> reassignReport(String reportId, AppRole newRole, IncidentStatus newStatus) async {
    final index = _reports.indexWhere((r) => r.id.toUpperCase() == reportId.toUpperCase());
    if (index != -1) {
      _reports[index] = _reports[index].copyWith(
        assignedRole: newRole,
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await PersistenceService.saveReports(_reports);
      await SyncService.broadcast(SyncEventType.ticketUpdated, sender: 'admin', payload: reportId);
      notifyListeners();
    }
  }

  Future<void> resetToMock() async {
    _reports.clear();
    _reports.addAll(MockData.getInitialReports());
    await PersistenceService.saveReports(_reports);
    notifyListeners();
  }
}
