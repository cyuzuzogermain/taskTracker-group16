import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'screens/placeholder_screen.dart';
import 'theme/app_theme.dart';
import 'utils/app_routes.dart';

void main() {
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
        AppRoutes.home: (context) => const AuthGate(),
        AppRoutes.createTask: (context) =>
            const PlaceholderScreen(title: 'New Task'),
      },
    );
  }
}
