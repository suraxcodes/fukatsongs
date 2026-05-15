# Phase 2: Saavn Search - Research

## API Integration

### Saavn (saavn.me v2)
- **Search URL**: `https://saavn.me/api/search/songs?query={query}`
- **Trending URL**: `https://saavn.me/api/modules?language=hindi,english`
- **Data Mapping**:
  - `id` -> `songId`
  - `name` -> `title`
  - `album.name` -> `albumName`
  - `year` -> `year`
  - `image[1].link` -> `imageUrl` (150x150 for performance)

### YouTube (youtube_explode_dart)
- **Search Method**: `YoutubeExplode().search.getVideos(query)`
- **Data Mapping**:
  - `id.value` -> `songId`
  - `title` -> `title`
  - `author` -> `artist`
  - `"YouTube Music"` -> `albumName`
  - `thumbnails.standardResUrl` -> `imageUrl`

## Parallelization & Resilience
- **Merging**: Use `Future.wait` to fire both requests simultaneously.
- **Retry**: Implement custom `Dio` interceptor for 3-retry logic on 5xx or connection timeout.
- **Caching**: Use `search_cache` Hive box to store results for 24h.

## UI & Presentation
- **Cards**: `Card` widget with `InkWell` for taps.
- **Image**: `CachedNetworkImage` with `BoxFit.cover`.
- **UX**: `TextField` with `onChanged` + `EasyDebounce`.
