// Basic smoke test for the Dashboard screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker_app/main.dart';
import 'package:task_tracker_app/services/seed_data.dart';
import 'package:task_tracker_app/services/storage_service.dart';

void main() {
  testWidgets('Dashboard shows the seeded overview', (WidgetTester tester) async {
    // Seed the same sample data the app seeds on startup, so the dashboard
    // has tasks to show instead of its empty state.
    SharedPreferences.setMockInitialValues({});
    await SeedData.seed(StorageService(), now: DateTime(2026, 1, 1, 10));

    // Sign in as a seeded member, so the app opens on the tabs instead of
    // the Sign In screen.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', '4');

    // Build our app and let the screens finish loading their data.
    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    // Verify the main dashboard sections appear.
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Hello, Alex'), findsOneWidget);
    expect(find.text('Project & SLA Task Tracker'), findsOneWidget);
    expect(find.text('SLA Summary'), findsOneWidget);
    expect(find.text('Recent Tasks'), findsOneWidget);
  });
}
