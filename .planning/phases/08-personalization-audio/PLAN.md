# Phase 8: Personalization & Audio (PLAN)

Implement settings persistence for audio quality and integrate a native equalizer.

## 1. Settings & Quality Persistence (SET)

### Task 1: Create Settings Model & Provider
- Create `lib/features/settings/models/app_settings.dart` (Freezed) with fields:
    - `streamingQuality`: String (e.g., '128', '320')
    - `downloadQuality`: String (e.g., '128', '320')
- Create `lib/features/settings/logic/settings_notifier.dart` (Riverpod):
    - Initialize from Hive box `settings`.
    - Methods to update qualities.
- **Verification:** Unit test for settings persistence.

### Task 2: Build Settings UI
- Create `lib/features/settings/presentation/settings_screen.dart`.
- Include ListTiles with dropdowns for Streaming and Download quality.
- Add "About" section.
- **Verification:** UI opens and saves values to Hive.

### Task 3: Integrate Quality into Providers
- Update `SaavnProvider.getStreamUrl` to use `AppSettings`.
- Inject `AppSettings` into `SaavnProvider` or pass quality as a parameter.
- **Verification:** Check `lib/test_yt.dart` style logs to see if correct bitrate URL is requested.

## 2. Audio Enhancement (AUD)

### Task 4: Equalizer Engine Integration
- Update `MusicAudioHandler`:
    - Add `AndroidEqualizer` or `Equalizer` effect to `just_audio`.
    - Note: `just_audio` supports `AndroidLoudnessEnhancer`, `AndroidEqualizer`.
    - Create a stream to expose EQ parameters.
- **Verification:** Log output showing EQ parameters being applied to the `AudioPlayer`.

### Task 5: Build Equalizer UI
- Create `lib/features/player/presentation/widgets/equalizer_sheet.dart`.
- Add 5-band frequency sliders.
- Add Presets (Bass Boost, Rock, Pop, etc.).
- **Verification:** Sliders update `AudioPlayer` state in real-time.

## Waves
1. **Wave 1:** Settings Model, Hive storage, and Logic.
2. **Wave 2:** Settings UI and Provider integration.
3. **Wave 3:** Equalizer Engine and UI.

## Requirements Addressed
- SET-01, SET-02, SET-03
- AUD-01, AUD-02
