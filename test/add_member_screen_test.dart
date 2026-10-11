import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_tracker_app/screens/add_member_screen.dart';
import 'package:task_tracker_app/screens/team_members_screen.dart';
import 'package:task_tracker_app/services/seed_data.dart';
import 'package:task_tracker_app/services/storage_service.dart';

/// Finds a text field by its label.
Finder field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  /// Opens the Team screen with the sample data, then the Add Member form.
  Future<void> openAddMember(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SeedData.seed(StorageService());

    await tester.pumpWidget(const MaterialApp(home: TeamMembersScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add member'));
    await tester.pumpAndSettle();
    expect(find.byType(AddMemberScreen), findsOneWidget);
  }

  testWidgets('empty form shows both required errors and saves nothing',
      (WidgetTester tester) async {
    await openAddMember(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Add member'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter a role'), findsOneWidget);
    expect((await StorageService().loadTeamMembers()).length, 4);
  });

  testWidgets('rejects a name that is too short or already used',
      (WidgetTester tester) async {
    await openAddMember(tester);

    await tester.enterText(field('Name'), 'A');
    await tester.enterText(field('Role'), 'Designer');
    await tester.tap(find.widgetWithText(FilledButton, 'Add member'));
    await tester.pumpAndSettle();
    expect(find.text('Name must be at least 2 characters'), findsOneWidget);

    // The check ignores capital letters and spaces around the name.
    await tester.enterText(field('Name'), '  naomi ');
    await tester.pumpAndSettle();
    expect(
      find.text('A team member with this name already exists'),
      findsOneWidget,
    );
    expect((await StorageService().loadTeamMembers()).length, 4);
  });

  testWidgets('a valid member is saved and appears on the Team screen',
      (WidgetTester tester) async {
    await openAddMember(tester);

    await tester.enterText(field('Name'), '  Amina Yusuf ');
    await tester.enterText(field('Role'), 'UI Designer');
    await tester.tap(find.widgetWithText(FilledButton, 'Add member'));
    await tester.pumpAndSettle();

    // Back on the Team screen, with the new member listed.
    expect(find.byType(AddMemberScreen), findsNothing);
    expect(find.text('Amina Yusuf added to the team'), findsOneWidget);
    expect(find.text('Amina Yusuf'), findsOneWidget);
    expect(find.text('UI Designer'), findsOneWidget);
    expect(find.text('No tasks assigned'), findsOneWidget);

    // Saved with the name trimmed and a unique id.
    final members = await StorageService().loadTeamMembers();
    expect(members.length, 5);
    expect(members.last.name, 'Amina Yusuf');
    expect(members.last.role, 'UI Designer');
    expect(members.map((m) => m.id).toSet().length, 5);
  });

  testWidgets('closing the form without saving adds nobody',
      (WidgetTester tester) async {
    await openAddMember(tester);

    await tester.enterText(field('Name'), 'Not Saved');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(TeamMembersScreen), findsOneWidget);
    expect((await StorageService().loadTeamMembers()).length, 4);
  });
}
