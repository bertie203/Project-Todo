# Project-Todo

Personal offline Android app: tasks with priorities, alarms and repeats; projects; a simple money ledger. See [SPEC.md](SPEC.md).

## Develop

```sh
flutter pub get
dart run build_runner build   # after changing lib/data/database.dart
flutter test
flutter run
```

`lib/data/database.g.dart` is generated and committed.

## Layout

- `lib/data/` — drift tables and queries.
- `lib/logic/` — pure functions: recurrence, sorting, ledger totals, money.
- `lib/services/` — alarms, task changes, backup, permissions.
- `lib/ui/` — screens.
- `test/` — unit, database and widget tests.

## Release

Every push to `main` runs `.github/workflows/release.yml`. It tests, builds a signed APK and creates a GitHub Release tagged `build-<run number>`. versionCode is the run number. versionName is `0.1.<run number>`.

### One-time keystore setup

Generate the keystore once, on your own computer:

```sh
keytool -genkeypair -v -keystore release.jks -alias projecttodo \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 release.jks > release.jks.b64
```

Add four repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | contents of `release.jks.b64` |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | `projecttodo` |
| `KEY_PASSWORD` | key password |

Keep a copy of `release.jks` and the passwords outside GitHub. Do not commit it. If it is lost, new builds cannot install over the old app.

## Behaviour not fixed by the spec

- Completing an overdue recurring task moves the next instance to the first date after today, so it does not create another overdue task.
- Monthly tasks store the day they repeat on (`recurrenceDay`), so 31 Jan → 28 Feb → 31 Mar.
- Undoing a completion keeps any next instance already created.
- Alarms of tasks in archived projects are cancelled. Unarchiving restores them.
- If the app is open when an alarm's Done or Snooze is pressed, it is handled in the app. Otherwise it is handled in the background.
