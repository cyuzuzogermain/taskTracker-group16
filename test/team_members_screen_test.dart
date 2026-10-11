import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker_app/screens/team_members_screen.dart';
import 'package:task_tracker_app/services/seed_data.dart';
import 'package:task_tracker_app/services/storage_service.dart';

void main() {
  testWidgets('shows each member with total and At Risk / Overdue counts',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Seed relative to the real clock so the SLA states match what the
    // screen computes when it builds.
    await SeedData.seed(StorageService());

    await tester.pumpWidget(const MaterialApp(home: TeamMembersScreen()));
    await tester.pumpAndSettle();

    // Everyone is listed once.
    expect(find.text('Naomi'), findsOneWidget);
    expect(find.text('Cyuzuzo'), findsOneWidget);
    expect(find.text('Moses'), findsOneWidget);
    expect(find.text('Mitchell'), findsOneWidget);

    // Totals: Naomi 2, Cyuzuzo 3, Moses 1, Mitchell 2.
    expect(find.text('3 tasks'), findsOneWidget);
    expect(find.text('2 tasks'), findsNWidgets(2));
    expect(find.text('1 task'), findsOneWidget);

    // Risk breakdown from the sample data:
    // Naomi and Mitchell each have 1 overdue task;
    // Cyuzuzo and Moses each have 1 task at risk.
    expect(find.text('1 Overdue'), findsNWidgets(2));
    expect(find.text('1 At Risk'), findsNWidgets(2));
  });
}
