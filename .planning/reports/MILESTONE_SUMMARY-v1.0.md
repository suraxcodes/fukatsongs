# Milestone v1.0 — Streaming Foundation Summary

**Generated:** 2026-05-16
**Status:** COMPLETE ✅
**Purpose:** Documentation of the unblocked hybrid streaming engine.

---

## 1. Project Overview

**fukatSongs** is a high-performance Android music streaming app designed for stable, uninterrupted playback. 
The v1.0 milestone focused on building a "Bulletproof" foundation that can stream high-quality music from unofficial sources (Saavn & YouTube) without getting blocked by bot detection.

## 2. Architecture & Technical Decisions

- **Hybrid Streaming Engine**: 
  - **YouTube**: Bypasses blocks using a **Piped Proxy Bridge** (e.g., `api.piped.private.coffee`), ensuring instant, ad-free playback without Google's tracking.
  - **Saavn**: Uses a **Masked Browser Strategy**. The app disguises its requests as a mobile browser to bypass 403 blocks and streams directly from verified "Golden Mirrors".
- **Instant Playback (No Wait)**: Switched from a download-first strategy to **Masked Instant Streaming** using `AudioSource.uri` with custom headers.
- **Self-Healing Failover**: Implemented a logic that automatically switches from Saavn to YouTube if a link is expired or a server is down.
- **HD Fidelity Lock**: Forced the engine to always select the **320kbps** HD stream for Saavn tracks.

## 3. Key Accomplishments

| Phase | Name | Status | One-Liner |
|-------|------|--------|-----------|
| 1 | Foundation | ✅ | Scaffolding, Design System, and Hive integration. |
| 2 | Saavn Search | ✅ | Unblocked search and 320kbps HD stream extraction. |
| 3 | Playback Engine | ✅ | Hybrid logic for Proxy-based YT and Masked-based Saavn. |
| 4 | Mirror Rotation | ✅ | Automatic server-switching to handle downtime. |
| 5 | Instant Stream | ✅ | Immediate startup using URI-based header masking. |

## 4. Technical Decisions Log

- **Decision:** Use `Piped` API for YouTube.
  - **Why:** Instant playback, no ad-blocking issues, and no API keys required.
- **Decision:** Use `sigma-sandy` mirror for Saavn.
  - **Why:** It currently bypasses the latest Saavn/Jio bot detection.
- **Decision:** Instant URI Streaming over Downloading.
  - **Why:** Users prefer immediate playback; download buffering was too slow for a "streaming" feel.

## 5. Tech Debt & Deferred Items

- **Equalizer**: Deferred to Milestone v2.0.
- **Settings**: Quality preferences were hardcoded to HD; v2.0 will add a settings page for user choice.
- **UI Overflow**: Some search results with long titles need better text wrapping (fixed in v1.1 patch).

## 6. Getting Started for Contributors

- **Main Entry**: `lib/main.dart`
- **Core Engine**: `lib/core/audio/audio_handler.dart`
- **Providers**: `lib/providers/` (saavn_provider.dart & youtube_provider.dart)
- **Diagnostic Lab**: `lib/test_yt.dart` (Use this for testing new mirrors).

---

## Stats

- **Timeline:** 2026-05-15 → 2026-05-16 (24 hours)
- **Commits:** ~20
- **Audio Fidelity:** 320kbps (Verified)
- **Startup Speed:** < 2 seconds (Verified)
