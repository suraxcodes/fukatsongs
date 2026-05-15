# Plan: Project Setup

**ID:** 01-PROJECT-SETUP
**Wave:** 1
**Requirements addressed:** SETUP-01, SETUP-02, SETUP-03
**Files modified:** pubspec.yaml, android/app/build.gradle, android/app/src/main/AndroidManifest.xml, lib/main.dart
**Autonomous:** true

<objective>
Rename the application, update the Android package ID, and install all required dependencies for fukatSongs.
</objective>

<tasks>
<task>
<read_first>pubspec.yaml</read_first>
<action>
Update `pubspec.yaml`:
- name: fukat_songs
- description: "fukatSongs - Personal Music Streaming"
Add dependencies:
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  just_audio: ^0.9.36
  audio_service: ^0.18.13
  dio: ^5.4.0
  hive_flutter: ^1.1.0
  path_provider: ^2.1.2
  cached_network_image: ^3.3.1
  flutter_screenutil: ^5.9.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  logger: ^2.0.2
  connectivity_plus: ^5.0.2
Add dev_dependencies:
  build_runner: ^2.4.8
  freezed: ^2.4.7
  riverpod_generator: ^2.4.0
  hive_generator: ^2.0.1
  json_serializable: ^6.7.1
</action>
<acceptance_criteria>
- `pubspec.yaml` name is `fukat_songs`
- `flutter pub get` exits 0
</acceptance_criteria>
</task>

<task>
<read_first>android/app/build.gradle</read_first>
<action>
In `android/app/build.gradle`, update `namespace` and `defaultConfig.applicationId` to `com.fukatsongs.app`.
</action>
<acceptance_criteria>
- `android/app/build.gradle` contains `applicationId "com.fukatsongs.app"`
</acceptance_criteria>
</task>

<task>
<read_first>android/app/src/main/AndroidManifest.xml</read_first>
<action>
In `AndroidManifest.xml`:
- Update `android:label` to `fukatSongs`.
- Add permissions:
  `<uses-permission android:name="android.permission.INTERNET" />`
  `<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />`
  `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />`
</action>
<acceptance_criteria>
- `AndroidManifest.xml` contains `android:label="fukatSongs"`
- Permissions are present
</acceptance_criteria>
</task>
</tasks>

<verification>
Run `flutter pub get` and verify successful dependency resolution.
</verification>

<must_haves>
- [ ] Application renamed to fukatSongs
- [ ] Dependencies installed
</must_haves>
