---
wave: 2
depends_on: [01-AUDIO-SERVICE-PLAN.md]
files_modified:
  - lib/features/player/logic/queue_manager.dart
autonomous: true
requirements_addressed: [PLAY-04, PLAY-05]
---

# Plan: Queue Persistence & Logic

**Objective:** Implement a robust queue system that handles shuffling and survives app restarts.

## Tasks

### 1. Create QueueManager
<read_first>
- lib/models/song.dart
</read_first>
<action>
Create `lib/features/player/logic/queue_manager.dart`.
- Manages `originalQueue` and `shuffledQueue`.
- Logic for `shuffle()` (toggle without destroying original order).
- `playNext(Song)`, `addToQueue(Song)`, `removeFromQueue(int index)`.
- Interacts with `AudioHandler` to update its queue.
</action>
<acceptance_criteria>
- Shuffling can be toggled on/off while maintaining state.
- Adding songs updates the active queue in the audio handler.
</acceptance_criteria>

### 2. Implement Hive Persistence
<read_first>
- lib/main.dart (Hive boxes)
</read_first>
<action>
Integrate `queue_state` Hive box.
- Save current song ID and entire queue (list of IDs) on every change.
- Restore queue on app launch (in `build()` of PlayerNotifier or during init).
</action>
<acceptance_criteria>
- App restores the last played song and queue list after restart.
</acceptance_criteria>

## Verification
- Unit test for shuffle logic (original vs shuffled indices).
- Manual verification of queue persistence after app kill.

## Must Haves
- [ ] Non-destructive shuffle
- [ ] Hive persistence for queue
- [ ] Sync between Logic and AudioHandler
