import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_role.dart';
import 'providers/app_state_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/test_matrix_provider.dart';
import 'screens/home_scaffold.dart';
import 'services/render_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SyncService.startPolling();
  await RenderService.init();
  runApp(const Practica7App());
}

class Practica7App extends StatelessWidget {
  const Practica7App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => TestMatrixProvider()),
      ],
      child: MaterialApp(
        title: 'Práctica 7 - Mensajería, Archivos y Roles por URL',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // Route generator for preassigned URLs:
        // /admin, /agente, /usuario1, /usuario2
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          final path = uri.path;

          AppRole? matchedRole;
          if (path.contains('admin')) {
            matchedRole = AppRole.admin;
          } else if (path.contains('agente') || path.contains('agent')) {
            matchedRole = AppRole.agente;
          } else if (path.contains('usuario1') || path.contains('user1')) {
            matchedRole = AppRole.usuario1;
          } else if (path.contains('usuario2') || path.contains('user2')) {
            matchedRole = AppRole.usuario2;
          }

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => HomeScaffold(initialRole: matchedRole),
          );
        },
        home: const HomeScaffold(),
      ),
    );
  }
}
