import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TestStatus {
  sinRegistrar,
  enEjecucion,
  aprobado,
  fallido;

  String get displayName {
    switch (this) {
      case TestStatus.sinRegistrar:
        return 'Sin registrar';
      case TestStatus.enEjecucion:
        return 'En ejecución...';
      case TestStatus.aprobado:
        return 'Aprobado (Pasó)';
      case TestStatus.fallido:
        return 'Fallido';
    }
  }

  Color get color {
    switch (this) {
      case TestStatus.sinRegistrar:
        return const Color(0xFF64748B); // Slate
      case TestStatus.enEjecucion:
        return const Color(0xFF3B82F6); // Blue
      case TestStatus.aprobado:
        return const Color(0xFF10B981); // Emerald
      case TestStatus.fallido:
        return const Color(0xFFEF4444); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case TestStatus.sinRegistrar:
        return Icons.radio_button_unchecked_rounded;
      case TestStatus.enEjecucion:
        return Icons.sync_rounded;
      case TestStatus.aprobado:
        return Icons.check_circle_rounded;
      case TestStatus.fallido:
        return Icons.cancel_rounded;
    }
  }
}

class TestCaseItem {
  final String code;
  final String name;
  final String action;
  final String expected;
  TestStatus status;
  String observations;
  DateTime? executedAt;

  TestCaseItem({
    required this.code,
    required this.name,
    required this.action,
    required this.expected,
    this.status = TestStatus.sinRegistrar,
    this.observations = 'Sin observaciones',
    this.executedAt,
  });

  String get formattedExecutedAt {
    if (executedAt == null) return 'No ejecutado';
    return DateFormat('hh:mm:ss a').format(executedAt!);
  }

  TestCaseItem copyWith({
    String? code,
    String? name,
    String? action,
    String? expected,
    TestStatus? status,
    String? observations,
    DateTime? executedAt,
  }) {
    return TestCaseItem(
      code: code ?? this.code,
      name: name ?? this.name,
      action: action ?? this.action,
      expected: expected ?? this.expected,
      status: status ?? this.status,
      observations: observations ?? this.observations,
      executedAt: executedAt ?? this.executedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'action': action,
      'expected': expected,
      'status': status.name,
      'observations': observations,
      'executedAt': executedAt?.toIso8601String(),
    };
  }

  factory TestCaseItem.fromJson(Map<String, dynamic> json) {
    return TestCaseItem(
      code: json['code'] as String,
      name: json['name'] as String,
      action: json['action'] as String,
      expected: json['expected'] as String,
      status: TestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TestStatus.sinRegistrar,
      ),
      observations: json['observations'] as String? ?? 'Sin observaciones',
      executedAt: json['executedAt'] != null
          ? DateTime.parse(json['executedAt'] as String)
          : null,
    );
  }

  static List<TestCaseItem> getDefaultTestCases() {
    return [
      TestCaseItem(
        code: 'TC01',
        name: 'Alta válida',
        action: 'Registrar un reporte con todos los campos correctos.',
        expected: 'El documento se almacena y puede consultarse.',
      ),
      TestCaseItem(
        code: 'TC02',
        name: 'Campos vacíos',
        action: 'Intentar guardar un reporte sin equipo ni descripción.',
        expected: 'La aplicación rechaza los datos y muestra una validación.',
      ),
      TestCaseItem(
        code: 'TC03',
        name: 'Identificador repetido',
        action: 'Guardar dos veces el reporte con ID REP001.',
        expected: 'La aplicación evita sobrescribir información accidentalmente o aplica una política explícita.',
      ),
      TestCaseItem(
        code: 'TC04',
        name: 'Actualización',
        action: 'Cambiar la prioridad de un reporte de Media a Alta.',
        expected: 'El cambio se conserva al volver a consultar el documento.',
      ),
      TestCaseItem(
        code: 'TC05',
        name: 'Eliminación',
        action: 'Eliminar un reporte existente y consultarlo nuevamente.',
        expected: 'El documento ya no aparece como registro activo.',
      ),
      TestCaseItem(
        code: 'TC06',
        name: 'Documento inexistente',
        action: 'Consultar el ID REP999.',
        expected: 'La aplicación maneja el resultado vacío sin bloquearse.',
      ),
      TestCaseItem(
        code: 'TC07',
        name: 'Pérdida de conexión',
        action: 'Desactivar la conexión durante una operación de escritura.',
        expected: 'La app informa el estado de la operación y gestiona la sincronización o el error.',
      ),
      TestCaseItem(
        code: 'TC08',
        name: 'Persistencia',
        action: 'Cerrar y abrir la app; consultar un reporte guardado.',
        expected: 'El dato persiste en Firestore y vuelve a mostrarse.',
      ),
    ];
  }
}
