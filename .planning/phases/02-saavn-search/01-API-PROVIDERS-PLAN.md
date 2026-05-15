---
wave: 1
depends_on: []
files_modified:
  - lib/providers/saavn_provider.dart
  - lib/providers/youtube_provider.dart
  - lib/providers/music_repository.dart
autonomous: true
requirements_addressed: [SEARCH-01, SEARCH-02, SEARCH-04]
---

# Plan: Saavn & YouTube API Providers

**Objective:** Implement concrete `MusicProvider` implementations for Saavn and YouTube, and a repository to merge results.

## Tasks

### 1. Implement SaavnProvider
<read_first>
- lib/providers/music_provider.dart
- lib/models/song.dart
</read_first>
<action>
Create `lib/providers/saavn_provider.dart` implementing `MusicProvider`.
- Base URL: `https://saavn.me/api`
- Search: `/search/songs?query={query}`
- Trending: `/modules?language=hindi,english`
- Map JSON to `Song` model.
- Use `image[1].link` (150x150).
- Add 3-retry logic using `Dio` or custom loop.
</action>
<acceptance_criteria>
- `SaavnProvider.search()` returns a list of `Song` objects.
- Retries on 5xx errors.
- Image URLs are from the 150x150 index.
</acceptance_criteria>

### 2. Implement YouTubeProvider
<read_first>
- lib/providers/music_provider.dart
</read_first>
<action>
Create `lib/providers/youtube_provider.dart` implementing `MusicProvider`.
- Use `youtube_explode_dart`.
- Search: `yt.search.getVideos(query)`.
- Stream URL: `yt.videos.streamsClient.getManifest(songId)`.
- Map to `Song` model (Album = "YouTube Music").
</action>
<acceptance_criteria>
- `YouTubeProvider.search()` returns normalized `Song` objects.
</acceptance_criteria>

### 3. Implement MusicRepository
<action>
Create `lib/providers/music_repository.dart`.
- Aggregates `SaavnProvider` and `YouTubeProvider`.
- `search(query)` calls both in parallel using `Future.wait`.
- Merges and removes duplicates.
- Provides `getTrending()` from Saavn.
</action>
<acceptance_criteria>
- `MusicRepository.search()` returns results from both providers.
- Trending results only come from Saavn (or combined if preferred).
</acceptance_criteria>

## Verification
- Unit test for `SaavnProvider` parsing.
- Unit test for `YouTubeProvider` mapping.
- Verify parallel execution in `MusicRepository`.

## Must Haves
- [ ] Saavn search integration
- [ ] YouTube search integration
- [ ] Normalized Song objects
- [ ] Parallel search execution
