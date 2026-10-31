# Project-Todo — Spec v0.1

Personal Android app. Single user, single phone, fully offline. No accounts, no sync, no server.

## 1. Platform and stack

- Flutter, Android only. Min SDK 26 (Android 8.0), target latest stable.
- Storage: SQLite via `drift`.
- State: `flutter_riverpod`.
- Calendar UI: `table_calendar`.
- Alarms: `flutter_local_notifications` with `zonedSchedule` and exact alarm mode, plus `timezone` and `flutter_timezone`. Timezone is the phone's local zone (Europe/London).
- Money stored as integer pence. Display as GBP (£1,234.56).

## 2. Navigation

Bottom navigation bar, four tabs:

1. Today (opens by default)
2. Calendar
3. Projects
4. Ledger

## 3. Tasks

A task is the single unit shown in Today, Calendar and Projects. A task may belong to a project or be standalone.

### Fields

| Field | Type | Notes |
|---|---|---|
| id | int | |
| projectId | int, nullable | null = standalone task |
| title | text | required |
| notes | text | optional |
| priority | enum: red, orange, green | default green |
| dueDate | date, nullable | null = undated, not shown in Calendar or Today |
| dueTime | time, nullable | |
| alarm | bool | only allowed when dueDate and dueTime are set |
| recurrence | enum: none, daily, weekly, monthly | weekly = same weekday, monthly = same day of month |
| done | bool | |
| doneAt | datetime, nullable | |
| createdAt | datetime | |

### Recurrence

- Only one instance of a recurring task exists at a time.
- When it is marked done, the app records the completion and creates the next instance with the next due date. Its alarm is scheduled.
- Monthly on the 29th–31st falls back to the last day of shorter months.

### Alarms

- Fire at the due time exactly.
- High-priority notification with sound and vibration, shown on the lock screen.
- Notification actions: Done, Snooze 10 min.
- Tapping the notification opens the task.
- Editing or deleting a task reschedules or cancels its alarm.
- On app start, all future alarms are rescheduled from the database, as a safety net after reboot or app update.

### Task editor

One screen used from all tabs: title, notes, priority (three coloured buttons), project picker (including "None"), date, time, alarm toggle, recurrence.

## 4. Today tab

- Section "Overdue": undone tasks with dueDate before today.
- Section "Today": undone tasks due today.
- Section "Done today": tasks completed today, collapsed by default.
- Sort within sections: priority (red, orange, green), then due time, then untimed last.
- Each row: priority colour bar, title, time, project name. Tap checkbox to complete. Tap row to edit.
- Add button creates a task due today.
- Header shows date and count of tasks left today.

## 5. Calendar tab

- Month grid.
- Each day shows up to three dots coloured by the priority of its undone tasks.
- Tapping a day lists that day's tasks below the grid, sorted as in Today.
- Add button creates a task on the selected day.
- Recurring tasks show only their current instance. Future repeats are not drawn.

## 6. Projects tab

- List of projects: name, count of open tasks, count of red tasks.
- Project screen: open tasks sorted by priority then due date. Completed tasks are in a collapsed section.
- Add, rename, archive and delete projects. Deleting a project asks whether to delete its tasks or make them standalone.
- Archived projects are hidden behind a toggle. Their tasks do not appear in Today or Calendar.

### Project fields

id, name, archived (bool), createdAt.

## 7. Ledger tab

Separate from tasks and projects. No links between them.

### Entry fields

| Field | Type | Notes |
|---|---|---|
| id | int | |
| date | date | default today |
| amountPence | int | always positive |
| direction | enum: in, out | |
| category | enum: personal, business | |
| note | text | optional |

### Screen

- Totals at the top: Personal, Business, All. Each total = sum(in) − sum(out).
- Month selector (default: all time). When a month is selected, the totals and list cover that month only.
- List newest first: date, note, category tag, amount (green for in, red for out).
- Add, edit and delete entries. Delete asks for confirmation.

## 8. Backup

- Settings screen (gear icon on Today header).
- Export: writes all data to one JSON file and opens the Android share sheet.
- Import: file picker. Replaces all data after confirmation, then reschedules alarms.

## 9. Permissions and first run

- `POST_NOTIFICATIONS` (Android 13+): requested on first run.
- `SCHEDULE_EXACT_ALARM` (Android 12) and `USE_EXACT_ALARM` (Android 13+).
- `RECEIVE_BOOT_COMPLETED` for the notification plugin's reboot receiver.
- First run screen explains the permissions and offers a button to open the battery optimisation settings for the app.
- Settings screen shows the status of each permission with a button to fix it.

## 10. Build and release

- Repo: `bertie203/Project-Todo`.
- GitHub Actions workflow on push to `main`:
  1. Set up Java and Flutter stable.
  2. `flutter test`.
  3. `flutter build apk --release`.
  4. Sign with a fixed release keystore from repo secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
  5. Create a GitHub Release tagged `build-<run number>` with the APK attached.
- versionCode = workflow run number. versionName = `0.1.<run number>`.
- The keystore is generated once. It is not committed to the repo. A copy is kept outside GitHub. Losing it means the next build cannot install over the old one.

## 11. Tests

- Unit tests: recurrence next-date logic, ledger totals, Today sorting and sectioning.
- Database tests for task and project CRUD using an in-memory drift database.

## 12. Out of scope for v0.1

Sync, iOS, Play Store, home-screen widgets, subtasks, tags, search, charts, multiple currencies, multiple alarms per task.

## 13. Assumptions to confirm

- Standalone tasks (no project) are allowed.
- Recurrence options are daily, weekly and monthly only.
- Ledger totals per Personal, Business and All, with a month filter.
- Alarm actions are Done and Snooze 10 min.
