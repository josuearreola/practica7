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

  // Dynamic Turn Assignment & Admin Disconnect Validation
  bool _isAdminDisconnectedSessionTerminated = false;
  String? _terminationReason;
  Map<String, dynamic> _serverDevices = {};
  String? _assignedRoleName;

  AppRole get currentRole => _currentRole;
  AppRole get selectedSenderRole => _selectedSenderRole;
  AppRole get selectedReceiverRole => _selectedReceiverRole;
  bool get isAgentConnected => _isAgentConnected;
  bool get isOfflineSimulated => _isOfflineSimulated;
  String? get lastSystemAlert => _lastSystemAlert;
  bool get isAdminDisconnectedSessionTerminated => _isAdminDisconnectedSessionTerminated;
  String? get terminationReason => _terminationReason;
  Map<String, dynamic> get serverDevices => _serverDevices;
  String? get assignedRoleName => _assignedRoleName;

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

      if (type == 'role_assigned' && payload != null) {
        final assignedRoleCode = payload['role'] as String?;
        if (assignedRoleCode != null) {
          final role = AppRole.fromString(assignedRoleCode);
          _currentRole = role;
          _selectedSenderRole = role;
          _assignedRoleName = payload['roleName'] as String?;
          _isAdminDisconnectedSessionTerminated = false;
          _terminationReason = null;

          if (payload['devices'] != null) {
            _serverDevices = Map<String, dynamic>.from(payload['devices'] as Map);
          }

          if (role == AppRole.admin) {
            _selectedReceiverRole = AppRole.usuario1;
          } else if (role == AppRole.agente) {
            _selectedReceiverRole = AppRole.usuario1;
          } else {
            _selectedReceiverRole = _isAgentConnected ? AppRole.agente : AppRole.admin;
          }

          notifyListeners();
        }
      } else if (type == 'admin_disconnected_session_terminated') {
        // VALIDACIÓN: Cuando el Admin se desconecta, se cierra la sesión a todos!
        _isAdminDisconnectedSessionTerminated = true;
        _terminationReason = payload?['reason'] as String? ??
            'El Administrador se ha desconectado. Todas las sesiones activas han sido cerradas por política de seguridad.';
        _currentRole = AppRole.espera;
        _selectedSenderRole = AppRole.espera;

        if (payload?['devices'] != null) {
          _serverDevices = Map<String, dynamic>.from(payload!['devices'] as Map);
        }

        _lastSystemAlert = 'ALERTA: El Administrador se ha desconectado. Tu sesión ha sido cerrada automáticamente.';
        notifyListeners();
      } else if (type == 'devices_state_updated' && payload != null) {
        if (payload['devices'] != null) {
          _serverDevices = Map<String, dynamic>.from(payload['devices'] as Map);
          notifyListeners();
        }
      } else if (type == 'agent_status_changed' && payload != null) {
        final isOnline = payload['isOnline'] as bool?;
        if (isOnline != null && isOnline != _isAgentConnected) {
          _isAgentConnected = isOnline;
          PersistenceService.saveAgentConnected(_isAgentConnected);
          notifyListeners();
        }
      }
    });
  }

  void requestTurnOrRole([AppRole? preferredRole]) {
    _isAdminDisconnectedSessionTerminated = false;
    _terminationReason = null;
    RenderService.requestRoleAssignment(preferredRole: preferredRole?.code);
    notifyListeners();
  }

  void releaseMyRole() {
    RenderService.releaseRole();
    _currentRole = AppRole.espera;
    _selectedSenderRole = AppRole.espera;
    notifyListeners();
  }

  void setRole(AppRole role) {
    _currentRole = role;
    _selectedSenderRole = role;

    // Request or register device on Render
    RenderService.requestRoleAssignment(preferredRole: role.code);

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
    if (_serverDevices.containsKey(role.code)) {
      final dev = _serverDevices[role.code];
      final isOnline = dev['isOnline'] == true;
      return isOnline ? 'En línea (Ocupado)' : 'Vacante (Disponible)';
    }

    if (role == AppRole.agente) {
      return _isAgentConnected ? 'En línea' : 'Desconectado';
    }
    return 'En línea';
  }

  bool isDeviceOnline(AppRole role) {
    if (_serverDevices.containsKey(role.code)) {
      final dev = _serverDevices[role.code];
      return dev['isOnline'] == true;
    }

    if (role == AppRole.agente) {
      return _isAgentConnected;
    }
    return true;
  }
}
