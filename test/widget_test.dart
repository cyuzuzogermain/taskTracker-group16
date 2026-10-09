// Basic smoke test for the Dashboard screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:task_tracker_app/main.dart';

void main() {
  testWidgets('Dashboard screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TaskTrackerApp());

    // Verify that the Dashboard title appears.
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Hello, Alex'), findsOneWidget);
    expect(find.text('Project & SLA Task Tracker'), findsOneWidget);
    expect(find.text('SLA Summary'), findsOneWidget);
    expect(find.text('Recent Tasks'), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
  });
}
