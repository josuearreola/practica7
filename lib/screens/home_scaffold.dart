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
        // Detect role from URL hash or query if on Web
        final uri = Uri.base;
        final hashOrFragment = uri.fragment;
        final queryRole = uri.queryParameters['role'] ?? uri.queryParameters['device'];

        if (hashOrFragment.isNotEmpty) {
          final detected = AppRole.fromString(hashOrFragment);
          context.read<AppStateProvider>().setRole(detected);
        } else if (queryRole != null) {
          final detected = AppRole.fromString(queryRole);
          context.read<AppStateProvider>().setRole(detected);
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
                    'Práctica 7: Mensajería, Archivos y Roles por URL',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Sistema de Casos de Atención, Fallas y Mesa de Ayuda',
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
          // 4 Connected Devices Banner & Status Bar
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
