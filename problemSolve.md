# 🛠️ problemSolve.md — fukatSongs

> A complete log of every error, bug, and challenge encountered during development — and exactly how each one was solved.

---

## Problem #1 — Syntax Error in `song_skeleton.dart`
### ❌ Error
`Can't find ')' to match '('`
### ✅ Fix
Located the unclosed bracket in `RepaintBoundary` and added the missing `)`.

---

## Problem #2 — `main_screen.dart` Import Path Wrong
### ❌ Error
`The system cannot find the file specified`
### ✅ Fix
Corrected imports from `features/main/presentation/main_screen.dart` to `features/main/main_screen.dart`.

---

## Problem #3 — `.w`, `.h`, `.sp` Extensions Undefined
### ❌ Error
`The getter 'w' isn't defined for the type 'int'`
### ✅ Fix
Replaced ScreenUtil extensions with plain pixel values in `splash_screen.dart`.

---

## Problem #4 — `Not a constant expression` Error
### ❌ Error
`MaterialPageRoute(builder: (_) => const MainScreen())` reported as non-constant.
### ✅ Fix
This was a secondary error from the broken import in Problem #2. Fixing the path fixed this.

---

## Problem #5 — `setAutomaticallyWaitToMinimizeStalling` Not Found
### ❌ Error
Method not defined for `AudioPlayer`.
### ✅ Fix
Removed the iOS-only method. Added Smart Pre-Buffer logic for Android instead.

---

## Problem #6 — `Song` Constructor Missing `year` Parameter
### ❌ Error
`Too few positional arguments`
### ✅ Fix
Added `year: ''` to the Song constructor in the YouTube parser.

---

## Problem #7 — Audio Stuttering at Song Start
### ❌ Problem
Audio was choppy for the first 5-10 seconds of a song.
### ✅ Fix
Implemented a **Smart Wait** loop that buffers 1.5 - 2 seconds of audio before calling `.play()`.

---

## Problem #8 — YouTube Rate Limiting / Blocked Streams
### ❌ Problem
YouTube blocks direct stream requests from the app's IP.
### ✅ Fix
**3-Stage Fallback**:
1. Stealth Tunnels (Piped Proxies)
2. Direct Extraction (youtube_explode)
3. Magic Switch (Search Saavn for match)

---

## Problem #10 — Gatekeeper Asked for Password Every Time
### ❌ Problem
Password screen appeared on every launch, not just the first time.
### ✅ Fix
Saved an `is_unlocked` flag in a Hive `auth` box after first successful entry.

---

## Problem #11 — Loudness Enhancer Causing Crackling
### ❌ Problem
Songs had digital clipping at high volumes.
### ✅ Fix
Reduced target gain from `1000mb` to `400mb` (+4dB boost).

---

## Problem #12 — Song Switching Lag & Audio Overlap
### ❌ Problem
When switching songs, the old song would keep playing while the new one loaded.
### ✅ Fix
Changed `audioHandler.pause()` to `await audioHandler.stop()` in `PlayerNotifier`. This instantly kills the old stream so the new one can load cleanly.

---

## Problem #13 — YouTube Fetching Too Slow (Lag on Poco M6 Pro)
### ❌ Problem
Waiting for 8 mirrors one-by-one took up to 60 seconds if mirrors were down.
### ✅ Fix
Implemented **Parallel Mirror Racing**. The app now launches 4 mirror requests at the same time and takes the **First Winner**. This reduced load time from 30s+ to ~2 seconds.

---

## Problem #14 — Duplicate Player Sheets Opening
### ❌ Problem
Tapping the mini-player quickly would open 2 or 3 copies of the player screen.
### ✅ Fix
Added an `_isPlayerOpen` guard flag in `openImmersivePlayer`. If the sheet is already open, new requests are ignored until it is closed.

---

## Problem #15 — App Icon Not Updated
### ❌ Request
Change the default Flutter icon to the new premium logo.
### ✅ Fix
Integrated `flutter_launcher_icons`, configured it in `pubspec.yaml`, and ran the generation script with the user's provided image.

---

*Last updated: May 2026 — fukatSongs Final Release*
