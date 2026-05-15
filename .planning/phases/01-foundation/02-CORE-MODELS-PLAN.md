# Plan: Core Models

**ID:** 02-CORE-MODELS
**Wave:** 2
**Depends on:** 01-PROJECT-SETUP
**Requirements addressed:** SETUP-04
**Files modified:** lib/models/song.dart, lib/providers/music_provider.dart
**Autonomous:** true

<objective>
Define the core Song model with persistence support and the MusicProvider abstraction layer.
</objective>

<tasks>
<task>
<read_first>.planning/phases/01-foundation/01-RESEARCH.md</read_first>
<action>
Create `lib/models/song.dart`:
- Implement `Song` class using `@freezed` and `@HiveType(typeId: 0)`.
- Include fields: `id`, `title`, `artist`, `albumName`, `year`, `imageUrl`, `duration`, `source`, `providers`, `localPath`.
- Run `flutter pub run build_runner build` to generate adapters.
</action>
<acceptance_criteria>
- `lib/models/song.freezed.dart` and `lib/models/song.g.dart` exist.
- `Song` class has all 10 specified fields.
</acceptance_criteria>
</task>

<task>
<read_first>lib/providers/music_provider.dart</read_first>
<action>
Create `lib/providers/music_provider.dart`:
- Define `abstract class MusicProvider`.
- Methods: `Future<List<Song>> search(String query)`, `Future<String?> getStreamUrl(String songId)`.
</action>
<acceptance_criteria>
- `lib/providers/music_provider.dart` defines the abstract interface.
</acceptance_criteria>
</task>
</tasks>

<verification>
Run `flutter pub run build_runner build` and ensure no generation errors.
</verification>

<must_haves>
- [ ] Song model with Hive adapters generated
- [ ] MusicProvider interface defined
</must_haves>
