# Project Context — Laporin

## 1. Project Overview
**Laporin** is a civic tech issue reporting and community discussion application built with Flutter (mobile and web) and Supabase. The platform empowers citizens to report public infrastructure and service issues within officially supported Indonesian geographic boundaries, monitor handling progress in real time, and interact through a public community discussion thread. Admins and government officials validate reports, update handling statuses with verifiable completion proof, moderate content, broadcast official announcements, and manage dual-party deletion workflows.

Key product invariants:
- **Single Source of Truth:** A report record serves dual perspectives: the author's private progress tracker ("Laporan Saya") and the public discussion thread ("Feed Publik").
- **Two Distinct State Machines:**
  - `handling_status`: `newReport`, `accepted`, `inProgress`, `completed`, `rejected`, `cancelled`
  - `publication_state`: `pendingReview`, `published`, `held`, `archived`
- **Immutability of Terminal Reports:** Reports marked as `completed` (Selesai) or `rejected` (Ditolak) are permanently immutable by citizens and cannot be edited.
- **Dual-Party Deletion Protocol:** Reports can only be permanently removed from storage and database when both parties agree: the citizen must soft-delete the report first (`deletedByUser`), allowing the admin to subsequently trigger permanent hard-deletion (`deletedByAdmin`).

---

## 2. Technology Stack
- **Framework & SDK:** Flutter SDK (>=3.0.0 <4.0.0), Dart 3.x with sound null safety.
- **State Management:** Provider pattern (`provider: ^6.1.2`, `ChangeNotifier`).
- **Backend as a Service (BaaS):** Supabase (`supabase_flutter: ^2.8.3` - PostgreSQL, Supabase Auth, Supabase Storage, Row Level Security policies, RPC functions).
- **Push Notifications:** Firebase Cloud Messaging (`firebase_messaging: ^15.2.0`, `firebase_core: ^3.11.0`).
- **Local Storage & Offline Caching:** `shared_preferences: ^2.3.5`, `sqflite: ^2.4.1`, `path_provider: ^2.1.5`.
- **Geocoding & Maps:** `geolocator: ^13.0.2`, `geocoding: ^3.0.0`, `flutter_map: ^7.0.2`, `latlong2: ^0.9.1`.
- **Media & Images:** `image_picker: ^1.1.2`, `flutter_image_compress: ^2.3.0`, `cached_network_image: ^3.4.1`.
- **Networking & Connectivity:** `connectivity_plus: ^6.1.1`, `http: ^1.3.0`.
- **Testing:** `flutter_test`, `mockito: ^5.4.5`, `build_runner: ^2.4.14`.

---

## 3. Project Structure
```text
laporin/
├── lib/
│   ├── core/
│   │   ├── config/             # App configs, routes, theme, Indonesia boundary & regions
│   │   ├── errors/             # Custom exceptions, failure classes
│   │   ├── services/           # BoundaryService, FCMService, MediaService, ConnectivityService
│   │   ├── theme/              # AppColors, AppTypography, AppRadius, AppSpacing
│   │   └── utils/              # DateFormatter, helpers, validators
│   ├── data/
│   │   ├── models/             # ReportModel, ProfileModel, AnnouncementModel, CommentModel, VoteModel
│   │   └── repositories/       # ReportRepository, AuthRepository, NotificationRepository, CommentRepository
│   ├── features/
│   │   ├── admin/              # AdminDashboard, AdminStatusUpdateSheet, AdminProvinceFilter, Announcements, AdminStatistics
│   │   ├── auth/               # LoginScreen, RegisterScreen, ForgotPassword, SetUsernameScreen
│   │   ├── create_report/      # CreateReportScreen, Drafts, CategoryPicker, LocationPicker
│   │   ├── edit_report/        # EditReportScreen (with immutability validations)
│   │   ├── feed/               # FeedScreen, ReportCard, Upvote/Downvote actions
│   │   ├── navigation/         # MainNavigationScreen, AdminNavigationScreen, AppDrawer
│   │   ├── notifications/      # NotificationListScreen, NotificationBadge
│   │   ├── profile/            # ProfileScreen, EditProfile, MyReportsScreen
│   │   ├── report_detail/      # ReportDetailScreen, CommentThread, ResolutionProof, DeleteReportDialog
│   │   └── settings/           # SettingsScreen, SettingsController (Theme mode, Notification toggles, About App)
│   └── main.dart               # App entrypoint, dependency initialization, MultiProvider setup
├── supabase/
│   └── migrations/             # SQL migrations, RLS policies, RPC functions (dual-party deletion, immutability)
├── assets/                     # Indonesia GeoJSON boundaries, icons, placeholder images
└── test/                       # 32 comprehensive unit, widget, and integration test suites
```

---

## 4. Architecture Overview
Laporin adheres to a clean, layered architectural pattern:
- **Presentation Layer (UI & Controllers):** Widgets subscribe to feature controllers extending `ChangeNotifier`. Controllers manage UI state, error handling, loading states, and user actions.
- **Data & Repository Layer:** Repositories abstract Supabase REST/RPC queries, offline SQLite caching, media uploads, and in-memory test mocks.
- **Domain Models:** Data models provide immutability rules, serialization/deserialization (`fromJson`/`toJson`), validation getters (`canEdit`, `canAdminDelete`, `downvotePercentage`), and `copyWith` utilities.
- **Core Services:** Reusable, testable singletons or service classes for boundary verification (Ray-Casting GeoJSON polygon checks), Supabase storage upload/cleanup, and FCM notifications.

---

## 5. Core Components and Modules
1. **ReportRepository (`lib/data/repositories/report_repository.dart`):**
   - Core CRUD and synchronization logic for reports.
   - Enforces business rules: report creation role guard, edit immutability guard, dual-party soft deletion protocol, and regional province filtering.
2. **AdminReportController (`lib/features/admin/controllers/admin_report_controller.dart`):**
   - Manages admin metrics (KPI cards), filtering by status (`new`, `accepted`, `in_progress`, `completed`, `rejected`, `deleted_by_user`), and regional filtering by province.
3. **BoundaryService (`lib/core/services/boundary_service.dart`):**
   - Ingests GeoJSON boundaries of Indonesian provinces and validates user GPS coordinates.
4. **MediaService (`lib/core/services/media_service.dart`):**
   - Validates, compresses images before upload, extracts storage bucket paths, and cleans up storage assets upon permanent deletion.
5. **AppGate & Navigation (`lib/features/navigation/`):**
   - Automatically directs users based on auth state and role: `AdminNavigationScreen` for admins, `MainNavigationScreen` for citizens.

---

## 6. Feature Implementation Map
- **Report Immutability:** `lib/data/models/report_model.dart` (`canEdit`, `cannotEditReason`), enforced in `EditReportScreen` and `ReportRepository.updateReport()`.
- **Dual-Party Deletion:** `ReportRepository.softDeleteReport()`, `DeleteReportDialog`, and `_AdminReportCard._buildDeleteButton()`.
- **Province-Based Admin Filtering:** `AdminProvinceFilterDropdown` (`lib/features/admin/widgets/admin_province_filter_dropdown.dart`), `AdminReportController.setProvinceFilter()`, and `ReportRepository.getAdminReports(provinceId: ...)`.
- **Voting & Invariants:** Upvote and downvote counters with downvote percentage thresholds in `lib/data/models/report_model.dart` and `lib/features/feed/widgets/report_card.dart`.
- **Public Discussions:** Discussion thread toggle (`isDiscussionActive`), nested comment replies, interactive top-center success toast (`"komentar diposting"`, 3s duration, slide down/up animation, universal transparent grey via `AppToast`) in `lib/features/report_detail/`.
- **Resolution Proof:** Mandatory image proof and resolution notes required when marking reports as `completed` via `AdminResolveSheet`.
- **Full-App Responsive Desktop Ecosystem (Citizen & Admin):**
  - **Admin Desktop Ecosystem:** `AdminNavigationScreen` (`lib/features/admin/screens/admin_navigation_screen.dart`), `AdminSidebar` (`lib/features/admin/widgets/admin_sidebar.dart`), `AdminDashboardScreen` (`lib/features/admin/screens/admin_dashboard_screen.dart`), `AdminAnnouncementsScreen`, and `AdminStatisticsScreen`. Dynamically switches to desktop layout when screen width $> 800\text{px}$: removes bottom navigation bar and mobile drawer toggler in favor of a persistent 260px left sidebar (DESIGN.md Section 2.3), displays KPI metric cards in a single 4-column row (instead of 2x2 grid), aligns province and status filters in a responsive horizontal bar, and renders reports and announcements in a 2-column responsive card layout.
  - **Citizen Desktop Ecosystem:** `MainNavigationScreen` (`lib/features/navigation/screens/main_navigation_screen.dart`), `UserSidebar` (`lib/features/navigation/widgets/user_sidebar.dart`), `MyReportsScreen` (`lib/features/my_reports/screens/my_reports_screen.dart`), `AnnouncementsScreen` (`lib/features/announcements/screens/announcements_screen.dart`), `ProfileScreen`, `NotificationsScreen`, `SettingsScreen`, `EditReportScreen`, and `ReportDetailScreen`. When screen width $> 800\text{px}$, replaces bottom navigation bar and mobile drawer with a persistent 260px left sidebar (`UserSidebar`) equipped with Laporin brand header, citizen badge ("WARGA"), prominent "+ Buat Laporan" action button, and main menu items (Beranda, Laporan Saya, Notifikasi with unread badge, Pengumuman, Profil). `MyReportsScreen` adapts to a 1200px container featuring a 4-card metric KPI summary row (Total, Menunggu, Diproses, Selesai), interactive status filter chips (`Semua`, `Menunggu`, `Diproses`, `Selesai`, `Draft`), rich 2-column card grid (`Wrap`) with category pills, photo thumbnails, and upvote/comment counts, and an AppBar "+ Buat Laporan" quick action. Empty states and action buttons in `MyReportsScreen` navigate directly via `Navigator.push` to `CreateReportScreen` with automatic post-creation refreshes for both `MyReportsController` and `FeedController`. `AnnouncementsScreen` adapts into a 2-column card grid, while form screens (`ProfileScreen`, `NotificationsScreen`, `SettingsScreen`, `EditReportScreen`) apply centered responsive width constraints ($760\text{px} - 860\text{px}$) for comfortable ergonomics on wide monitors.
  - **Responsive 2-Column Report Detail Desktop Layout:** `ReportDetailScreen` (`lib/features/report_detail/screens/report_detail_screen.dart`). On desktop viewports ($> 800\text{px}$), expands to a 1280px wide container split into a 2-column layout (flex 6:5) separated by a vertical divider:
    - **Left Column:** Displays report details (draft/deleted banner, author card, category pill, title, interactive location row, photo gallery with lightbox, problem description), progress (`StatusTimeline`, admin status/resolution action panel, completion resolution notes & proof photos), and citizen voting (`VoteActionBar`).
    - **Right Column:** Dedicated surface panel for community discussion and comments, featuring a discussion count header badge, independently scrollable nested comment threads (`CommentThreadTile`), and pinned comment composer at the bottom.
    - Mobile single-column scrollable experience is 100% preserved on smaller screens ($\le 800\text{px}$).
  - **Desktop Top App Titlebar Profile Bar:** `AppProfileBar` (`lib/core/widgets/app_profile_bar.dart`). On desktop viewports ($> 800\text{px}$), the user profile bar is placed in the top AppBar actions (app titlebar) across both admin and citizen screens, displaying cleanly and exclusively the user avatar photo (`UserAvatar`) and Profile Name (`displayName`), with no subtitle or chevron dropdown icon, navigating directly to the profile screen/tab upon tap.
- **Desktop Feed & Thumbnail Optimization:** `FeedScreen` (`lib/features/feed/screens/feed_screen.dart`) and `ReportCard` (`lib/features/feed/widgets/report_card.dart`). On desktop viewports ($> 800\text{px}$), the feed container is centered with `maxWidth: 760` and `ReportCard` thumbnails are capped at `height: 220` with `BoxFit.cover` (preventing massive 500-900px tall image blowups on wide screens) and feature a translucent pill indicator (`+N Foto`) for multiple photo attachments per DESIGN.md Section 4.3.
- **Application Settings & Dark Mode:** `lib/features/settings/` (`SettingsScreen`, `SettingsController`), dynamic ThemeMode toggles (System, Light, Dark) persisted via `SharedPreferences`, role-aware notification switches (Citizen: pengumuman masuk, perubahan status, dukungan warga, komentar; Admin: laporan masuk, pengumuman, balasan), bottom connectivity banner (`BottomConnectivityStrip` positioned between app layer and Android navigation bar), and centralized About Application dialog.

---

## 7. Data Flow and Integrations
1. **User Action (Mobile/Web Client):** Citizen fills report with location + photos.
2. **Boundary Validation:** Coordinates evaluated against GeoJSON polygons.
3. **Media Upload:** Compressed photos sent to Supabase Storage bucket `report-attachments`.
4. **Database Mutation:** Report inserted into PostgreSQL `public.reports` via Supabase client, triggering RLS checks.
5. **Notification:** Edge function / webhook or client service triggers FCM message to area-assigned admins.
6. **Admin Triage & Moderation:** Admin updates status with notes and resolution proof; state changes reflect in both public thread and user's private tracker.

---

## 8. Database Overview
- **`public.profiles`:** User metadata, full name, username, avatar URL, role (`user` | `admin`), and assigned region.
- **`public.reports`:** Core report records with dual status columns (`handling_status`, `publication_state`), soft deletion flags (`deleted_by_user`, `deleted_by_admin`, `deleted_by_user_at`, `deleted_by_admin_at`), GPS coordinates, and media URLs.
- **`public.comments`:** Nested comment threads per report.
- **`public.votes`:** User vote records (`upvote` | `downvote`) with unique constraint on `(report_id, user_id)`.
- **`public.announcements`:** Broadcast notices created by admins.
- **Database Functions & Triggers:**
  - `validate_report_immutability()`: BEFORE UPDATE trigger blocking changes to completed/rejected reports.
  - `execute_dual_party_deletion()`: Atomic RPC enforcing that admin deletion requires citizen deletion first.

---

## 9. Authentication and Authorization
- **Supabase Auth:** Google OAuth and email/password sign-in.
- **Role-Based Access Control (RBAC):**
  - `user`: Citizen role. Can create reports, view own reports, edit active reports, vote, comment, and soft-delete own reports. Blocked from accessing admin portal.
  - `admin`: Public official role. Can update statuses, upload resolution proof, moderate held threads, broadcast announcements, filter by province, and execute permanent deletion on citizen-deleted reports. Blocked from filing reports.

---

## 10. Development Conventions
- **Code Style:** Effective Dart rules via `analysis_options.yaml`. Strict linting with zero analyzer errors or warnings.
- **Error Handling:** Graceful fallback when offline or Supabase connection is unavailable.
- **UI Architecture & Theme System:** Design tokens organized in `lib/core/theme/` (`AppColors`, `AppRadius`, `AppTextStyles`, `AppTheme`). Supports comprehensive dual-theme (Light & Dark mode) conforming to Flat UI principles with WCAG 2.2 AA contrast compliance across all component layers (cards, pills/badges, navigation bars, appbars, typography headings, form inputs, and buttons) utilizing semantic colors (`primary`, `secondary`, `tertiary`, `warning`, `success`, `danger`).
- **Testing Mandate:** Every new feature, status rule, and state transition must be validated with comprehensive unit and widget tests in `test/`.

---

## 11. Build, Run, and Test Instructions
### Static Analysis:
```powershell
flutter analyze
```
### Running Tests:
```powershell
# Run the entire test suite (350+ tests across 32 files)
flutter test

# Run a specific test suite
flutter test test/admin_role_and_navigation_test.dart
flutter test test/dual_party_report_deletion_test.dart
```
### Running the Application:
```powershell
# Run on Chrome (Web)
flutter run -d chrome

# Run on connected Android device/emulator
flutter run -d android
```

---

## 12. Known Issues and Technical Limitations
- **Offline Sync:** In-memory fallback is fully functional for tests; production background sync requires network reconnect handlers in active foreground sessions.
- **Storage Cleanup:** Offline and test environments safely skip remote Supabase Storage deletion calls via `MediaService` bypass.
- **Desktop Navigation:** On desktop layouts (`width > 800`), the mobile AppBar toggler (`DrawerMenuButton`) is omitted in favor of the permanent `AdminSidebar` on the left; mobile layouts retain drawer togglers and bottom navigation bars.

---

## 13. Important File References
- `lib/data/models/report_model.dart`: Core report entity and business invariant rules.
- `lib/data/repositories/report_repository.dart`: Central data access and mutation layer.
- `lib/features/admin/screens/admin_dashboard_screen.dart`: Admin portal dashboard and action triggers.
- `lib/features/admin/widgets/admin_sidebar.dart`: Responsive 260px desktop navigation sidebar component.
- `lib/features/admin/widgets/admin_province_filter_dropdown.dart`: Regional province filter component.
- `lib/features/admin/screens/admin_statistics_screen.dart`: Admin statistics, monthly trend bar chart, and category/status analytics.
- `lib/features/admin/controllers/admin_statistics_controller.dart`: State controller for admin report statistics and period filtering.
- `lib/data/models/report_statistics_model.dart`: Models for monthly and aggregated report statistics.
- `supabase/migrations/20261113000000_create_report_statistics_and_retention.sql`: Database schema, persistent archives, and triggers for statistics retention even after physical hard-delete.
- `lib/features/report_detail/screens/report_detail_screen.dart`: Report detail and discussion interface.
- `test/dual_party_report_deletion_test.dart`: Test specifications for dual-party deletion and storage cleanup.
- `test/admin_role_and_navigation_test.dart`: Test specifications for admin roles, navigation, and dashboard actions.
- `test/admin_desktop_responsive_test.dart`: Test specifications for admin desktop sidebar and responsive UI layouts.
- `test/admin_statistics_test.dart`: Test specifications for admin statistics, monthly filtering, and report deletion retention.
- `lib/data/repositories/notification_repository.dart`: Notification repository with real-time subscription, in-memory/database deduplication, and 6-event dispatchers.
- `lib/features/notifications/controllers/notification_controller.dart`: Reactive notification state manager filtered dynamically by `SettingsController`.
- `lib/core/services/fcm_service.dart`: Push notification service with foreground presentation suppression tied to user notification preferences.
- `supabase/migrations/20261113010000_fix_duplicate_notifications_and_all_events.sql`: Migration resolving duplicate status change triggers and establishing database triggers for all 6 core events.
- `test/notification_events_and_settings_test.dart`: Verification tests for notification deduplication, 6 event dispatchers, settings filtering, and foreground message handling.

---

## 14. Notification Architecture & Event Matrix
Laporin maintains a real-time event-driven notification pipeline spanning Supabase PostgreSQL database triggers, Supabase Realtime WebSocket streams, Firebase Cloud Messaging (FCM), and dynamic client-side filtering via `SettingsController`:
- **Strict Deduplication:** Protected both at the database level (`NOT EXISTS (... created_at > now() - interval '5 seconds')`) and client level (`_setDeduplicatedNotifications` & `addNotification` checking identical IDs and identical semantic tuples within 5 seconds). Eliminates duplicate notifications caused by concurrent database triggers or rapid status changes.
- **6-Event Support Matrix:**
  1. `new_report`: Dispatched to Admin when a citizen submits a new report (`ReportRepository.createReport`).
  2. `status_changed`: Dispatched to Report Author when handling status changes (`ReportRepository.updateHandlingStatus`).
  3. `upvoted`: Dispatched to Report Author when a citizen upvotes their report (`ReportRepository.voteReport`).
  4. `new_comment`: Dispatched to Report Author when a citizen comments on their report (`CommentRepository.addComment`).
  5. `reply_comment`: Dispatched to Parent Comment Author and Admins when a comment receives a reply (`CommentRepository.addComment`).
  6. `announcement`: Dispatched to all Citizens and Admins when an official announcement is published (`AnnouncementRepository.createAnnouncement`).
- **Dynamic Settings Filtering:** `NotificationController` and `FcmService` observe `SettingsController`. Disabling notifications globally or toggling off specific categories immediately filters the active notification list, zeroes the unread counter badge, and suppresses foreground pop-up banners.

---

## 15. Development Guidelines for Future Tasks
- Always follow the cycle: $\text{ANALYZE} \rightarrow \text{IMPLEMENT} \rightarrow \text{CHECK} \rightarrow \text{TEST} \rightarrow \text{DONE}$.
- Never modify existing business invariants (dual status machine, immutability of completed/rejected reports, dual-party deletion) without consulting product specifications.
- Verify all changes with `flutter analyze` and `flutter test` before completing a task.
