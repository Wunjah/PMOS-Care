# PMOS Care: Flutter Project Foundation

PMOS Care is a mobile-first, offline-capable healthcare application designed for women in Cameroon managing Polyendocrine Metabolic Ovarian Syndrome (PMOS). This codebase implements Clean Architecture principles coupled with Riverpod state management.

---

## 1. Project Directory Structure

```
pmos_care/
├── pubspec.yaml
├── README.md
└── lib/
     ├── main.dart             # App Initialization (Firebase, Secure Hive, ProviderScope)
     ├── app.dart              # MaterialApp setup (Theme, Localization, Offline banner overlay)
     └── core/                 # Shared modules
          ├── localization/    # Translations.dart (English & French localizations & provider)
          ├── network/         # Network_info.dart (Connectivity checking stream provider)
          ├── router/          # App_router.dart (GoRouter settings, ShellRoute, and tab stubs)
          ├── storage/         # Encryption_helper.dart (Secure storage key gen + encrypted Hive boxes)
          └── theme/           # App_theme.dart (Modern Teal & Coral themes)
```

---

## 2. Dependencies & Build Requirements

This project relies on GoRouter for routing, Riverpod for state management, Hive for offline secure cache storage, and Firebase for cloud syncing.

### Core Dependencies:
* State Management: `flutter_riverpod`, `riverpod_annotation`
* Routing: `go_router`
* Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`
* Offline Storage: `hive_flutter`, `path_provider`, `connectivity_plus`
* Security: `flutter_secure_storage`, `local_auth`

---

## 3. Getting Started

Follow these steps to set up the environment and run the application:

### Step 1: Set Active Workspace
If you are using Antigravity, set this project directory as your active workspace:
```
C:\Users\Alvin\.gemini\antigravity\scratch\pmos_care
```

### Step 2: Retrieve Packages
Run the package installer from the terminal:
```bash
flutter pub get
```

### Step 3: Execute Code Generation
Build code generators (for Freezed models, Hive adaptors, and Riverpod providers):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 4: Run the Application
Start debugging on an attached device or emulator:
```bash
flutter run
```

---
*Signed,*  
**Lead Product Architect, PMOS Care**
