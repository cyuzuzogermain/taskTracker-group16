import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'screens/placeholder_screen.dart';
import 'services/seed_data.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_routes.dart';

Future<void> main() async {
  // Storage uses a platform channel, so make sure the Flutter bindings are
  // ready before touching it.
  WidgetsFlutterBinding.ensureInitialized();

  // Seed the sample data once, before the first screen reads from storage.
  await SeedData.seed(StorageService());

  runApp(const TaskTrackerApp());
}

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project & SLA Task Tracker',
      theme: AppTheme.light(),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (context) => const MainShell(),
        AppRoutes.createTask: (context) =>
            const PlaceholderScreen(title: 'New Task'),
      },
    );
  }
}
