---
wave: 3
depends_on: [02-STATE-MGMT-PLAN.md]
files_modified:
  - lib/features/search/presentation/search_screen.dart
  - lib/features/search/presentation/widgets/song_card.dart
autonomous: true
requirements_addressed: [SEARCH-03, SEARCH-07]
---

# Plan: Search UI Implementation

**Objective:** Build the visual search interface using "Deep Midnight" design and Visual Cards.

## Tasks

### 1. Create SongCard Widget
<read_first>
- lib/main.dart (Theme)
- lib/models/song.dart
</read_first>
<action>
Create `lib/features/search/presentation/widgets/song_card.dart`.
- Visual Card layout (1B).
- Large album art with rounded corners.
- Glassmorphism effect for text overlay or subtle background.
- Display: Title, Artist, Album, Duration.
- Use `CachedNetworkImage` (150x150).
</action>
<acceptance_criteria>
- Card looks premium (shadows, rounded corners).
- Images load efficiently.
- Text is readable on dark background.
</acceptance_criteria>

### 2. Implement SearchScreen
<read_first>
- lib/features/search/presentation/search_notifier.dart
</read_first>
<action>
Create `lib/features/search/presentation/search_screen.dart`.
- Search bar at top (Electric Indigo focus).
- Initial state: Horizontal list of Trending + Vertical list of History.
- Search state: `MasonryGridView` or `ListView` of `SongCard`s.
- Loading: Skeleton loaders.
- Error: "Retry" button.
</action>
<acceptance_criteria>
- Screen switches between Trending/History and Search Results seamlessly.
- Scrolling is smooth (60fps).
- Immediate playback on tap (stub for now if player not ready).
</acceptance_criteria>

## Verification
- Visual audit against Deep Midnight specs.
- Test scroll performance with 50+ results.

## Must Haves
- [ ] Visual Card layout
- [ ] Trending & History displays
- [ ] Smooth scrolling search results
- [ ] Deep Midnight styling (Indigo accents)
