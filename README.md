# ServicePing — Vehicle Maintenance Tracker

**Store launch kit:** [Logo, feature graphic, 7 screenshots, listing and privacy documents](store/README.md) · [Download ZIP](store/ServicePing-Store-Kit.zip) · [Upload guide](store/UPLOAD-GUIDE.md)

An offline Flutter application for motorcycle and car owners. No accounts, Firebase, analytics, remote APIs, or automatic mileage detection.

## Run

Install Flutter stable (developed and tested with Flutter 3.47.9 / Dart 3.13.7), Android Studio and/or Xcode, then:

```sh
flutter pub get
flutter run
```

Android and iOS are the mobile targets. A web target is included for UI previews; local mobile notifications require Android or iOS. Data stays in Hive CE on the device. Initial dependency installation needs internet; app use does not.

## Features

- Multiple vehicles: create, edit, delete, optional year and registration, cars and motorcycles, km or miles.
- Selected-vehicle dashboard with current mileage, latest service, due maintenance and mileage progress.
- Manual odometer updates, decrease protection, timestamped history. Distance units are fixed after vehicle creation so historical readings cannot be misinterpreted.
- Service records with built-in or custom types, date, mileage, cost and notes; edit/delete and vehicle/type/search filters.
- Schedules with a date, mileage threshold or both. Either threshold independently makes the service due. Zero remaining distance is due; negative distance or a past date is overdue.
- Completing a schedule requires saving a service record. The completed schedule and record remain stored. No recurrence is generated.
- Expenses, completed service count, most recent service, upcoming count and six-month cost chart.
- Material 3, deep blue/orange styling, responsive mobile layout, light/dark/system themes, and animated vehicle cards.
- Opt-in local date reminders; Android reboot receivers and notification permission support.

## MVVM structure

```text
lib/
├── main.dart                         # Startup, Hive, dependency injection, lifecycle
├── core/
│   ├── app_router.dart               # GoRouter routes and navigation shell
│   └── app_theme.dart                # Material 3 light/dark themes
├── models/
│   └── entities.dart                 # Vehicle, ServiceRecord, Schedule, OdometerEntry
├── data/
│   └── repositories/
│       └── local_repository.dart     # Versioned JSON snapshot in Hive CE
├── services/
│   └── notification_service.dart     # OS notifications and reminder scheduling
├── viewmodels/
│   └── garage_view_model.dart        # Riverpod state, validation, CRUD, completion
└── views/
    ├── dashboard.dart
    ├── vehicles.dart                 # My Vehicles and Vehicle Details
    ├── vehicle_form.dart
    ├── service_form.dart
    ├── history.dart
    ├── schedules.dart
    ├── schedule_form.dart
    ├── statistics.dart
    ├── privacy.dart                  # Offline policy from shared editable JSON
    ├── settings.dart
    └── widgets/
        └── form_fields.dart          # Reusable inputs, date picker, confirmations

test/
├── maintenance_test.dart             # Boundary/date/mileage calculations
├── reminders_test.dart               # Reminder queue ordering and limits
├── view_model_test.dart              # Persistence, isolation, mutations
└── ui_test.dart                      # Every route in light/dark mobile layouts
android/                             # Native Android project and notification setup
ios/                                 # Native iOS project
web/                                 # Optional browser preview
.github/workflows/flutter.yml        # Analysis, tests, Android/iOS build jobs
```

Views observe Riverpod state and invoke ViewModel commands. The ViewModel owns mutations and business validation and depends on an injected repository and notification service. Models encode relationships and maintenance status. Persistence writes all related collections together in one Hive entry so completing a schedule and recording its service cannot be saved independently.

## Business behavior

Service odometer values may be older than the current reading, but cannot exceed it. Update the vehicle's odometer manually before recording a newer service. Editing a historical service never modifies vehicle mileage. Deleting a vehicle asks for confirmation and deletes only that vehicle's records, schedules and odometer history. Deleting a service record does not reopen a completed schedule.

Expenses are decimal amounts in the owner's local currency; the app does not perform currency conversion. Statistics count saved service records as completed services. Upcoming maintenance excludes due/overdue and completed schedules. The chart groups costs by calendar month of service.

## Notifications

Use **Settings → Enable notifications** to request OS permission. Each active date-based schedule queues a due-date notification plus unique configured reminder days at 09:00 local device time. Android uses inexact alarms, so delivery time is subject to the OS, battery restrictions and permission settings. Mileage thresholds have in-app status only. Opening/resuming the app resynchronizes date reminders and refreshes due status. There is no background mileage sensor or automatic odometer update.

The app works when notification permission is denied. The nearest 64 future reminders are queued chronologically to respect iOS limits. Opening/resuming the app refills this rolling queue; later reminders need the app to be reopened after earlier reminders have fired. No server delivers notifications. Device testing of permission prompts, reboot delivery, timezone changes and battery policies is required before store release.

## Verify and build

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
# For distribution after configuring your own Android signing key:
flutter build appbundle --release
# macOS with Xcode and your Apple signing configuration:
flutter build ipa --release
```

The generated Android release configuration currently uses a debug signing key for local builds. Replace it with a private release keystore before distribution. Never commit keystore files or signing passwords. iOS signing requires an Apple development team. CI provides an installable debug APK artifact and compiles iOS without signing.

## Data and privacy

All data resides in the app sandbox. Android automatic cloud backup is disabled. Uninstalling/clearing app data removes the garage. There is no export, synchronization, account recovery or telemetry. Device-level iOS backups follow the owner's system settings.

## Store assets and privacy policy

The `store/` folder includes a complete Google Play asset kit, numbered 1080 × 1920 screenshots captured from real Flutter widgets, editable documents and an offline review gallery. Matching branded launcher icons are installed for Android, iOS and web. Settings links to an offline privacy policy built from `store/source/policy.json`.

The support email `support@serviceping.example` is a reserved temporary placeholder. Replace it, regenerate the policy/listing documents with `python3 tool/build_store_documents.py`, and rebuild the app before publication. The web-ready privacy policy is in `docs/privacy/index.html`; hosting has not been enabled. Follow `store/UPLOAD-GUIDE.md` for the public HTTPS policy URL, asset uploads and Data safety facts.
