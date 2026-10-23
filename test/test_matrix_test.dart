import 'package:flutter_test/flutter_test.dart';
import 'package:practica7/models/app_role.dart';
import 'package:practica7/models/incident_report.dart';
import 'package:practica7/models/test_case.dart';
import 'package:practica7/providers/chat_provider.dart';
import 'package:practica7/providers/incident_provider.dart';
import 'package:practica7/providers/test_matrix_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Matriz de Pruebas TC01 - TC08', () {
    test('TC01 - Alta válida: Almacena reporte con todos los campos correctos', () async {
      final ip = IncidentProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final res = await ip.createReport(
        id: 'TC01-UNIT',
        title: 'Alta válida unitaria',
        equipment: 'Servidor Postgres',
        description: 'Prueba de alta correcta',
        category: IncidentCategory.reporteFallas,
        priority: IncidentPriority.alta,
      );

      expect(res.success, isTrue);
      final query = ip.getReportById('TC01-UNIT');
      expect(query, isNotNull);
      expect(query!.equipment, equals('Servidor Postgres'));
    });

    test('TC02 - Campos vacíos: Rechaza reporte sin equipo o descripción', () async {
      final ip = IncidentProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final res = await ip.createReport(
        id: 'TC02-UNIT',
        title: 'Reporte incompleto',
        equipment: '',
        description: '',
        category: IncidentCategory.reporteFallas,
      );

      expect(res.success, isFalse);
      expect(res.message, contains('obligatorios'));
    });

    test('TC03 - Identificador repetido: Bloquea ID duplicado REP001', () async {
      final ip = IncidentProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // First insert
      await ip.createReport(
        id: 'REP001',
        title: 'Reporte base',
        equipment: 'Switch Cisco',
        description: 'Reporte primario',
        category: IncidentCategory.reporteFallas,
      );

      // Attempt second insert with REP001
      final res = await ip.createReport(
        id: 'REP001',
        title: 'Reporte duplicado',
        equipment: 'Otro equipo',
        description: 'Intento duplicado',
        category: IncidentCategory.reporteFallas,
      );

      expect(res.success, isFalse);
      expect(res.message, contains('duplicidad'));
    });

    test('TC04 - Actualización: Modifica prioridad de Media a Alta', () async {
      final ip = IncidentProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await ip.createReport(
        id: 'TC04-UNIT',
        title: 'Reporte para cambio de prioridad',
        equipment: 'Router Core',
        description: 'Validar cambio de prioridad',
        category: IncidentCategory.reporteFallas,
        priority: IncidentPriority.media,
      );

      final res = await ip.updatePriority('TC04-UNIT', IncidentPriority.alta);
      expect(res.success, isTrue);

      final query = ip.getReportById('TC04-UNIT');
      expect(query, isNotNull);
      expect(query!.priority, equals(IncidentPriority.alta));
    });

    test('TC05 - Eliminación: Elimina reporte y verifica que no aparezca activo', () async {
      final ip = IncidentProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await ip.createReport(
        id: 'TC05-UNIT',
        title: 'Reporte a borrar',
        equipment: 'Impresora',
        description: 'Borrado',
        category: IncidentCategory.reporteFallas,
      );

      final delRes = await ip.deleteReport('TC05-UNIT');
      expect(delRes.success, isTrue);

      final query = ip.getReportById('TC05-UNIT');
      expect(query, isNull);
    });

    test('TC06 - Documento inexistente: Consultar REP999 retorna nulo sin error', () async {
      final ip = IncidentProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final result = ip.getReportById('REP999');
      expect(result, isNull);
    });

    test('TC07 - Pérdida de conexión: Gestiona error offline durante escritura', () async {
      final ip = IncidentProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final res = await ip.createReport(
        id: 'TC07-UNIT',
        title: 'Escritura offline',
        equipment: 'Access Point',
        description: 'Pérdida de enlace',
        category: IncidentCategory.reporteFallas,
        isOfflineSimulated: true,
      );

      expect(res.success, isFalse);
      expect(res.message, contains('pérdida de conexión'));
    });

    test('TC08 - Persistencia: Guarda y recarga datos del motor estructurado', () async {
      final matrixProvider = TestMatrixProvider();
      final incidentProvider = IncidentProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      await matrixProvider.runTestCase('TC08', incidentProvider);

      final tc08 = matrixProvider.testCases.firstWhere((t) => t.code == 'TC08');
      expect(tc08.status, equals(TestStatus.aprobado));
      expect(tc08.observations, contains('persistido'));
    });

    test('Suite completa TestMatrixProvider: Ejecuta TC01 a TC08 y aprueba todos', () async {
      final matrixProvider = TestMatrixProvider();
      final incidentProvider = IncidentProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      await matrixProvider.runAllTests(incidentProvider);

      for (final tc in matrixProvider.testCases) {
        expect(tc.status, equals(TestStatus.aprobado),
            reason: '${tc.code} debe aprobar: ${tc.observations}');
      }
    });
  });

  group('Funcionalidades de Mensajería Requeridas', () {
    test('Evita envío de mensajes vacíos', () async {
      final cp = ChatProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final res = await cp.sendMessage(
        senderRole: AppRole.admin,
        receiverRole: AppRole.usuario1,
        text: '   ',
      );

      expect(res.success, isFalse);
      expect(res.message, contains('vacío'));
    });

    test('Envía mensaje con hora y actualiza contadores por dispositivo', () async {
      final cp = ChatProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final initialCount = cp.getMessageCountFor(AppRole.usuario1);

      final res = await cp.sendMessage(
        senderRole: AppRole.usuario1,
        receiverRole: AppRole.agente,
        text: 'Mensaje de prueba con marca de tiempo',
      );

      expect(res.success, isTrue);
      expect(res.createdMessage, isNotNull);
      expect(res.createdMessage!.formattedTime, isNotEmpty);
      expect(cp.getMessageCountFor(AppRole.usuario1), equals(initialCount + 1));
    });

    test('Botón limpiar historial vacía los mensajes', () async {
      final cp = ChatProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await cp.clearHistory();
      expect(cp.messages, isEmpty);
      expect(cp.totalMessagesCount, equals(0));
    });
  });
}
