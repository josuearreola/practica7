import '../models/app_role.dart';
import '../models/chat_attachment.dart';
import '../models/chat_message.dart';
import '../models/incident_report.dart';

class MockData {
  static List<IncidentReport> getInitialReports() {
    final now = DateTime.now();
    return [
      IncidentReport(
        id: 'REP001',
        title: 'Caída de servicio en base de datos productiva',
        equipment: 'Servidor Dell PowerEdge R740',
        description: 'El servicio PostgreSQL no responde tras el reinicio automático de mantenimiento. Los usuarios no pueden consultar inventario.',
        category: IncidentCategory.reporteFallas,
        priority: IncidentPriority.critica,
        status: IncidentStatus.enAtencion,
        assignedRole: AppRole.agente,
        reportedByRole: AppRole.usuario1,
        createdAt: now.subtract(const Duration(hours: 2, minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
        resolutionNotes: 'Agente analizando logs de Postgres y estado de memoria RAM.',
      ),
      IncidentReport(
        id: 'REP002',
        title: 'Bloqueo de credenciales y acceso perdido a nómina',
        equipment: 'Portal ERP Financiero Web',
        description: 'Usuario 2 bloqueó su cuenta tras 3 intentos fallidos con token caducado. Requiere reseteo con autorización de Administrador.',
        category: IncidentCategory.solucionAccesosPerdidos,
        priority: IncidentPriority.alta,
        status: IncidentStatus.escaladoAdmin,
        assignedRole: AppRole.admin,
        reportedByRole: AppRole.usuario2,
        isDirectToAdmin: true,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 40)),
        updatedAt: now.subtract(const Duration(minutes: 10)),
        resolutionNotes: 'Solicitud directa enviada al Administrador debido a permisos de seguridad.',
      ),
      IncidentReport(
        id: 'REP003',
        title: 'Intermitencia de enlace y túnel VPN corporativo',
        equipment: 'Firewall Fortinet FortiGate 100F',
        description: 'Desconexiones frecuentes del cliente FortiClient en la subred de desarrollo. Pérdida de paquetes del 40%.',
        category: IncidentCategory.reporteFallas,
        priority: IncidentPriority.media,
        status: IncidentStatus.abierto,
        assignedRole: AppRole.agente,
        reportedByRole: AppRole.usuario1,
        createdAt: now.subtract(const Duration(minutes: 45)),
        updatedAt: now.subtract(const Duration(minutes: 45)),
      ),
      IncidentReport(
        id: 'REP004',
        title: 'Solicitud de alta de buzón y permisos para nuevo integrante',
        equipment: 'Microsoft 365 / Directorio Activo',
        description: 'Proceso de incorporación de analista financiero. Se requiere creación de buzón compartido y acceso a carpeta de auditoría.',
        category: IncidentCategory.procesoAtencion,
        priority: IncidentPriority.baja,
        status: IncidentStatus.enAtencion,
        assignedRole: AppRole.agente,
        reportedByRole: AppRole.usuario2,
        createdAt: now.subtract(const Duration(minutes: 20)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  static List<ChatMessage> getInitialMessages() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'msg-001',
        senderRole: AppRole.admin,
        senderDeviceName: AppRole.admin.deviceName,
        receiverRole: null, // Broadcast
        text: 'Sistema de Mesa de Ayuda y Mensajería inicializado. Dispositivos conectados y listos para recepción de reportes.',
        timestamp: now.subtract(const Duration(minutes: 25)),
      ),
      ChatMessage(
        id: 'msg-002',
        senderRole: AppRole.usuario1,
        senderDeviceName: AppRole.usuario1.deviceName,
        receiverRole: AppRole.agente,
        receiverDeviceName: AppRole.agente.deviceName,
        text: 'Hola Agente, acabo de registrar el reporte REP001 del servidor R740. Adjunto la captura de pantalla con el volcado de error.',
        attachment: ChatAttachment.testSamples[0],
        timestamp: now.subtract(const Duration(minutes: 18)),
      ),
      ChatMessage(
        id: 'msg-003',
        senderRole: AppRole.agente,
        senderDeviceName: AppRole.agente.deviceName,
        receiverRole: AppRole.usuario1,
        receiverDeviceName: AppRole.usuario1.deviceName,
        text: 'Enterado Usuario 1. Estoy revisando la traza del error en la base de datos para restablecer el servicio a la brevedad.',
        timestamp: now.subtract(const Duration(minutes: 12)),
      ),
      ChatMessage(
        id: 'msg-004',
        senderRole: AppRole.usuario2,
        senderDeviceName: AppRole.usuario2.deviceName,
        receiverRole: AppRole.admin,
        receiverDeviceName: AppRole.admin.deviceName,
        text: 'Estimado Administrador, generé el ticket REP002 por acceso bloqueado a nómina. ¿Podría verificar mis credenciales?',
        attachment: ChatAttachment.testSamples[1],
        timestamp: now.subtract(const Duration(minutes: 6)),
      ),
    ];
  }
}
