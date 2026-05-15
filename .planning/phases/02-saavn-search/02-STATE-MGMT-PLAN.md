---
wave: 2
depends_on: [01-API-PROVIDERS-PLAN.md]
files_modified:
  - lib/features/search/presentation/search_notifier.dart
autonomous: true
requirements_addressed: [SEARCH-02, SEARCH-05, SEARCH-06]
---

# Plan: Search State Management

**Objective:** Implement Riverpod logic for debounced searching, trending songs, and history.

## Tasks

### 1. Create SearchNotifier
<read_first>
- lib/providers/music_repository.dart
</read_first>
<action>
Create `lib/features/search/presentation/search_notifier.dart` using `@riverpod`.
- State: `AsyncValue<List<Song>>`.
- Method `search(String query)`:
  - Implement 500ms debounce.
  - Call `MusicRepository.search(query)`.
- Method `getTrending()`:
  - Initial state on empty query.
</action>
<acceptance_criteria>
- `SearchNotifier` correctly fetches and caches results.
- Rapid input doesn't spam APIs (debounce works).
</acceptance_criteria>

### 2. Implement Search History
<read_first>
- lib/main.dart (Hive boxes)
</read_first>
<action>
Integrate `search_cache` Hive box into `SearchNotifier`.
- Save successful queries (top 10).
- Expose history to the UI.
</action>
<acceptance_criteria>
- Queries are persisted across restarts.
- Max 10 items in history.
</acceptance_criteria>

## Verification
- Mock repository to verify debounce timing.
- Check Hive storage content after searches.

## Must Haves
- [ ] Debounced search (500ms)
- [ ] Trending songs on load
- [ ] 10-item search history (Hive)
