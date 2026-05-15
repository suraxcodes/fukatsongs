# Phase 1: Foundation - Validation

**Date:** 2026-05-15
**Status:** Active

## Phase Goal
App boots with correct structure, Song model defined, and Hive initialized.

## Automated Verification (Nyquist Dimension 8)

### 1. Structure Verification
- [ ] Directory `lib/core/theme` exists
- [ ] Directory `lib/features/home` exists
- [ ] Directory `lib/models` exists

### 2. Dependency Verification
- [ ] `pubspec.yaml` contains `flutter_riverpod`, `just_audio`, `audio_service`, `hive_flutter`
- [ ] `pubspec.yaml` contains `freezed`, `build_runner` in dev_dependencies

### 3. Build & Generation
- [ ] `lib/models/song.freezed.dart` exists after build_runner
- [ ] `lib/models/song.g.dart` exists after build_runner

### 4. Android Integrity
- [ ] `android/app/src/main/AndroidManifest.xml` contains `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
- [ ] `android/app/build.gradle` contains `applicationId "com.fukatsongs.app"`

## UAT Criteria (Conversational)
- "Does the app open to a black/indigo screen without crashing?"
- "Can I see 'fukatSongs' as the app name in the Android launcher?"
- "Do the logs show all 8 Hive boxes opened successfully?"
