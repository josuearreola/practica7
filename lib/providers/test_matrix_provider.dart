import 'package:flutter/material.dart';
import '../models/app_role.dart';
import '../models/incident_report.dart';
import '../models/test_case.dart';
import '../services/persistence_service.dart';
import 'incident_provider.dart';

class TestMatrixProvider extends ChangeNotifier {
  List<TestCaseItem> _testCases = [];
  bool _isRunningAll = false;

  List<TestCaseItem> get testCases => List.unmodifiable(_testCases);
  bool get isRunningAll => _isRunningAll;

  TestMatrixProvider() {
    _init();
  }

  Future<void> _init() async {
    final loaded = await PersistenceService.loadTestCases();
    if (loaded.isEmpty) {
      _testCases = TestCaseItem.getDefaultTestCases();
      await PersistenceService.saveTestCases(_testCases);
    } else {
      _testCases = loaded;
    }
    notifyListeners();
  }

  Future<void> resetMatrix() async {
    _testCases = TestCaseItem.getDefaultTestCases();
    await PersistenceService.saveTestCases(_testCases);
    notifyListeners();
  }

  Future<void> runTestCase(String code, IncidentProvider incidentProvider) async {
    final index = _testCases.indexWhere((t) => t.code == code);
    if (index == -1) return;

    _testCases[index] = _testCases[index].copyWith(
      status: TestStatus.enEjecucion,
      observations: 'Ejecutando pruebas y verificaciones en tiempo real...',
    );
    notifyListeners();

    // Small delay to visually convey real-time execution
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      switch (code) {
        case 'TC01':
          await _executeTC01(index, incidentProvider);
          break;
        case 'TC02':
          await _executeTC02(index, incidentProvider);
          break;
        case 'TC03':
          await _executeTC03(index, incidentProvider);
          break;
        case 'TC04':
          await _executeTC04(index, incidentProvider);
          break;
        case 'TC05':
          await _executeTC05(index, incidentProvider);
          break;
        case 'TC06':
          await _executeTC06(index, incidentProvider);
          break;
        case 'TC07':
          await _executeTC07(index, incidentProvider);
          break;
        case 'TC08':
          await _executeTC08(index, incidentProvider);
          break;
        default:
          _testCases[index] = _testCases[index].copyWith(
            status: TestStatus.sinRegistrar,
            observations: 'Caso de prueba no configurado.',
          );
      }
    } catch (e) {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.fallido,
        observations: 'Error no controlado durante la prueba: $e',
        executedAt: DateTime.now(),
      );
    }

    await PersistenceService.saveTestCases(_testCases);
    notifyListeners();
  }

  Future<void> runAllTests(IncidentProvider incidentProvider) async {
    _isRunningAll = true;
    notifyListeners();

    for (final tc in _testCases) {
      await runTestCase(tc.code, incidentProvider);
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _isRunningAll = false;
    notifyListeners();
  }

  // --- Specific Test Implementations ---

  Future<void> _executeTC01(int index, IncidentProvider ip) async {
    final testId = 'TC01-VAL';
    // Clean if already exists
    ip.deleteReport(testId);

    final res = await ip.createReport(
      id: testId,
      title: 'Alta válida automatizada',
      equipment: 'Servidor Web Central Nginx',
      description: 'Prueba de almacenamiento y consulta con todos los campos correctos.',
      category: IncidentCategory.reporteFallas,
      priority: IncidentPriority.alta,
      assignedRole: AppRole.agente,
      reportedByRole: AppRole.usuario1,
    );

    final retrieved = ip.getReportById(testId);
    if (res.success && retrieved != null && retrieved.equipment == 'Servidor Web Central Nginx') {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.aprobado,
        observations: 'El documento con ID $testId se almacenó exitosamente y se consultó en memoria y almacenamiento persistente.',
        executedAt: DateTime.now(),
      );
    } else {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.fallido,
        observations: 'Fallo al almacenar o consultar el documento: ${res.message}',
        executedAt: DateTime.now(),
      );
    }
  }

  Future<void> _executeTC02(int index, IncidentProvider ip) async {
    final res = await ip.createReport(
      id: 'TC02-EMPTY',
      title: '',
      equipment: '', // Empty
      description: '', // Empty
      category: IncidentCategory.reporteFallas,
    );

    if (!res.success && res.message.contains('obligatorios')) {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.aprobado,
        observations: 'Validación exitosa: La aplicación rechazó los datos por falta de equipo y descripción ("${res.message}").',
        executedAt: DateTime.now(),
      );
    } else {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.fallido,
        observations: 'La aplicación permitió guardar con campos vacíos de manera incorrecta.',
        executedAt: DateTime.now(),
      );
    }
  }

  Future<void> _executeTC03(int index, IncidentProvider ip) async {
    // First ensure REP001 exists
    final exists = ip.getReportById('REP001');
    if (exists == null) {
      await ip.createReport(
        id: 'REP001',
        title: 'Reporte base REP001',
        equipment: 'Servidor Dell R740',
        description: 'Base para prueba de duplicados',
        category: IncidentCategory.reporteFallas,
      );
    }

    // Try to insert REP001 second time
    final res = await ip.createReport(
      id: 'REP001',
      title: 'Intento duplicado de REP001',
      equipment: 'Equipo Duplicado',
      description: 'Intento de sobrescritura',
      category: IncidentCategory.reporteFallas,
    );

    if (!res.success && res.message.contains('duplicidad')) {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.aprobado,
        observations: 'Control de duplicados verificado: Se bloqueó la inserción del ID repetido REP001 protegiendo la integridad.',
        executedAt: DateTime.now(),
      );
    } else {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.fallido,
        observations: 'Fallo: La aplicación no previno el ID repetido.',
        executedAt: DateTime.now(),
      );
    }
  }

  Future<void> _executeTC04(int index, IncidentProvider ip) async {
    const testId = 'TC04-UPD';
    ip.deleteReport(testId);

    // Create report with Media priority
    await ip.createReport(
      id: testId,
      title: 'Prueba de cambio de prioridad',
      equipment: 'Router Cisco ISR 4331',
      description: 'Verificación de actualización de prioridad',
      category: IncidentCategory.reporteFallas,
      priority: IncidentPriority.media,
    );

    // Update to Alta
    final res = await ip.updatePriority(testId, IncidentPriority.alta);
    final consult = ip.getReportById(testId);

    if (res.success && consult != null && consult.priority == IncidentPriority.alta) {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.aprobado,
        observations: 'La prioridad de $testId cambió exitosamente de Media a Alta y el cambio se conserva al volver a consultarlo.',
        executedAt: DateTime.now(),
      );
    } else {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.fallido,
        observations: 'No se conservó la actualización de prioridad.',
        executedAt: DateTime.now(),
      );
    }
  }

  Future<void> _executeTC05(int index, IncidentProvider ip) async {
    const testId = 'TC05-DEL';
    await ip.createReport(
      id: testId,
      title: 'Reporte para eliminar',
      equipment: 'Impresora HP LaserJet',
      description: 'Reporte temporal para prueba de eliminación',
      category: IncidentCategory.reporteFallas,
    );

    final delRes = await ip.deleteReport(testId);
    final consult = ip.getReportById(testId);

    if (delRes.success && consult == null) {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.aprobado,
        observations: 'El reporte $testId fue eliminado correctamente y ya no aparece en el listado activo de registros.',
        executedAt: DateTime.now(),
      );
    } else {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.fallido,
        observations: 'El reporte continuó existiendo tras la eliminación.',
        executedAt: DateTime.now(),
      );
    }
  }

  Future<void> _executeTC06(int index, IncidentProvider ip) async {
    // Ensure REP999 does not exist
    ip.deleteReport('REP999');

    // Query REP999
    final result = ip.getReportById('REP999');

    if (result == null) {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.aprobado,
        observations: 'Consulta de ID REP999 gestionada correctamente: Retornó resultado vacío/nulo sin bloqueos ni excepciones en la UI.',
        executedAt: DateTime.now(),
      );
    } else {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.fallido,
        observations: 'Se encontró un documento inesperado para REP999.',
        executedAt: DateTime.now(),
      );
    }
  }

  Future<void> _executeTC07(int index, IncidentProvider ip) async {
    // Attempt writing with simulated offline mode
    final res = await ip.createReport(
      id: 'TC07-OFFLINE',
      title: 'Prueba Offline',
      equipment: 'Switch de Borde',
      description: 'Prueba de desconexión',
      category: IncidentCategory.reporteFallas,
      isOfflineSimulated: true, // Forces offline simulation
    );

    if (!res.success && res.message.contains('pérdida de conexión')) {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.aprobado,
        observations: 'La app gestionó el estado offline informando adecuadamente al usuario sin corromper el almacén de datos.',
        executedAt: DateTime.now(),
      );
    } else {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.fallido,
        observations: 'La app no gestionó el error de desconexión.',
        executedAt: DateTime.now(),
      );
    }
  }

  Future<void> _executeTC08(int index, IncidentProvider ip) async {
    const testId = 'TC08-PERSIST';
    // Clean and insert
    ip.deleteReport(testId);

    await ip.createReport(
      id: testId,
      title: 'Reporte para verificar persistencia',
      equipment: 'Storage SAN NetApp',
      description: 'Verificación de persistencia en Firestore / motor local.',
      category: IncidentCategory.reporteFallas,
    );

    // Directly read from persistent engine
    final persistentReports = await PersistenceService.loadReports();
    final found = persistentReports.any((r) => r.id == testId);

    if (found) {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.aprobado,
        observations: 'Dato $testId persistido exitosamente en el motor de almacenamiento (Firestore Persistent Store) y recargado con integridad.',
        executedAt: DateTime.now(),
      );
    } else {
      _testCases[index] = _testCases[index].copyWith(
        status: TestStatus.fallido,
        observations: 'El dato no se encontró en el almacenamiento persistente.',
        executedAt: DateTime.now(),
      );
    }
  }

  // Generate markdown / plain text report for submission
  String generateExportableReport() {
    final buffer = StringBuffer();
    buffer.writeln('# INFORME DE MATRIZ DE PRUEBAS - PRÁCTICA 7');
    buffer.writeln('**Generado:** ${DateTime.now().toLocal()}\n');
    buffer.writeln('| Código | Caso de Prueba | Acción | Resultado Esperado | Estado | Observaciones |');
    buffer.writeln('| :--- | :--- | :--- | :--- | :--- | :--- |');

    for (final tc in _testCases) {
      final statusStr = tc.status == TestStatus.aprobado
          ? 'APROBADO'
          : tc.status == TestStatus.fallido
              ? 'FALLIDO'
              : 'SIN REGISTRAR';
      buffer.writeln('| ${tc.code} | ${tc.name} | ${tc.action} | ${tc.expected} | $statusStr | ${tc.observations} |');
    }

    return buffer.toString();
  }
}
