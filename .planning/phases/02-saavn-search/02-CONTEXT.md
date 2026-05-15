# Phase 2: Saavn Search - Context

**Gathered:** 2026-05-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Implementing the search engine for fukatSongs, including parallel API integrations (Saavn + YouTube) and a visual Search UI. This phase covers trending songs discovery, recent search history, and immediate playback triggering.

</domain>

<decisions>
## Implementation Decisions

### API & Providers
- **D-01:** Primary Saavn API: `saavn.me` (v2).
- **D-02:** Secondary Provider: YouTube Music via `youtube_explode_dart`.
- **D-03:** Parallel Execution: Search results from both providers must be merged and displayed in a unified list.
- **D-04:** Resilience: Automatic 3-retry logic for all API search calls using `Dio` interceptors or custom retry logic.

### Search UI & Performance
- **D-05:** Layout: Vertical list of **Visual Cards** with large album art.
- **D-06:** Image Quality: Use **150x150** resolution for search result art to prioritize scroll performance and data efficiency.
- **D-07:** Interaction: Tapping a song card **triggers immediate playback** (clears queue and starts playing).

### Search UX
- **D-08:** Initial Screen: Display **Trending Songs** (fetched from Saavn) when the search bar is empty.
- **D-09:** Search History: Persist the last **10 search queries** in the `search_cache` Hive box and display them as suggestions.
- **D-10:** Input Behavior: Implement a **500ms debounce** on the search input to avoid excessive API calls.

### the agent's Discretion
- Exact layout of the "Trending" section (e.g., horizontal scroll vs vertical list).
- Merging logic/sorting for parallel results (e.g., prioritize exact title matches).
- UI for the retry state/loading skeletons.

</decisions>

<canonical_refs>
## Canonical References

### Provider Docs
- `lib/providers/music_provider.dart` — Base interface to implement.
- `lib/models/song.dart` — Model to populate from API responses.

### Project Context
- `.planning/PROJECT.md` — Parallel search requirement.
- `.planning/REQUIREMENTS.md` — SEARCH-01 to SEARCH-03.

</canonical_refs>
