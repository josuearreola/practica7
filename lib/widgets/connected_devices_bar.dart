import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_role.dart';
import '../providers/app_state_provider.dart';
import '../providers/chat_provider.dart';
import '../services/render_service.dart';
import 'preassigned_urls_dialog.dart';

class ConnectedDevicesBar extends StatelessWidget {
  const ConnectedDevicesBar({super.key});

  void _showRenderConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: RenderService.serverUrl);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131B2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          title: const Row(
            children: [
              Icon(Icons.cloud_sync_rounded, color: Color(0xFF38BDF8)),
              SizedBox(width: 10),
              Text(
                'Servidor Render (Internet)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conecta los 4 dispositivos a través del backend desplegado en Render.com para mensajería y sincronización remota:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'URL del backend en Render',
                    hintText: 'https://mi-practica7.onrender.com o http://localhost:3000',
                    prefixIcon: Icon(Icons.language_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: RenderService.connectionState == RenderConnectionState.connected
                              ? const Color(0xFF10B981)
                              : RenderService.connectionState == RenderConnectionState.connecting
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Estado actual: ${RenderService.connectionState == RenderConnectionState.connected ? 'Conectado a Render' : RenderService.connectionState == RenderConnectionState.connecting ? 'Conectando...' : 'Desconectado'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              onPressed: () async {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  await RenderService.updateServerUrl(newUrl);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Servidor Render actualizado: $newUrl'),
                        backgroundColor: const Color(0xFF0284C7),
                      ),
                    );
                  }
                }
              },
              child: const Text('Guardar y Reconectar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final currentRole = appState.currentRole;
    final counters = chatProvider.allDeviceCounters;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Active device role badge, URL button, Render status, and controls
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Active Device Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: currentRole.primaryColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: currentRole.primaryColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: currentRole.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: currentRole.primaryColor.withOpacity(0.8),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ESTE DISPOSITIVO: ${currentRole.deviceName.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: currentRole.primaryColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '/#${currentRole.routePath}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Render Server Status & Config Button
                    Tooltip(
                      message: 'Configurar servidor backend en Render.com',
                      child: InkWell(
                        onTap: () => _showRenderConfigDialog(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: RenderService.connectionState == RenderConnectionState.connected
                                      ? const Color(0xFF10B981)
                                      : RenderService.connectionState == RenderConnectionState.connecting
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                RenderService.connectionState == RenderConnectionState.connected
                                    ? 'Render: Conectado'
                                    : RenderService.connectionState == RenderConnectionState.connecting
                                        ? 'Render: Conectando...'
                                        : 'Render: Configurar',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.settings_outlined, size: 12, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Button to inspect all 4 preassigned URLs
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => PreassignedUrlsDialog(appState: appState),
                        );
                      },
                      icon: const Icon(Icons.hub_outlined, size: 16, color: Color(0xFF818CF8)),
                      label: Text(
                        isCompact ? 'URLs Roles' : 'Ver 4 URLs Preasignadas',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Offline simulation toggle (TC07)
                    Tooltip(
                      message: appState.isOfflineSimulated
                          ? 'Simulación de desconexión activa (TC07). Clic para reconectar.'
                          : 'Simular pérdida de conexión para prueba TC07',
                      child: InkWell(
                        onTap: () => appState.toggleOfflineSimulation(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: appState.isOfflineSimulated
                                ? const Color(0xFFEF4444).withOpacity(0.2)
                                : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: appState.isOfflineSimulated
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                appState.isOfflineSimulated ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                                size: 14,
                                color: appState.isOfflineSimulated
                                    ? const Color(0xFFF87171)
                                    : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                appState.isOfflineSimulated ? 'OFFLINE (TC07)' : 'RED OK',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: appState.isOfflineSimulated
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Agent Presence Toggle (Only shown to Admin or Agent)
                    if (currentRole == AppRole.admin || currentRole == AppRole.agente) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: appState.isAgentConnected
                            ? 'Simular desconexión del Agente (Reasigna casos al Admin)'
                            : 'Reconectar Agente de Atención',
                        child: ElevatedButton.icon(
                          onPressed: () => appState.toggleAgentConnection(),
                          icon: Icon(
                            appState.isAgentConnected
                                ? Icons.power_settings_new_rounded
                                : Icons.refresh_rounded,
                            size: 14,
                          ),
                          label: Text(
                            appState.isAgentConnected ? 'Desconectar Agente' : 'Conectar Agente',
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appState.isAgentConnected
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF059669),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Device Status and Message Counters Strip
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: AppRole.values.map((role) {
                  final isCurrent = currentRole == role;
                  final isOnline = appState.isDeviceOnline(role);
                  final msgCount = counters[role] ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? role.primaryColor.withOpacity(0.15)
                          : const Color(0xFF1E293B).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? role.primaryColor.withOpacity(0.6)
                            : const Color(0xFF334155),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          role.shortDeviceName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$msgCount msgs',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
