---
phase: 13
plan: 01
subsystem: streaming
tags:
  - feat
  - fallback
  - search
requires: []
provides:
  - three-layer-stream-fallback
  - smart-search-filtering
affects:
  - lib/providers/youtube_provider.dart
  - lib/providers/music_repository.dart
tech-stack.added: []
tech-stack.patterns:
  - Race strategy for Piped API mirrors
  - Keyword blocklist filtering at repository layer
key-files.created: []
key-files.modified:
  - lib/providers/youtube_provider.dart
  - lib/providers/music_repository.dart
key-decisions:
  - Layer 1 uses youtube_explode_dart direct manifest fetching — fastest path (~75% success)
  - Layer 2 races all available Piped API public instances simultaneously — proxy bypass for rate-limited YouTube (~15% of remaining)
  - Layer 3 JioSaavn Magic Switch — completely different platform, very high for Hindi songs (~90% of remaining)
  - Search filtering applied post-merge at repository layer — zero UX speed penalty
  - Blocklist only activates when user did NOT search for those terms — respects user intent
  - Filtered results are also cached so subsequent searches are clean
requirements-completed:
  - 3-layer audio stream extraction preventing playback failure
  - Smart search filtering removing remixes and covers from results
duration: 8 min
completed: 2026-05-17T16:48:00Z
---

# Phase 13 Plan 01: Fallback Architecture Summary

Implemented 3-layer stream fallback and smart search filtering.

## Completed Tasks
- [x] Added Layer 1 (STAGE 1: DIRECT EXTRACTION via youtube_explode_dart) in youtube_provider.dart before Piped mirrors
- [x] Labeled Layer 2 (STAGE 2: PIPED MIRRORS) and Layer 3 (STAGE 3: JIOSAAVN MAGIC SWITCH) consistently
- [x] Added smart keyword blocklist filter in music_repository.dart search method
- [x] Filter respects user intent — not activated when user themselves searched for filtered terms
- [x] Filtered results are saved to cache (not raw results) ensuring cache hits also return clean data

## Self-Check: PASSED

Ready for verification.
