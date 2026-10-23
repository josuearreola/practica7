import 'package:flutter/material.dart';

enum AppRole {
  admin,
  agente,
  usuario1,
  usuario2,
  espera;

  String get code {
    switch (this) {
      case AppRole.admin:
        return 'admin';
      case AppRole.agente:
        return 'agente';
      case AppRole.usuario1:
        return 'usuario1';
      case AppRole.usuario2:
        return 'usuario2';
      case AppRole.espera:
        return 'espera';
    }
  }

  String get displayName {
    switch (this) {
      case AppRole.admin:
        return 'Administrador';
      case AppRole.agente:
        return 'Agente de Atención / Soporte';
      case AppRole.usuario1:
        return 'Usuario 1 (Sistemas)';
      case AppRole.usuario2:
        return 'Usuario 2 (Finanzas)';
      case AppRole.espera:
        return 'En espera de turno';
    }
  }

  String get deviceName {
    switch (this) {
      case AppRole.admin:
        return 'Dispositivo 1 - Administrador';
      case AppRole.agente:
        return 'Dispositivo 2 - Soporte';
      case AppRole.usuario1:
        return 'Dispositivo 3 - Usuario 1';
      case AppRole.usuario2:
        return 'Dispositivo 4 - Usuario 2';
      case AppRole.espera:
        return 'Dispositivo en Espera';
    }
  }

  String get shortDeviceName {
    switch (this) {
      case AppRole.admin:
        return 'Disp. 1 (Admin)';
      case AppRole.agente:
        return 'Disp. 2 (Soporte)';
      case AppRole.usuario1:
        return 'Disp. 3 (Usuario 1)';
      case AppRole.usuario2:
        return 'Disp. 4 (Usuario 2)';
      case AppRole.espera:
        return 'En Espera';
    }
  }

  String get badgeLabel {
    switch (this) {
      case AppRole.admin:
        return 'Administrador Central (Turno 1)';
      case AppRole.agente:
        return 'Mesa de Soporte (Turno 2)';
      case AppRole.usuario1:
        return 'Solicitante IT (Turno 3)';
      case AppRole.usuario2:
        return 'Solicitante Finanzas (Turno 4)';
      case AppRole.espera:
        return 'Sala de Espera de Turno';
    }
  }

  String get routePath {
    switch (this) {
      case AppRole.admin:
        return '/admin';
      case AppRole.agente:
        return '/agente';
      case AppRole.usuario1:
        return '/usuario1';
      case AppRole.usuario2:
        return '/usuario2';
      case AppRole.espera:
        return '/espera';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppRole.admin:
        return const Color(0xFF6366F1); // Indigo
      case AppRole.agente:
        return const Color(0xFF10B981); // Emerald
      case AppRole.usuario1:
        return const Color(0xFF0EA5E9); // Sky
      case AppRole.usuario2:
        return const Color(0xFFF59E0B); // Amber
      case AppRole.espera:
        return const Color(0xFF94A3B8); // Slate
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AppRole.admin:
        return const Color(0xFF1E1B4B);
      case AppRole.agente:
        return const Color(0xFF064E3B);
      case AppRole.usuario1:
        return const Color(0xFF0C4A6E);
      case AppRole.usuario2:
        return const Color(0xFF78350F);
      case AppRole.espera:
        return const Color(0xFF1E293B);
    }
  }

  IconData get icon {
    switch (this) {
      case AppRole.admin:
        return Icons.admin_panel_settings_rounded;
      case AppRole.agente:
        return Icons.support_agent_rounded;
      case AppRole.usuario1:
        return Icons.person_rounded;
      case AppRole.usuario2:
        return Icons.account_circle_outlined;
      case AppRole.espera:
        return Icons.hourglass_top_rounded;
    }
  }

  bool get canAccessTestMatrix => this == AppRole.admin || this == AppRole.agente;

  static List<AppRole> get coreRoles => [
        AppRole.admin,
        AppRole.agente,
        AppRole.usuario1,
        AppRole.usuario2,
      ];

  static AppRole fromString(String? value) {
    if (value == null) return AppRole.admin;
    final clean = value.toLowerCase().replaceAll('/', '').replaceAll('#', '').trim();
    if (clean.contains('espera') || clean.contains('wait')) return AppRole.espera;
    if (clean.contains('admin')) return AppRole.admin;
    if (clean.contains('agente') || clean.contains('agent') || clean.contains('soporte')) return AppRole.agente;
    if (clean.contains('usuario1') || clean.contains('user1')) return AppRole.usuario1;
    if (clean.contains('usuario2') || clean.contains('user2')) return AppRole.usuario2;
    return AppRole.admin;
  }
}
