# PMOS Care — Developer Reference

## What This App Is

**PMOS Care** is a Flutter + Firebase mobile application that helps Cameroonian women
track and manage Polyendocrine Metabolic Ovarian Syndrome (PMOS, formerly PCOS).
It is deliberately adapted to the Cameroonian context: local foods (fufu, huckleberry,
garden eggs, plantain, water leaf), limited/intermittent internet, and the practical
realities of the local healthcare system. It is **not** a diagnostic tool — it is a
self-management and monitoring companion.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) — targets Android first |
| State management | Riverpod (StateNotifier pattern) |
| Navigation | go_router (shell routes for bottom nav) |
| Backend | Firebase Auth, Cloud Firestore, Firebase Storage, FCM |
| Local cache | Hive (offline-first, syncs when online) |
| Notifications | flutter_local_notifications + FCM |
| Auth | Email/Password, Google Sign-In, Phone OTP |
| Typography | Outfit (headings), Inter (body) |

---

## Architecture

Clean Architecture — three layers per feature:

```
lib/features/<feature>/
  domain/
    entities/          # Pure Dart data classes (no Flutter, no Firebase)
    repositories/      # Abstract interfaces
    usecases/          # Business logic units
  data/
    models/            # Entity subclasses with toJson/fromJson
    datasources/       # Local (Hive) + Remote (Firestore) implementations
    repositories/      # ConcretRepositoryImpl — orchestrates local/remote
  presentation/
    providers/         # Riverpod providers + StateNotifier
    screens/           # Flutter UI screens
    widgets/           # Reusable screen-level widgets
```

**Key conventions:**
- Every feature has its own Riverpod provider file.
- Firestore path: `users/{uid}/<collection>/{docId}`.
- User ID always obtained from `FirebaseAuth.instance.currentUser.uid`.
- Offline writes go to Hive with `needsSync: true`; `syncOfflineData()` reconciles on next online start.
- Design tokens live in `lib/core/theme/app_theme.dart` and match the inline constants in each screen file (see below).

---

## Design System

All screens follow the home/calendar design language:

```dart
const _kPrimary    = Color(0xFF5152B9);   // indigo — primary actions, active state
const _kDarkText   = Color(0xFF191C20);
const _kBodyText   = Color(0xFF464552);
const _kMutedText  = Color(0xFF777684);
const _kBg         = Color(0xFFF8F9FF);   // scaffold background
const _kGlass      = Color(0xB3FFFFFF);   // frosted-glass card fill
const _kGlassBorder= Color(0x80FFFFFF);
const _kDivider    = Color(0xFFE7E8EE);
const _kTealDark   = Color(0xFF00696A);   // secondary accent (nutrition, hydration)
const _kTeal       = Color(0xFF45A8A9);
const _kTealBg     = Color(0x1A45A8A9);
const _kProgressTrack = Color(0xFFECEEF3);
```

- Cards: white bg, `borderRadius: 14–16`, subtle `BoxShadow` (4 % black, blur 8–12).
- Feature header: frosted glass bar (`BackdropFilter` + `SafeArea`) replaces the default `AppBar`.
- Gradient banners: `Color(0xFF5152B9)` → `Color(0xFF6C6DD1)` with decorative rotated icon.
- Chip pills: `borderRadius: 999`, animated `AnimatedContainer` for selected state.

---

## Feature Status

### ✅ Done
- Firebase Auth: email/password, phone OTP, Google Sign-In
- Clinical onboarding flow (health profile, skin profile, connected apps)
- Home dashboard with bento-grid, activity trend, cycle phase card
- Calendar / cycle tracker (log start date, flow, pain, symptoms, predicted next date)
- Diet & Nutrition screen (food guide, meal tracker, dietary advice, AI Chef)
- Symptom history screen
- Weight tracker
- Activity tracker
- Medication schedule screen
- Specialist directory (coach tab)
- Reports hub
- Offline-first sync (Hive → Firestore)
- Firebase Cloud Messaging setup

### 🔨 In Progress / Next Up

#### 1. Skip Onboarding
- Add a "Skip" text button (top-right) on `HealthProfileSetupScreen`, `SkinProfileScreen`, and `ConnectedAppsScreen`.
- Tapping skip calls `ref.read(authStateNotifierProvider.notifier).completeOnboarding()` then `context.go('/home')`.
- Files: `lib/features/authentication/presentation/screens/health_profile_setup_screen.dart`, `skin_profile_screen.dart`, `connected_apps_screen.dart`.

#### 2. Cycle Tracking — End-Cycle Flow
- Add `updateCycle(CycleEntity)` to `CycleRepository` interface + all layers.
- `CycleNotifier.endActiveCycle(String cycleId, DateTime endDate)` → calls `updateCycle`.
- Remote: Firestore `update({endDate: ...})` on the existing doc.
- Local: `cacheSingleCycle` (already upserts by ID).
- Calendar screen: detect "active cycle" = most recent cycle where `endDate == null` and `!isPredicted`.
  Show an **"Active — Mark End"** banner card with a date picker to close the cycle.

#### 3. Cycle PDF Download
- Use `pdf` + `printing` packages (or `share_plus`) to export the cycle log as a formatted PDF.
- Button in the CalendarScreen header.

#### 4. Dual Sign-Up: Doctor vs Patient
- Add `role` field (`'patient'` | `'doctor'`) to `UserEntity` and Firestore `users/{uid}` doc.
- `SignupScreen`: add role toggle chip at the top ("I am a Patient" / "I am a Healthcare Provider").
- Doctors skip the PMOS clinical onboarding and go directly to a provider dashboard.
- Firestore security rules: patients can only read their own data; doctors can read patients who have granted access.

#### 5. Telemedicine: Patient ↔ Doctor Chat + Call
- Firestore collection: `consultations/{consultationId}/messages/{msgId}`.
- `ConsultationEntity`: `{id, patientUid, doctorUid, startedAt, status}`.
- `MessageEntity`: `{id, senderUid, text, timestamp, type (text|image|call_log)}`.
- UI: chat bubble screen (`ConsultationChatScreen`) reachable from the Coach tab.
- In-app calling: integrate `agora_rtc_engine` or `flutter_webrtc` (or a deep-link to WhatsApp as MVP fallback).

#### 6. Profile Update
- Allow user to update display name and profile picture.
- Profile picture: `image_picker` → upload to `Firebase Storage` at `users/{uid}/avatar.jpg`.
- Update `displayName` in both Firestore and `FirebaseAuth.currentUser.updateDisplayName()`.
- Add a profile edit screen reachable from the home top-bar avatar.

#### 7. Medication Reminders
- `MedicationEntity` already exists. When user saves a med with a time, schedule a local notification via `flutter_local_notifications` using `NotificationService`.
- On app launch, re-schedule all saved medications (handles app restarts).

#### 8. Activity Tracker Download
- Similar to cycle PDF: export activity logs as CSV or PDF using `csv` + `share_plus`.

#### 9. AI Chef Enhancement
- Current: Gemini streaming chat with local recipe cards.
- Target: AI Chef should answer questions about **any** meal (not just the 5 preset recipes) by passing the dish name as context in the system instruction.

#### 10. Firebase Endpoint Tests
- Integration tests in `test/` covering:
  - `CycleRemoteDataSource.saveRemoteCycle` → document appears in Firestore.
  - `CycleRemoteDataSource.getRemoteCycles` → returns correct count.
  - `CycleRemoteDataSource.deleteRemoteCycle` → document removed.
  - `updateCycleEndDate` → `endDate` field updated in Firestore.
  - Auth: `signUpWithEmailAndPassword` → user exists in Firebase Auth.

---

## Firestore Data Schema

```
users/{uid}
  uid, email, phoneNumber, displayName, photoUrl
  role: 'patient' | 'doctor'
  isOnboardingCompleted, biometricLockEnabled, notificationsEnabled
  age, heightCm, weightKg, country, region, pmosDiagnosisStatus
  medications[], allergies[], goals[]
  fcmTokens[]

  cycles/{cycleId}
    startDate, endDate (nullable), flowIntensity, painLevel
    symptoms[], isPredicted, clientUpdatedTimestamp, serverTimestamp

  mealLogs/{logId}
    mealType, foodName, calories, proteinGrams, fiberGrams, waterMl
    timestamp, serverTimestamp

  symptoms/{symptomId}
    date, symptoms[], mood, painLevel, notes, serverTimestamp

  weightLogs/{logId}
    date, weightKg, notes, serverTimestamp

  activityLogs/{logId}
    date, type, durationMinutes, intensityLevel, notes, serverTimestamp

  medications/{medId}
    name, dosage, frequency, scheduledTimes[], startDate, isActive

consultations/{consultationId}
  patientUid, doctorUid, startedAt, status: 'active'|'closed'

  messages/{msgId}
    senderUid, text, timestamp, type: 'text'|'image'|'call_log'
```

---

## Running the App

```bash
flutter pub get
flutter run                        # Android device/emulator
flutter test                       # Unit + widget tests
flutter test integration_test/     # Firebase integration tests (needs emulator)
```

**Firebase emulator (for tests):**
```bash
firebase emulators:start --only auth,firestore
```

Set `USE_FIREBASE_EMULATOR=true` in your test environment to point the SDK to localhost.

---

## Important Files Quick-Reference

| File | Purpose |
|---|---|
| `lib/core/router/app_router.dart` | All routes + `SplashScreen` auth gate + `AppShell` bottom nav |
| `lib/core/theme/app_theme.dart` | Design tokens (colours, typography, card/button styles) |
| `lib/core/network/gemini_service.dart` | Gemini streaming singleton |
| `lib/features/authentication/presentation/providers/auth_provider.dart` | `AuthNotifier` — all auth state + `completeOnboarding()` |
| `lib/features/cycle_tracker/presentation/providers/cycle_provider.dart` | `CycleNotifier` — load, add, remove, (to add) update cycles |
| `lib/features/cycle_tracker/data/datasources/cycle_remote_datasource.dart` | Firestore CRUD for cycles |
| `lib/features/diet/presentation/screens/diet_screen.dart` | Diet & Nutrition UI (4-tab) |
| `lib/features/cycle_tracker/presentation/screens/calendar_screen.dart` | Calendar + cycle tracking UI |
| `lib/features/home/presentation/screens/home_screen.dart` | Home dashboard |

---

## Contributing / Extending

1. **New feature**: create full `domain/data/presentation` structure under `lib/features/<name>/`.
2. **New screen**: add a `GoRoute` in `app_router.dart`; add a bottom-nav item to `AppShell` if it's a top-level screen.
3. **New Firestore collection**: add the path to the schema above; add security rules in `firestore.rules`.
4. **Design**: always use `_kPrimary`, `_kBg`, etc. from the inline token constants — do not hard-code hex values.
5. **No `dart:io` imports in `domain/` layer** — keep it pure Dart.
