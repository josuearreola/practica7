import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_role.dart';
import '../providers/app_state_provider.dart';
import '../widgets/connected_devices_bar.dart';
import 'chat_view.dart';
import 'test_matrix_view.dart';
import 'tickets_view.dart';

class HomeScaffold extends StatefulWidget {
  final AppRole? initialRole;

  const HomeScaffold({super.key, this.initialRole});

  @override
  State<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends State<HomeScaffold> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialRole != null) {
        context.read<AppStateProvider>().setRole(widget.initialRole!);
      } else {
        // Detect role from URL hash or query if on Web, or request dynamic turn
        final uri = Uri.base;
        final hashOrFragment = uri.fragment;
        final queryRole = uri.queryParameters['role'] ?? uri.queryParameters['device'];

        if (hashOrFragment.isNotEmpty) {
          final detected = AppRole.fromString(hashOrFragment);
          context.read<AppStateProvider>().setRole(detected);
        } else if (queryRole != null) {
          final detected = AppRole.fromString(queryRole);
          context.read<AppStateProvider>().setRole(detected);
        } else {
          // Automatic dynamic turn request (1st: Admin, 2nd: Soporte, 3rd: Usuario 1, 4th: Usuario 2)
          context.read<AppStateProvider>().requestTurnOrRole();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final currentRole = appState.currentRole;

    // VALIDACIÓN CRÍTICA: Desconexión del Administrador -> Cierre de Sesión General
    if (appState.isAdminDisconnectedSessionTerminated) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF131B2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    blurRadius: 36,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.no_accounts_rounded,
                      size: 64,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SESIÓN CERRADA A TODOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Validación: El Administrador se ha desconectado',
                      style: TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    appState.terminationReason ??
                        'Por validación de seguridad de la práctica, cuando el Administrador se desconecta se desocupan y cierran automáticamente las sesiones de todos los dispositivos (Soporte y Usuarios).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Color(0xFF38BDF8)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'El primer dispositivo en reconectarse tomará el rol de nuevo Administrador (Turno 1).',
                            style: TextStyle(fontSize: 12, color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text(
                        'Reconectar y Tomar Turno Disponible',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        appState.requestTurnOrRole();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // PANTALLA: Dispositivo en Sala de Espera de Turno (si los 4 están llenos)
    if (currentRole == AppRole.espera) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        appBar: AppBar(
          backgroundColor: const Color(0xFF131B2E),
          title: const Text('Sala de Espera de Turno - Práctica 7'),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF475569)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 54, color: Color(0xFFF59E0B)),
                const SizedBox(height: 16),
                const Text(
                  'En Espera de Turno Disponible',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Actualmente los 4 roles (Administrador, Soporte, Usuario 1 y Usuario 2) están ocupados por otros dispositivos físicos.\n\nEn cuanto uno de los dispositivos se desconecte, se te asignará su rol automáticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Comprobar Turnos Libres Ahora'),
                  onPressed: () {
                    appState.requestTurnOrRole();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131B2E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [currentRole.primaryColor, const Color(0xFF38BDF8)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hub_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Práctica 7: Asignación por Turnos y Mensajería',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Turnos Automáticos: 1° Admin ➔ 2° Soporte ➔ 3° y 4° Usuarios',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: currentRole.primaryColor,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(
              icon: Icon(Icons.forum_outlined, size: 18),
              text: 'Mensajería y Archivos',
            ),
            const Tab(
              icon: Icon(Icons.assignment_outlined, size: 18),
              text: 'Casos y Reportes',
            ),
            Tab(
              icon: Icon(
                currentRole.canAccessTestMatrix ? Icons.verified_outlined : Icons.lock_outline,
                size: 18,
              ),
              text: currentRole.canAccessTestMatrix
                  ? 'Matriz de Pruebas (TC01-TC08)'
                  : 'Matriz (Sólo Admin/Agente)',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 4 Connected Devices Banner & Status Bar with turn indicators
          const ConnectedDevicesBar(),

          // System Alerts Banner (Agent Disconnection / Offline Mode)
          if (appState.lastSystemAlert != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: appState.isAgentConnected && !appState.isOfflineSimulated
                  ? const Color(0xFF065F46)
                  : const Color(0xFF7F1D1D),
              child: Row(
                children: [
                  Icon(
                    appState.isAgentConnected && !appState.isOfflineSimulated
                        ? Icons.info_outline
                        : Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      appState.lastSystemAlert!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onPressed: () => appState.clearAlert(),
                  ),
                ],
              ),
            ),

          // Main Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                ChatView(),
                TicketsView(),
                TestMatrixView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
