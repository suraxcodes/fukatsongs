# Plan: Phase 9 (Smart Home UI)

## Wave 1: Persistence & Tracking
- [ ] **HOME-01**: Initialize `history` Hive box in `main.dart`.
- [ ] **HOME-02**: Implement `HistoryRepository` to handle search and playback history.
- [ ] **HOME-03**: Integrate playback tracking in `PlayerNotifier` (add song to history when played).
- [ ] **HOME-04**: Integrate search tracking in `SearchNotifier` (save query on search).

## Wave 2: Home Logic & Data
- [ ] **HOME-05**: Create `HomeNotifier` (Riverpod) to fetch "Quick Picks" and "Trending" songs.
- [ ] **HOME-06**: Update `SearchNotifier` to include `recentSearches` in its state.

## Wave 3: Premium UI Components
- [ ] **HOME-07**: Build `GlassContainer` and `PremiumSectionHeader` widgets.
- [ ] **HOME-08**: Update `SearchScreen` to show Recent Searches list.

## Wave 4: Home Screen Overhaul
- [ ] **HOME-09**: Implement the new Home Screen layout with "Quick Picks" grid.
- [ ] **HOME-10**: Add glassmorphic "Trending" section with high-quality artwork.

## Verification
- [ ] Verify search history saves and loads correctly.
- [ ] Verify "Quick Picks" updates after playing a song.
- [ ] Perform a visual audit of the Home screen against premium design standards.
