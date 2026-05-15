---
wave: 3
depends_on: [02-QUEUE-LOGIC-PLAN.md]
files_modified:
  - lib/features/player/presentation/widgets/mini_player.dart
  - lib/features/player/presentation/player_screen.dart
autonomous: true
requirements_addressed: [PLAY-06, PLAY-07]
---

# Plan: Player UI Implementation

**Objective:** Build the persistent mini-player and the expanded full-screen player.

## Tasks

### 1. Build MiniPlayer Widget
<read_first>
- lib/features/player/presentation/player_notifier.dart
</read_first>
<action>
Create `lib/features/player/presentation/widgets/mini_player.dart`.
- Persistent bar with 64.h height.
- Album art (circular or rounded).
- Title & Artist scroll (Marquee if needed).
- Play/Pause toggle.
- Progress indicator (linear, 2px height at top).
- On tap: Expand to `PlayerScreen`.
</action>
<acceptance_criteria>
- Appears only when a song is loaded.
- Stays at the bottom across all screens.
</acceptance_criteria>

### 2. Implement PlayerScreen
<action>
Create `lib/features/player/presentation/player_screen.dart`.
- Large Artwork (300x300).
- Seek Bar (using `ProgressBar` or custom slider).
- Controls: Shuffle, Prev, Play/Pause, Next, Repeat.
- Current Queue list (swipe up or bottom sheet).
- Glassmorphism styling.
</action>
<acceptance_criteria>
- Seek bar accurately reflects and controls position.
- Controls correctly trigger `PlayerNotifier` methods.
- Layout follows Deep Midnight brand.
</acceptance_criteria>

### 3. Integrate into App Scaffold
<read_first>
- lib/main.dart
</read_first>
<action>
Wrap the main app content in a `Stack` or use a custom `Scaffold` to host the persistent `MiniPlayer`.
</action>
<acceptance_criteria>
- MiniPlayer doesn't overlap search results (add padding to bottom).
</acceptance_criteria>

## Verification
- Visual audit of progress bar smoothness.
- Check tap targets for controls.

## Must Haves
- [ ] Persistent MiniPlayer
- [ ] Full-screen Player Screen
- [ ] Working Seek Bar
- [ ] Indigo-themed UI
