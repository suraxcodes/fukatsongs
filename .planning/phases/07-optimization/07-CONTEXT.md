# Phase 07: Optimization & Polish - Context

**Gathered:** 2026-05-15
**Status:** Ready for planning

<domain>
## Phase Boundary
Implementation of persistent caching (search/metadata/images), network resilience (timeouts/retries), adaptive offline UI, and premium visual polish (glassmorphism).
</domain>

<decisions>
## Implementation Decisions

### Smart Caching (TTL)
- **D-01:** Search results stored in Hive with 30-min TTL.
- **D-02:** Song metadata cached for 24 hours.
- **D-03:** `cached_network_image` configured for 7-day retention.
- **D-04:** NEVER cache stream URLs (fetch fresh at runtime).

### Network & Offline Behavior
- **D-05:** Adaptive Search: Automatic pivot to Library-only search when offline.
- **D-06:** Resilience: Implement Dio interceptors for 15s timeouts and automatic retry on 5xx errors.

### Premium UI Polish
- **D-07:** Glassmorphic skeletons: Use `shimmer` + custom `GlassContainer` for all loading states.
- **D-08:** Smooth Transitions: Implement shared-axis transitions for screen navigation.

</decisions>

<canonical_refs>
## Canonical References
- `lib/providers/music_repository.dart` — Caching layer location
- `lib/features/search/presentation/search_screen.dart` — Offline pivot logic
- `lib/main.dart` — Global Dio/Theme configuration
</canonical_refs>
