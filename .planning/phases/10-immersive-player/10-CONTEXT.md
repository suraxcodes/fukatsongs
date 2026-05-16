# Context: Phase 10 (Immersive Player)

## Objective
Create a flagship full-screen player that automatically appears when music starts, featuring glassmorphic controls and clear metadata indicators.

## Key Requirements
1. **Auto-Expansion**: When a user taps a song, the player should slide up from the bottom (using a modal or a custom route animation).
2. **Dynamic UI**: Large, high-resolution artwork (cached) with a soft glow effect.
3. **Metadata Badges**: Show the streaming provider icon (YouTube/Saavn) and the current bitrate (e.g., 320kbps).
4. **Queue Integration**: A "Up Next" preview at the bottom that shows the next song in the queue.
5. **Interactive Controls**: Smooth seek bar, shuffle/repeat toggles, and large playback buttons.

## Success Criteria
- [ ] Tapping a song from Home/Search opens the Full Player.
- [ ] Player shows a "YouTube" or "Saavn" badge based on the active provider.
- [ ] User can swipe down to dismiss the player back to the MiniPlayer.
