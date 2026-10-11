// Headless layout checks that stand in for the on-device pass:
//   * every screen renders at small phone sizes and in landscape (rotation),
//   * long task titles never cause a RenderFlex overflow,
//   * a long title on the Task Details screen is handled by its AppBar.
//
// An overflow in a widget test shows up as a FlutterError, so each step
// asserts no exception was reported.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker_app/main.dart';
import 'package:task_tracker_app/models/task.dart';
import 'package:task_tracker_app/models/team_member.dart';
import 'package:task_tracker_app/screens/task_details_screen.dart';
import 'package:task_tracker_app/services/seed_data.dart';
import 'package:task_tracker_app/services/storage_service.dart';
import 'package:task_tracker_app/theme/app_theme.dart';

const _longTitle =
    'This task title is deliberately extremely long so that the layout has '
    'to wrap it or truncate it instead of overflowing the edges of the '
    'screen sideways';

void main() {
  // The sizes engineers actually test in small-screen and rotation passes.
  const viewports = <String, Size>{
    'small portrait (320x568)': Size(320, 568),
    'compact portrait (360x640)': Size(360, 640),
    'standard portrait (411x914)': Size(411, 914),
    'small landscape (568x320)': Size(568, 320),
    'compact landscape (640x360)': Size(640, 360),
  };

  for (final entry in viewports.entries) {
    testWidgets('app tabs have no overflow - ${entry.key}',
        (WidgetTester tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({'current_user_id': '1'});
      await SeedData.seed(StorageService());

      await tester.pumpWidget(const TaskTrackerApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Visit every tab so each screen lays out at this size.
      for (final tab in ['Home', 'Tasks', 'Team', 'Profile']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'overflow while showing the $tab tab');
      }
    });

    testWidgets('long-title task details have no overflow - ${entry.key}',
        (WidgetTester tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      await SeedData.seed(StorageService());

      final task = Task(
        id: 'long-title',
        title: _longTitle,
        assigneeId: '1',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        priority: TaskPriority.low,
        notes: 'Some lengthy notes about this task. ' * 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: TaskDetailsScreen(
          task: task,
          members: const [
            TeamMember(id: '1', name: 'Naomi', role: 'Mobile Developer'),
          ],
          onSave: (_) async {},
          onDelete: (_) async {},
          onEdit: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      // Opening the delete dialog also renders the long title in the message.
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('long task titles in the lists are truncated, not overflowing',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'current_user_id': '1'});
    final storage = StorageService();
    await SeedData.seed(storage);

    // Add a long-title task (due today so it shows in Needs Attention too).
    final tasks = await storage.loadTasks();
    tasks.add(Task(
      id: 'long-list-task',
      title: _longTitle,
      assigneeId: '2',
      dueDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    await storage.saveTasks(tasks);

    await tester.pumpWidget(const TaskTrackerApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Long titles in tiles use maxLines + ellipsis, so they never push a
    // tile wider than the screen. The dashboard builds every tile eagerly,
    // so its copy of the long title is always in the tree.
    final tile = find.text(_longTitle).first;
    expect(tester.getRect(tile).width, lessThanOrEqualTo(320));

    // The Task List tab also handles the long title without overflowing.
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}