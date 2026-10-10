# Project & SLA Task Tracker

A Flutter mobile app that helps a small software team manage project tasks: create and edit tasks, assign them to team members, set priorities and deadlines, update status, and see overall progress. Every task shows an SLA status so the team can spot work that needs attention.

Built by Group 16 for ALU Formative Assignment 1.

> This project is in active development. Sections below will be filled in as features are merged.

## SLA status

The SLA status is calculated from a task's due date and status each time it is shown. It is never stored. The rules are checked in this order:

| Status | Rule |
| --- | --- |
| Completed | The task's status is Done. |
| Overdue | Not Done, and the end of the due date (11:59 pm) has passed. |
| At Risk | Not Done, and due within the next 48 hours. |
| On Track | Everything else. |

## Running the app

You need Flutter installed with Dart 3.12.2 or newer, and an Android emulator or a connected Android phone.

```
flutter pub get
flutter run
```

## Project structure

```
lib/
  main.dart     App entry point
  models/       Data classes: Task, TeamMember, SlaStatus
  services/     Local storage and SLA rules
  screens/      One file per screen
  widgets/      Reusable widgets shared between screens
  theme/        Colours, fonts and the app theme
  utils/        Small helper functions
```

## Data storage

Tasks and team members are saved on the device with SharedPreferences, as JSON. There is no backend.

## How we work

- Each member works on a branch named after them.
- Nobody pushes directly to `main`. Work is merged through reviewed pull requests.
- Commits are small, with messages that say what changed.
