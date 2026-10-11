# Project & SLA Task Tracker

A Flutter mobile app that helps a small software team manage project tasks. Team members can create and edit tasks, assign them to each other, set priorities and deadlines, update status, and see overall project progress. Every task shows an SLA status, so the team can spot work that needs attention.

Built by Group 16 for ALU Formative Assignment 1.

## Features

| Screen | What it does |
| --- | --- |
| Sign In | Choose which team member you are. There is no password; the choice is remembered on the device. |
| Dashboard | Overall progress, a count of tasks in each SLA state, a Needs Attention list (Overdue first, then At Risk), and recent tasks. |
| Task List | Search by title or assignee, filter by SLA state or "My tasks", sorted so the most urgent tasks come first. |
| Task Details | Every field of a task, an SLA card that explains why the task has its status, a status dropdown that saves straight away, plus Edit and Delete. |
| Create / Edit Task | One form for both. Validates the title, description, assignee and due date before saving. |
| Team | The team members, how many tasks each one has, and an **At Risk / Overdue** pill for work that needs attention. New members can be added from here. |
| Profile | The signed-in member, a summary of their own tasks, and Sign out. |

## SLA status

The SLA status is calculated from a task's due date and status each time it is shown. It is never stored, so it can never be out of date. The rules are checked in this order:

| Status | Rule |
| --- | --- |
| Completed | The task's status is Done. |
| Overdue | Not Done, and the end of the due date (11:59 pm) has passed. |
| At Risk | Not Done, and the deadline is within the next 48 hours. |
| On Track | Everything else. |

The rules live in one place, `lib/services/sla_service.dart`. The 48-hour window is a named constant there.

## Team workload

The Team tab shows every member's total task count plus, in coloured pills, how many of their tasks are **At Risk** or **Overdue** — the same labels used by the SLA grid. Members with nothing flagged show **"All tasks on track"**, and members with no tasks show **"No tasks assigned"**. The counts come from the shared SLA rules and refresh when tasks change.

## Validation rules

The Create / Edit Task form checks:

- **Title:** required, 3 to 60 characters.
- **Description:** optional, at most 300 characters.
- **Assignee:** required.
- **Due date:** required, and not in the past for a new task.

The Add Team Member form checks:

- **Name:** required, 2 to 40 characters, and not the same as an existing member.
- **Role:** required, 2 to 40 characters.

Sign In shows an error if you continue without choosing a team member.

## Running the app

You need Flutter installed with Dart 3.12.2 or newer, and an Android emulator or a connected Android phone.

```
flutter pub get
flutter run
```

On first launch the app adds sample data: four team members and eight tasks, two in each SLA state.

To run the tests:

```
flutter test
```

## How it is built

- **State:** `setState()` only. Each screen is a `StatefulWidget` that holds its own state and reloads from storage when it needs fresh data.
- **Storage:** SharedPreferences. Tasks and team members are each saved as a list of JSON strings, using the models' `toMap` and `fromMap`. There is no backend.
- **Navigation:** a bottom navigation bar with four tabs (Home, Tasks, Team, Profile). Task Details and the task form open on top of the tabs with `Navigator.push`.
- **Theme:** one `ThemeData` in `lib/theme/app_theme.dart`, with colours, spacing and corner radius as named constants. IBM Plex Sans is bundled in `assets/fonts`, so the app needs no internet.

## Project structure

```
lib/
  main.dart                     App entry point: seeds sample data, sets up theme and routes
  models/
    task.dart                   Task, TaskPriority, TaskStatus
    team_member.dart            TeamMember
    sla_status.dart             The four SLA states
    workload_summary.dart       A member's task counts by SLA state
  services/
    storage_service.dart        Loads and saves tasks and members
    seed_data.dart              Sample data for the first launch
    session_service.dart        Remembers who is signed in
    sla_service.dart            SLA rules, deadline text and reason text
  screens/
    auth_gate.dart              Shows Sign In or the tabs
    sign_in_screen.dart
    main_shell.dart             Bottom navigation and tab switching
    dashboard_screen.dart
    task_list_screen.dart
    task_details_screen.dart
    create_edit_task_screen.dart
    team_members_screen.dart
    add_member_screen.dart
    profile_screen.dart
  widgets/
    member_avatar.dart          Avatar with a member's initials
  theme/
    app_theme.dart              Colours, spacing, text styles, component themes
    sla_colors.dart             Text and background colour for each SLA state
  utils/
    app_routes.dart             Route names
    date_format.dart            Date helpers
test/                           Tests for the SLA rules, storage, seed data and screens
```

## Team

| Member | GitHub | Branch | Main contributions |
| --- | --- | --- | --- |
| Mitchell | MitchellBarure | `mitchell` | Models, theme and fonts, navigation, Sign In, Profile, Create / Edit Task form |
| Cyuzuzo | cyuzuzogermain | `germain` | SLA service, Dashboard, Task List, Task Details |
| Naomi | Ladecodes1 | `naomi` | Storage service, Team screen |
| Moses | mugishamoses | `moses` | Seed data, storage error handling, team workload, tests |

## How we work

- Each member works on their own branch.
- Nobody pushes directly to `main`. Work is merged through pull requests reviewed by a teammate.
- Commits are small, with messages that say what changed.

## Limitations

- Data is stored on one device only and is not shared between phones.
- Sign In is a local choice of user, not real authentication.

## Font licence

IBM Plex Sans is used under the SIL Open Font License. The licence text is in `assets/fonts/OFL.txt`.
