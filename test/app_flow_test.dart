// End-to-end flow test: signs in, browses all four tabs, changes a task
// status, checks the Team workload updates, and signs out again.
//
// Runs headless (no emulator), which is how these checks are verified on
// every `flutter test` run.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker_app/main.dart';
import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/screens/team_members_screen.dart';
import 'package:task_tracker_app/screens/task_details_screen.dart';
import 'package:task_tracker_app/screens/task_list_screen.dart';
import 'package:task_tracker_app/services/seed_data.dart';
import 'package:task_tracker_app/services/storage_service.dart';

void main() {
  testWidgets(
      'full flow: sign in, browse tabs, change status, workload updates, '
      'sign out', (WidgetTester tester) async {
    // Start with a fresh install and no saved session.
    SharedPreferences.setMockInitialValues({});
    await SeedData.seed(StorageService());

    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    // --- 1. First launch shows the Sign In screen. -----------------------
    expect(find.text('Choose who you are to continue.'), findsOneWidget);

    // --- 2. Pick Naomi and press Continue. -------------------------------
    await tester.tap(find.text('Naomi'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // --- 3. Dashboard is the home tab. -----------------------------------
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Hello, Alex'), findsOneWidget);

    // --- 4. Team tab shows the seed workload pills: ----------------------
    //      Naomi + Mitchell each have 1 Overdue, Cyuzuzo + Moses 1 At Risk.
    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();

    final team = find.byType(TeamMembersScreen);
    expect(
      find.descendant(of: team, matching: find.text('1 Overdue')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: team, matching: find.text('1 At Risk')),
      findsNWidgets(2),
    );

    // --- 5. Tasks tab: New Task is still a placeholder. ------------------
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    final taskList = find.byType(TaskListScreen);
    expect(
      find.descendant(of: taskList, matching: find.text('Search by title or assignee')),
      findsOneWidget,
    );

    await tester.tap(find.text('New Task'));
    await tester.pumpAndSettle();
    // The create flow is not built yet, so the app lands on the placeholder.
    expect(find.text('This screen is coming soon.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // --- 6. Open Naomi's overdue task and mark it Done. ------------------
    await tester
        .tap(find.descendant(of: taskList, matching: find.text('Fix login bug')));
    await tester.pumpAndSettle();

    final details = find.byType(TaskDetailsScreen);
    expect(find.descendant(of: details, matching: find.text('Overdue')),
        findsOneWidget);

    await tester.tap(
      find.descendant(of: details, matching: find.byType(DropdownButton<TaskStatus>)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done').last);
    await tester.pumpAndSettle();

    // The SLA card switches to Completed as soon as the status changes:
    // the chip no longer reads Overdue and the status field shows Done.
    expect(
      find.descendant(of: details, matching: find.text('Overdue')),
      findsNothing,
    );
    expect(
      find.descendant(of: details, matching: find.text('Done')),
      findsOneWidget,
    );

    // --- 7. Back to the list, then Team again: Naomi's overdue is gone, --
    //      so only Mitchell still shows 1 Overdue.--------------------------
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: team, matching: find.text('1 Overdue')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: team, matching: find.text('1 At Risk')),
      findsNWidgets(2),
    );

    // --- 8. Profile tab: summary and sign out. ---------------------------
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('My tasks'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();

    // Back on the Sign In screen with the session cleared.
    expect(find.text('Choose who you are to continue.'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}