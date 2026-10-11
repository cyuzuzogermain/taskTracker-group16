import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker_app/screens/team_members_screen.dart';
import 'package:task_tracker_app/services/seed_data.dart';
import 'package:task_tracker_app/services/storage_service.dart';

void main() {
  testWidgets('shows the member list with a workload count each',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SeedData.seed(StorageService(), now: DateTime(2026, 1, 1, 10));

    await tester.pumpWidget(const MaterialApp(home: TeamMembersScreen()));
    await tester.pumpAndSettle();

    // Everyone is listed once.
    expect(find.text('Naomi'), findsOneWidget);
    expect(find.text('Cyuzuzo'), findsOneWidget);
    expect(find.text('Moses'), findsOneWidget);
    expect(find.text('Mitchell'), findsOneWidget);

    // Workload counts come from the sample tasks:
    // Naomi 2, Cyuzuzo 3, Moses 1, Mitchell 2.
    expect(find.text('3 tasks'), findsOneWidget);
    expect(find.text('2 tasks'), findsNWidgets(2));
    expect(find.text('1 task'), findsOneWidget);
  });
}
