# 📘 Nutri360 Flutter: Architecture & Codebase Guide

This document provides a detailed breakdown of the entire **Nutri360 Flutter** codebase: its architectural design, directory organization, every source file's purpose and functionality, and how each component connects to the wider ecosystem.

---

## 🏛️ 1. High-Level Architecture

The project is structured according to **Clean Architecture** principles, enforcing separation of concerns between business logic, clinical calculations, data persistence, and UI presentation:

```
nutri360_flutter/
├── android/                  ← Android native configuration, Gradle, AGP, Manifest
├── assets/
│   ├── app.env               ← Environment variables (Supabase URL, Anon Key, Stitch ID)
│   ├── images/               ← Branding assets, logo, splash screens
│   └── translations/         ← Multi-language JSON dictionaries (en, hi, te, ta, kn, bn, mr)
├── lib/
│   ├── main.dart             ← Application entry point & cold-start initializations
│   ├── core/
│   │   ├── models/           ← Immutable data domain entities (JSON serialization)
│   │   ├── services/         ← External APIs (Supabase, MongoDB Stitch, Offline Hive Cache)
│   │   ├── utils/            ← Medical & biophysical algorithms (WHO LMS, Vitamin D formula)
│   │   ├── theme/            ← Design tokens (Colours, Typography, Material 3 Theme)
│   │   └── router.dart       ← GoRouter declarative routing & role-based route guards
│   ├── features/             ← Feature-oriented UI screens
│   │   ├── auth/             ← Role selection, parent sign-in, health worker sign-in
│   │   ├── parent/           ← Parent dashboard, child profile, 5 health modules
│   │   └── worker/           ← Anganwadi worker dashboard, screening tool, clinical triage
│   └── shared/
│       └── widgets/          ← Reusable design system UI components
├── .github/
│   └── workflows/
│       └── build_apk.yml     ← Automated CI/CD build pipeline for release APK
└── pubspec.yaml              ← Dependencies, assets, and Flutter SDK constraints
```

---

## 🚀 2. Entry Point & Pre-Render Initialization

### [`lib/main.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/main.dart)
- **Role**: Bootstraps the application before any UI frames are rendered.
- **Key Operations**:
  1. `WidgetsFlutterBinding.ensureInitialized()`: Hooks into the Flutter engine.
  2. `dotenv.load(fileName: 'assets/app.env')`: Loads Supabase URLs, anonymous keys, and backend configuration securely.
  3. `Supabase.initialize(...)`: Initializes PostgreSQL client connection.
  4. `Hive.initFlutter()` & `OfflineStore.instance.init()`: Initializes encrypted local NoSQL storage boxes for offline capability in rural Anganwadi centers.
  5. `AuthService.instance.init()`: Rehydrates saved user credentials and authentication tokens from `SharedPreferences`.
  6. `StitchService.instance.init()`: Connects to MongoDB Atlas App Services.
  7. `SystemChrome.setPreferredOrientations(...)`: Locks screen rotation to portrait mode.
  8. `EasyLocalization(...)`: Loads localization dictionaries for 7 languages (**English, Hindi, Telugu, Tamil, Kannada, Bengali, Marathi**).
  9. `runApp(Nutri360App)`: Boots `MaterialApp.router` with `GoRouter`.

---

## 📦 3. Domain Models (`lib/core/models/`)

These models represent the core business domain. Every entity includes JSON serialization (`fromJson`, `toJson`) and immutable copying (`copyWith`).

### [`child.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/models/child.dart)
- **Role**: Represents a registered child profile.
- **Attributes**: `id`, `name`, `sex` (`Sex.male` / `Sex.female`), `dob`, `parentId`, `weightKg`, `heightCm`, `headCircumferenceCm`, timestamps.
- **Computed Properties**: `ageDisplay` (e.g. "2 yrs 4 mos"), `ageInDays`, `ageInMonths`.

### [`user.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/models/user.dart)
- **Role**: Represents an authenticated user profile.
- **Attributes**: `id`, `email`, `name`, `role` (`UserRole.parent`, `UserRole.healthWorker`, `UserRole.clinician`, `UserRole.admin`), `workerId`, `organization`, `isDemo`.
- **Aliases**: `fullName` (alias of `name`), `centreCode` (alias of `organization`). Includes pre-configured demo singletons (`User.demoParent` and `User.demoWorker`).

### [`growth_record.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/models/growth_record.dart)
- **Role**: Periodic biometric measurement taken by parents or Anganwadi workers.
- **Attributes**: `id`, `childId`, `date`, `weightKg`, `heightCm`, `headCircumferenceCm`, `waz` (Weight-for-Age), `haz` (Height-for-Age), `baz` (BMI-for-Age), `clinicalNotes`.

### [`nutrition_record.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/models/nutrition_record.dart)
- **Role**: Daily dietary meal record.
- **Attributes**: `id`, `childId`, `mealType` (`breakfast`, `lunch`, `dinner`, `snack`), `foodItems` (list of selected Indian food IDs), `timestamp`, `nutrientTotals`.

### [`nutrient_breakdown.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/models/nutrient_breakdown.dart)
- **Role**: Aggregated nutrient profile for meals.
- **Attributes**: `calories` (kcal), `proteinG` (g), `ironMg` (mg), `vitaminAUg` (µg), `calciumMg` (mg), `zincMg` (mg).

### [`share_code.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/models/share_code.dart)
- **Role**: Secure temporary authorization token.
- **Attributes**: `code` (6-digit PIN), `childId`, `parentId`, `expiresAt`, `redeemedByWorkerId`. Allows parents to grant field workers temporary write access without sharing credentials.

---

## ⚙️ 4. Core Services & Backends (`lib/core/services/`)

### [`auth_service.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/services/auth_service.dart)
- **Role**: Authentication and session lifecycle management.
- **Key Functions**:
  - `loginParent(email, password, rememberMe)`: Authenticates via Supabase Auth.
  - `loginWorker(workerId, centreCode)`: Authenticates against the ICDS health worker database.
  - `loginDemo(role)`: Instant zero-credential demo login.
  - `init()`: Cold-start session restoration from `SharedPreferences`.
  - `logout()`: Clears local tokens, drains active user state, and triggers UI redirection to login.

### [`database_service.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/services/database_service.dart)
- **Role**: Data access layer communicating with Supabase PostgreSQL.
- **Key Functions**:
  - `getChildrenForParent(parentId)`: Fetches children registered under a parent.
  - `addChild(child)`: Inserts a child record with dual casing mapping.
  - `getGrowthHistory(childId)`: Returns chronological growth checkups.
  - `saveGrowthRecord(record)`: Upserts biometric measurements.
  - `createShareCode(childId)` & `redeemShareCode(code, workerId)`: Generates and validates share codes.

### [`offline_store.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/services/offline_store.dart)
- **Role**: Local offline-first caching and background synchronization.
- **Mechanism**:
  - Operates Hive boxes (`children_cache`, `growth_queue`, `nutrition_queue`).
  - When network is unavailable, records are committed locally.
  - Listens to `Connectivity().onConnectivityChanged`. Once internet returns, `_flushQueues()` drains pending records into Supabase automatically.

### [`stitch_service.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/services/stitch_service.dart)
- **Role**: Integration with MongoDB Atlas App Services (Stitch).
- **Functions**: Handles cross-facility synchronization and real-time medical referral event streaming.

---

## 🧮 5. Medical & Biophysical Algorithms (`lib/core/utils/`)

### [`growth_calculations.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/utils/growth_calculations.dart)
- **Role**: Implementation of the **World Health Organization (WHO) Child Growth Standards**.
- **Math Formula (LMS Method)**:
  $$\text{Z-score} = \frac{\left(\frac{\text{Measurement}}{M}\right)^L - 1}{L \times S}$$
- **Outputs**:
  - **WAZ (Weight-for-Age)**: Detects underweight ($\text{Z} < -2$) and severe underweight ($\text{Z} < -3$).
  - **HAZ (Height-for-Age)**: Detects stunting ($\text{Z} < -2$) and severe stunting ($\text{Z} < -3$).
  - **BAZ (BMI-for-Age)**: Identifies wasting ($\text{Z} < -2$) and Severe Acute Malnutrition / SAM ($\text{Z} < -3$).
  - **Red Flag Engine**: Flags high-risk pediatric cases for immediate clinical triage.

### [`vitamin_d_formula.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/utils/vitamin_d_formula.dart)
- **Role**: Biophysical photochemical model (Webb & Holick).
- **Parameters**: Solar Zenith Angle, Latitude, Time of Day, Skin Fitzpatrick Phototype (Types I–VI), Exposed Body Surface Area (BSA percentage), Exposure Duration.
- **Output**: Calculates synthesized cutaneous Vitamin D in International Units (IU) and compares against the 400 IU/day pediatric RDA.

### [`nutrition_guidance.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/utils/nutrition_guidance.dart)
- **Role**: Nutritional database and dietary assessment.
- **Features**: Contains micro/macronutrient values for 50+ regional Indian staple foods (Ragi, Moong Dal, Khichdi, Idli, Moringa leaves, Curd, Egg, etc.) and computes WHO Minimum Dietary Diversity (MDD) scores (0–8 food groups).

### [`formatters.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/utils/formatters.dart)
- **Role**: Localized formatting utilities for dates, ages, currency, weights, and measurements.

---

## 🎨 6. Design System & Theme (`lib/core/theme/`)

- [`app_colors.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/theme/app_colors.dart): Design palette tokens (Primary blues, Semantic triage colors: `semanticLow` green for normal, `semanticMonitor` amber for review, `semanticHigh` red for high priority/SAM alerts).
- [`app_typography.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/theme/app_typography.dart): Typography scale definitions (`displayLarge`, `headlineMedium`, `titleMedium`, `bodyMedium`, `labelSmall`).
- [`app_theme.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/theme/app_theme.dart): Assembles Material 3 theme data, card elevations, button styles, and form field decorations.

---

## 🧭 7. Navigation & Routing: [`lib/core/router.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/core/router.dart)

- Built using **GoRouter** with route guards:
  - **Unauthenticated Redirect**: Any attempt to open `/parent/*` or `/worker/*` without an active session redirects to `/` (Role Selection).
  - **Role Guard Protection**: Parents attempting to access `/worker/*` are routed back to `/parent`. Health workers attempting to access `/parent/*` are routed to `/worker`.

---

## 📱 8. UI Feature Screens (`lib/features/`)

### Authentication (`lib/features/auth/`)
- [`role_selection_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/auth/role_selection_screen.dart): Initial landing screen. Choose between Parent Portal or Anganwadi Worker Portal, plus language selector.
- [`parent_login_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/auth/parent_login_screen.dart): Parent sign-in, registration, password visibility toggle, session persistence, and one-tap demo login.
- [`worker_login_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/auth/worker_login_screen.dart): Anganwadi worker login using Worker ID (e.g. `HW-ANG-4019`) and Centre Code (e.g. `ANG-4019`).

### Parent Module (`lib/features/parent/`)
- [`parent_dashboard_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/parent/dashboard/parent_dashboard_screen.dart): Main overview showing registered children, active alerts, and quick actions.
- [`add_child_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/parent/add_child/add_child_screen.dart): Child enrollment form with date picker, gender selector, and initial growth metrics.
- [`child_profile_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/parent/child/child_profile_screen.dart): Individual child hub displaying current metrics, Anganwadi share code dialog, and module navigation cards.
- [`growth_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/parent/child/growth/growth_screen.dart): WHO growth trajectory charts (`fl_chart`), Z-score cards, and measurement entry modal.
- [`nutrition_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/parent/child/nutrition/nutrition_screen.dart): Meal logging, nutrient breakdowns, Minimum Dietary Diversity check, and Vitamin D exposure calculator.
- [`vaccination_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/parent/child/vaccination/vaccination_screen.dart): Indian Universal Immunization Programme (UIP) & IAP vaccine tracking schedule.
- [`development_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/parent/child/development/development_screen.dart): Age-calibrated developmental milestone questionnaire (Motor, Cognitive, Language, Social-Emotional).
- [`attention_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/parent/child/attention/attention_screen.dart): Early neurodevelopmental and attention screening tool with automated guidance.

### Anganwadi Worker Module (`lib/features/worker/`)
- [`worker_dashboard_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/worker/dashboard/worker_dashboard_screen.dart): Summary of all assigned children in the Anganwadi center, triage indicators, and share-code redemption input.
- [`worker_child_screen.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/features/worker/child/worker_child_screen.dart): Field worker assessment tool: record official clinical measurements, enter intervention notes, and dispatch medical referrals.

---

## 🧩 9. Shared UI Components (`lib/shared/widgets/`)

- [`app_button.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/shared/widgets/app_button.dart): Buttons supporting `primary`, `secondary`, and `ghost` variants with built-in async loading spinners.
- [`app_card.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/shared/widgets/app_card.dart): Standard card container with rounded corners, optional title icon, and clinical severity accent borders.
- [`app_header.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/shared/widgets/app_header.dart): Navigation header with back button handling, screen title, and language switcher.
- [`status_badge.dart`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/lib/shared/widgets/status_badge.dart): Status pill badge with colored status indicators (`Normal`, `Monitor`, `High Priority`, `Info`).

---

## 🏗️ 10. Native Android & CI/CD Pipeline

- [`android/gradle.properties`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/android/gradle.properties): Enables `android.useAndroidX=true`, `android.enableJetifier=true`, and Gradle heap optimization.
- [`android/settings.gradle`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/android/settings.gradle): Configures Gradle plugins with AGP `8.11.1` and Kotlin `2.2.20`.
- [`android/app/build.gradle`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/android/app/build.gradle): Specifies `minSdk = 24`, `compileSdk = flutter.compileSdkVersion`, `targetSdk = flutter.targetSdkVersion`, Kotlin 2.2 JVM 17 compiler options, and AndroidX dependencies.
- [`.github/workflows/build_apk.yml`](file:///home/sivaguru/.gemini/antigravity/scratch/nutri360_flutter/.github/workflows/build_apk.yml): The GitHub Actions pipeline that builds, validates, and uploads the release APK (`nutri360-android-apk`) on every push to `main`.
