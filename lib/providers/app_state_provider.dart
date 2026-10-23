import 'package:flutter/material.dart';
import '../models/app_role.dart';
import '../services/persistence_service.dart';
import '../services/render_service.dart';
import '../services/sync_service.dart';

class AppStateProvider extends ChangeNotifier {
  AppRole _currentRole = AppRole.admin;
  AppRole _selectedSenderRole = AppRole.admin;
  AppRole _selectedReceiverRole = AppRole.usuario1;

  bool _isAgentConnected = true;
  bool _isOfflineSimulated = false; // For TC07 test
  String? _lastSystemAlert;

  AppRole get currentRole => _currentRole;
  AppRole get selectedSenderRole => _selectedSenderRole;
  AppRole get selectedReceiverRole => _selectedReceiverRole;
  bool get isAgentConnected => _isAgentConnected;
  bool get isOfflineSimulated => _isOfflineSimulated;
  String? get lastSystemAlert => _lastSystemAlert;

  AppStateProvider() {
    _init();
  }

  Future<void> _init() async {
    _isAgentConnected = await PersistenceService.loadAgentConnected();
    _isOfflineSimulated = await PersistenceService.loadOfflineMode();
    notifyListeners();

    // Listen to local sync stream
    SyncService.stream.listen((event) async {
      if (event.type == SyncEventType.agentStatusChanged || event.type == SyncEventType.forceReload) {
        _isAgentConnected = await PersistenceService.loadAgentConnected();
        notifyListeners();
      }
    });

    // Listen to Render events
    RenderService.events.listen((event) {
      final type = event['type'];
      final payload = event['payload'];

      if (type == 'agent_status_changed' && payload != null) {
        final isOnline = payload['isOnline'] as bool?;
        if (isOnline != null && isOnline != _isAgentConnected) {
          _isAgentConnected = isOnline;
          PersistenceService.saveAgentConnected(_isAgentConnected);
          notifyListeners();
        }
      }
    });
  }

  void setRole(AppRole role) {
    _currentRole = role;
    _selectedSenderRole = role;

    // Register active device on Render
    RenderService.sendWsMessage('register_device', {'role': role.code});

    if (role == AppRole.admin) {
      _selectedReceiverRole = AppRole.usuario1;
    } else if (role == AppRole.agente) {
      _selectedReceiverRole = AppRole.usuario1;
    } else {
      _selectedReceiverRole = _isAgentConnected ? AppRole.agente : AppRole.admin;
    }
    notifyListeners();
  }

  void setSelectedSenderRole(AppRole role) {
    _selectedSenderRole = role;
    notifyListeners();
  }

  void setSelectedReceiverRole(AppRole role) {
    _selectedReceiverRole = role;
    notifyListeners();
  }

  Future<void> toggleAgentConnection() async {
    _isAgentConnected = !_isAgentConnected;
    await PersistenceService.saveAgentConnected(_isAgentConnected);

    _lastSystemAlert = _isAgentConnected
        ? 'El Agente de Atención se ha CONECTADO nuevamente.'
        : 'ALERTA: El Agente de Atención se ha DESCONECTADO. Los casos son reasignados al Administrador.';

    await SyncService.broadcast(
      SyncEventType.agentStatusChanged,
      sender: _currentRole.code,
      payload: _isAgentConnected ? 'connected' : 'disconnected',
    );

    // Sync to Render server
    RenderService.sendWsMessage('toggle_agent_presence', {'isOnline': _isAgentConnected});
    RenderService.updatePresenceOnServer('agente', _isAgentConnected);

    notifyListeners();
  }

  Future<void> toggleOfflineSimulation() async {
    _isOfflineSimulated = !_isOfflineSimulated;
    await PersistenceService.saveOfflineMode(_isOfflineSimulated);
    _lastSystemAlert = _isOfflineSimulated
        ? 'Modo SIN CONEXIÓN activado (Simulando pérdida de red para TC07).'
        : 'Conexión restablecida con el servidor.';
    notifyListeners();
  }

  void clearAlert() {
    _lastSystemAlert = null;
    notifyListeners();
  }

  String getDeviceStatus(AppRole role) {
    if (role == AppRole.agente) {
      return _isAgentConnected ? 'En línea' : 'Desconectado';
    }
    return 'En línea';
  }

  bool isDeviceOnline(AppRole role) {
    if (role == AppRole.agente) {
      return _isAgentConnected;
    }
    return true;
  }
}
