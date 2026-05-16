# Context: Phase 9 (Smart Home UI)

## Objective
Evolve the Home screen into a personalized, premium dashboard that tracks user activity (history, recent searches) and presents it with high-end "glassmorphism" aesthetics.

## Key Requirements
1. **Recent Searches**:
    - Persist search queries in a Hive box.
    - Show recent searches in a horizontal list on the Home/Search screen.
    - Allow clearing individual history items.
2. **Recently Played (Quick Picks)**:
    - Track songs as they are played (trigger from `PlayerNotifier`).
    - Show a 2x3 or 3x2 grid of "Quick Picks" on the Home Screen.
    - YouTube Music style: Large artwork with title/artist.
3. **Home Screen UI Overhaul**:
    - Replace the basic list/grid with a premium layout.
    - Sections: "Quick Picks", "Trending Now", "Recent Searches".
    - Design tokens: Glassmorphism containers, smooth gradients, and vibrant colors.

## Success Criteria
- [ ] User can see their last 5 search queries on the Search Screen.
- [ ] Tapping a "Recent Search" immediately triggers that search.
- [ ] Playing a song adds it to "Quick Picks" on the Home Screen.
- [ ] Home Screen uses rich aesthetics (Google Fonts, gradients, blur effects).

## Technical Strategy
- **Persistence**: Use Hive box `history` for both searches and playback history.
- **State**: Create `HomeNotifier` to aggregate history and trending data.
- **UI**: Implement `GlassContainer` utility widget for reuse.
