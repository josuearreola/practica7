import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_role.dart';

enum IncidentCategory {
  reporteFallas,
  procesoAtencion,
  solucionAccesosPerdidos;

  String get displayName {
    switch (this) {
      case IncidentCategory.reporteFallas:
        return 'Reporte de Fallas';
      case IncidentCategory.procesoAtencion:
        return 'Proceso de Atención';
      case IncidentCategory.solucionAccesosPerdidos:
        return 'Solución de Accesos Perdidos';
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentCategory.reporteFallas:
        return Icons.build_circle_outlined;
      case IncidentCategory.procesoAtencion:
        return Icons.headset_mic_outlined;
      case IncidentCategory.solucionAccesosPerdidos:
        return Icons.lock_reset_rounded;
    }
  }

  static IncidentCategory fromString(String? val) {
    if (val == null) return IncidentCategory.reporteFallas;
    if (val.contains('Accesos') || val.contains('accesos')) {
      return IncidentCategory.solucionAccesosPerdidos;
    }
    if (val.contains('Atencion') || val.contains('atencion')) {
      return IncidentCategory.procesoAtencion;
    }
    return IncidentCategory.reporteFallas;
  }
}

enum IncidentPriority {
  baja,
  media,
  alta,
  critica;

  String get displayName {
    switch (this) {
      case IncidentPriority.baja:
        return 'Baja';
      case IncidentPriority.media:
        return 'Media';
      case IncidentPriority.alta:
        return 'Alta';
      case IncidentPriority.critica:
        return 'Crítica';
    }
  }

  Color get color {
    switch (this) {
      case IncidentPriority.baja:
        return const Color(0xFF10B981); // Emerald
      case IncidentPriority.media:
        return const Color(0xFF3B82F6); // Blue
      case IncidentPriority.alta:
        return const Color(0xFFF59E0B); // Amber
      case IncidentPriority.critica:
        return const Color(0xFFEF4444); // Red
    }
  }

  static IncidentPriority fromString(String? val) {
    if (val == null) return IncidentPriority.media;
    final clean = val.toLowerCase().trim();
    if (clean.contains('baja') || clean == 'low') return IncidentPriority.baja;
    if (clean.contains('alta') || clean == 'high') return IncidentPriority.alta;
    if (clean.contains('critica') || clean == 'critical') return IncidentPriority.critica;
    return IncidentPriority.media;
  }
}

enum IncidentStatus {
  abierto,
  enAtencion,
  escaladoAdmin,
  resuelto,
  cerrado;

  String get displayName {
    switch (this) {
      case IncidentStatus.abierto:
        return 'Abierto';
      case IncidentStatus.enAtencion:
        return 'En Atención por Agente';
      case IncidentStatus.escaladoAdmin:
        return 'Escalado al Administrador';
      case IncidentStatus.resuelto:
        return 'Resuelto';
      case IncidentStatus.cerrado:
        return 'Cerrado';
    }
  }

  Color get color {
    switch (this) {
      case IncidentStatus.abierto:
        return const Color(0xFF64748B);
      case IncidentStatus.enAtencion:
        return const Color(0xFF0284C7);
      case IncidentStatus.escaladoAdmin:
        return const Color(0xFFDC2626);
      case IncidentStatus.resuelto:
        return const Color(0xFF059669);
      case IncidentStatus.cerrado:
        return const Color(0xFF475569);
    }
  }

  static IncidentStatus fromString(String? val) {
    if (val == null) return IncidentStatus.abierto;
    final clean = val.toLowerCase().trim();
    if (clean.contains('atencion')) return IncidentStatus.enAtencion;
    if (clean.contains('escalado') || clean.contains('admin')) return IncidentStatus.escaladoAdmin;
    if (clean.contains('resuelto')) return IncidentStatus.resuelto;
    if (clean.contains('cerrado')) return IncidentStatus.cerrado;
    return IncidentStatus.abierto;
  }
}

class IncidentReport {
  final String id;
  final String title;
  final String equipment;
  final String description;
  final IncidentCategory category;
  IncidentPriority priority;
  IncidentStatus status;
  AppRole assignedRole;
  final AppRole reportedByRole;
  final DateTime createdAt;
  DateTime updatedAt;
  String? resolutionNotes;
  bool isDirectToAdmin;

  IncidentReport({
    required this.id,
    required this.title,
    required this.equipment,
    required this.description,
    required this.category,
    this.priority = IncidentPriority.media,
    this.status = IncidentStatus.abierto,
    this.assignedRole = AppRole.agente,
    this.reportedByRole = AppRole.usuario1,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.resolutionNotes,
    this.isDirectToAdmin = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? (createdAt ?? DateTime.now());

  String get formattedCreatedAt => DateFormat('dd/MM/yyyy hh:mm a').format(createdAt);
  String get formattedUpdatedAt => DateFormat('dd/MM/yyyy hh:mm a').format(updatedAt);

  IncidentReport copyWith({
    String? id,
    String? title,
    String? equipment,
    String? description,
    IncidentCategory? category,
    IncidentPriority? priority,
    IncidentStatus? status,
    AppRole? assignedRole,
    AppRole? reportedByRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? resolutionNotes,
    bool? isDirectToAdmin,
  }) {
    return IncidentReport(
      id: id ?? this.id,
      title: title ?? this.title,
      equipment: equipment ?? this.equipment,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedRole: assignedRole ?? this.assignedRole,
      reportedByRole: reportedByRole ?? this.reportedByRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      isDirectToAdmin: isDirectToAdmin ?? this.isDirectToAdmin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'equipment': equipment,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'assignedRole': assignedRole.code,
      'reportedByRole': reportedByRole.code,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'isDirectToAdmin': isDirectToAdmin,
    };
  }

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    return IncidentReport(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Reporte de Incidencia',
      equipment: json['equipment'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: IncidentCategory.fromString(json['category'] as String?),
      priority: IncidentPriority.fromString(json['priority'] as String?),
      status: IncidentStatus.fromString(json['status'] as String?),
      assignedRole: AppRole.fromString(json['assignedRole'] as String?),
      reportedByRole: AppRole.fromString(json['reportedByRole'] as String?),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      resolutionNotes: json['resolutionNotes'] as String?,
      isDirectToAdmin: json['isDirectToAdmin'] as bool? ?? false,
    );
  }
}
