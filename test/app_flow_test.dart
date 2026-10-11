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
import 'package:task_tracker_app/screens/create_edit_task_screen.dart';
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

    // --- 5. Tasks tab: the New Task form is wired in. ---------------------
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    final taskList = find.byType(TaskListScreen);
    expect(
      find.descendant(of: taskList, matching: find.text('Search by title or assignee')),
      findsOneWidget,
    );

    await tester.tap(find.text('New Task'));
    await tester.pumpAndSettle();
    // The real Create / Edit form opens (was a placeholder before merge).
    expect(find.byType(CreateEditTaskScreen), findsOneWidget);
    expect(find.text('Create task'), findsOneWidget);
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

  testWidgets(
      'create task: form validates, saves, and updates list and workload',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SeedData.seed(StorageService());

    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();

    // Sign in as Naomi and open the Tasks tab.
    await tester.tap(find.text('Naomi'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    // --- Open the New Task form. ----------------------------------------
    await tester.tap(find.text('New Task'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateEditTaskScreen), findsOneWidget);

    // --- Save with an empty title shows the first validation error. -----
    await tester.ensureVisible(find.text('Create task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title'), findsOneWidget);

    // --- Fill the form properly. ----------------------------------------
    await tester.ensureVisible(find.widgetWithText(TextFormField, 'Title'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'QA created task',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Naomi (Mobile Developer)').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // --- Save and confirm. ----------------------------------------------
    await tester.ensureVisible(find.text('Create task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();
    expect(find.text('Task created'), findsOneWidget);

    // Let the confirmation SnackBar dismiss, then open the Home tab. The
    // dashboard reloaded when the form closed and lists the newest task
    // first in Recent Tasks.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('QA created task'), findsWidgets);

    // --- Team workload reflects the new (At Risk) task. -----------------
    // Naomi's task is due today, so it is At Risk: the At Risk pills go
    // from two (Cyuzuzo, Moses) to three.
    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    final team = find.byType(TeamMembersScreen);
    expect(
      find.descendant(of: team, matching: find.text('1 At Risk')),
      findsNWidgets(3),
    );
    expect(
      find.descendant(of: team, matching: find.text('1 Overdue')),
      findsNWidgets(2),
    );

    expect(tester.takeException(), isNull);
  });
}