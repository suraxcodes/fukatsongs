---
wave: 1
depends_on: []
files_modified:
  - lib/features/main/main_screen.dart
  - lib/features/library/presentation/library_screen.dart
  - lib/main.dart
autonomous: true
requirements_addressed: [UI-01, LIB-01]
---

# Plan: Main Navigation & Scaffolding

**Objective:** Implement the bottom navigation bar to support switching between Search and the new Library screen.

## Tasks

### 1. Create MainScreen
<action>
Create `lib/features/main/main_screen.dart`.
- `StatefulWidget` to manage `currentIndex`.
- Use `Scaffold` with `bottomNavigationBar`.
- Use `IndexedStack` as the body with:
  1. `SearchScreen`
  2. `LibraryScreen`
- Persistent `MiniPlayer` should be moved here to stay above the tabs.
</action>
<acceptance_criteria>
- Navigation bar switches between screens without losing Search state.
- MiniPlayer remains visible and active across both tabs.
</acceptance_criteria>

### 2. Create LibraryScreen Placeholder
<action>
Create `lib/features/library/presentation/library_screen.dart`.
- Simple UI showing "Your Library" header.
- Placeholder for the list of downloaded songs.
</action>
<acceptance_criteria>
- "Library" text is visible when switching tabs.
</acceptance_criteria>

### 3. Update main.dart Home
<read_first>
- lib/main.dart
</read_first>
<action>
Change the `home` of `MaterialApp` to `MainScreen`.
</action>
<acceptance_criteria>
- App launches with the bottom navigation bar.
</acceptance_criteria>

## Verification
- Manual verification of tab switching.
- Ensure Search results stay valid when switching back from Library.

## Must Haves
- [ ] Working BottomNavigationBar
- [ ] IndexedStack for state preservation
- [ ] MainScreen as the new entry point
