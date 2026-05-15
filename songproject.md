# Personal Music Streaming App

## Realistic Project Goal

Build a stable personal music streaming app for learning and personal use.

Main priorities:

1. Stable playback
2. Fast search
3. Reliable queue system
4. Offline playback
5. Simple architecture
6. Easy maintenance

NOT priorities:

* Fancy animations
* AI recommendations
* Complex cloud systems
* Overengineered backend
* Too many APIs initially

The goal is NOT to build Spotify.
The goal is to build a reliable personal music player.

---

# Biggest Problems To Solve

## Problem 1: Unofficial APIs Break

Reality:

* Saavn APIs can stop working
* YouTube Music internals change often
* Stream URLs expire
* Rate limits may happen

Solution:

* Build provider abstraction layer
* Add fallback providers
* Cache metadata locally
* Never depend on a single API

---

## Problem 2: Offline Download Reliability

Reality:

* Temporary stream URLs expire
* Downloads fail midway
* Different formats cause issues
* Metadata may be missing

Solution:

* Download actual audio file
* Validate file after download
* Store metadata separately
* Retry failed downloads
* Keep download queue manager

---

## Problem 3: Slow Search

Reality:

Searching one API at a time feels slow.

Bad:

```python
search_saavn()
if not found:
    search_youtube()
```

Better:

Search providers in parallel.

Example:

```python
results = await asyncio.gather(
    search_saavn(query),
    search_youtube(query)
)
```

Then:

* normalize results
* rank results
* remove duplicates

---

## Problem 4: Playback Stability

Reality:

Music apps fail mainly because of bad playback handling.

You must properly manage:

* queue
* buffering
* next song
* previous song
* shuffle
* repeat
* app background state
* audio interruptions

This is more important than UI.

---

# Final Recommended Architecture

## V1 Architecture

```txt
Flutter App
    ↓
Provider Layer
    ↓
Saavn Provider
YouTube Provider
    ↓
Local Cache
```

NO backend initially.

Reason:

* simpler
* faster development
* less maintenance
* fewer deployment problems

---

# When Backend Is Actually Needed

Add FastAPI backend ONLY if you need:

* proxy requests
* rate limiting
* centralized caching
* account system
* multi-device sync
* recommendations

Until then:

Do NOT build backend.

It wastes time early.

---

# Final Tech Stack

## Frontend

Flutter

Language:

* Dart

---

## State Management

Riverpod

Reason:

* scalable
* clean
* easier async handling

---

## Audio

Packages:

```yaml
just_audio
just_audio_background
audio_service
```

---

## Networking

```yaml
dio
```

Reason:

* retries
* interceptors
* better download handling

---

## Local Database

```yaml
hive
```

Use Hive for:

* playlists
* liked songs
* recent songs
* cache
* downloads metadata

---

## Image Caching

```yaml
cached_network_image
```

---

# Recommended Folder Structure

```txt
lib/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── services/
│
├── features/
│   ├── player/
│   ├── search/
│   ├── library/
│   ├── playlist/
│   ├── downloads/
│   └── settings/
│
├── models/
│
├── providers/
│
├── database/
│
└── main.dart
```

---

# Song Model

Create ONE normalized song model.

Example:

```dart
class Song {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final String streamUrl;
  final Duration duration;
  final String source;
}
```

Reason:

Every API returns different formats.
You must normalize data.

---

# Provider Architecture

## Correct Approach

```txt
Abstract Provider
    ↓
SaavnProvider
YouTubeProvider
```

---

## Example

```dart
abstract class MusicProvider {
  Future<List<Song>> search(String query);
}
```

---

# Search System

## WRONG Beginner Flow

```txt
Search Saavn
    ↓
If Failed
    ↓
Search YouTube
```

Problems:

* slow
* inconsistent results
* bad UX
* no smart ranking

---

## Correct Search Flow

```txt
User Search
    ↓
Search Multiple Providers In Parallel
    ↓
Normalize Results
    ↓
Remove Duplicates
    ↓
Filter Garbage Results
    ↓
Rank Results
    ↓
Show Best Results
```

---

# Real Example Flow

Example Search:

```txt
Tu Hi Hai
```

---

## Step 1: Parallel Search

Search BOTH providers simultaneously.

```txt
Saavn Provider
YouTube Provider
```

Reason:

Sequential search feels slow.

---

## Step 2: Providers Return Results

Example:

### Saavn

```txt
Tu Hi Hai - Arijit Singh
```

### YouTube

```txt
Tu Hi Hai Official Video
Tu Hi Hai Lyrics
Tu Hi Hai Slowed Reverb
```

---

## Step 3: Normalize Results

Convert ALL provider responses into ONE common model.

Example:

```dart
class Song {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final Duration duration;
  final Map<String, dynamic> providers;
}
```

Reason:

Every API has different response formats.

---

## Step 4: Filter Garbage Results

Especially important for YouTube.

Remove:

* slowed
* remix
* 8D
* fan edits
* lyrics videos
* low quality duplicates

---

## Step 5: Ranking System

Score songs using:

| Condition             | Score |
| --------------------- | ----- |
| Exact title match     | +50   |
| Exact artist match    | +40   |
| Official audio        | +20   |
| Verified source       | +15   |
| Remix/slowed keywords | -50   |

---

## Step 6: Select Primary Provider

Example:

### Saavn Result

```txt
Score = 95
```

### YouTube Result

```txt
Score = 82
```

Then:

```txt
Primary Provider = Saavn
Fallback Provider = YouTube
```

---

## Step 7: Store Song In Playlist

IMPORTANT:

Playlist should NOT store raw API response.

Wrong:

```txt
This is a Saavn song
```

Correct:

```txt
This is a song with multiple providers
```

---

## Correct Playlist Storage Example

```json
{
  "title": "Tu Hi Hai",
  "artist": "Arijit Singh",
  "providers": {
    "saavn": {
      "id": "123"
    },
    "youtube": {
      "id": "abc"
    }
  },
  "primaryProvider": "saavn"
}
```

---

## Step 8: Playback Flow

```txt
Try Primary Provider
    ↓
Playback Failed?
    ↓
Automatically Switch To Fallback Provider
```

User should not notice provider switching.

---

## Why This Architecture Matters

Suppose:

* Saavn breaks
* stream URL expires
* provider becomes unavailable

Your playlists STILL work because:

* backup providers exist

This is the correct scalable architecture.

---

# Duplicate Removal Logic

Different APIs may return same song.

Use:

* title similarity
* artist similarity
* duration similarity

Example:

```txt
Kesariya - Arijit
Kesariya (Official) - Arijit Singh
```

These are likely same song.

---

# Queue System

You NEED a dedicated queue manager.

## Queue Features

* next song
* previous song
* shuffle queue
* repeat one
* repeat all
* autoplay next

---

# Correct Shuffle Logic

WRONG:

```dart
songs.shuffle();
```

Reason:

* destroys original order
* hard to restore queue

Correct:

Maintain:

```txt
originalQueue
shuffledQueue
```

---

# Offline Download System

## Correct Download Flow

```txt
Get Stream URL
    ↓
Download File
    ↓
Validate File
    ↓
Store Metadata
    ↓
Save Local Path
```

---

# Download Metadata Example

```json
{
  "songId": "123",
  "localPath": "/storage/music/test.mp3",
  "downloadedAt": "date"
}
```

---

# Download Manager Requirements

You need:

* pause download
* resume download
* retry failed download
* delete download
* check file exists

---

# Stream URL Expiration

Many unofficial APIs provide temporary stream URLs.

Problem:

```txt
Saved stream URL today
May fail tomorrow
```

Correct approach:

* NEVER permanently store stream URLs
* Store provider IDs instead
* Fetch fresh stream URL before playback

Example:

```json
{
  "songId": "123",
  "provider": "saavn"
}
```

Then:

```txt
Playback Request
    ↓
Fetch Fresh Stream URL
    ↓
Start Playback
```

---

# Audio Buffering Strategy

You must handle:

* slow internet
* buffering
* stalled streams
* request timeout
* playback retry

Required:

* loading states
* retry handling
* timeout handling
* buffering indicator

---

# Background Audio Interruptions

Handle:

* incoming calls
* headphones removed
* Bluetooth disconnect
* notification interruptions

Example:

```txt
Headphones Removed
    ↓
Pause Music Automatically
```

---

# Search Debouncing

Without debounce:

Every keystroke sends API requests.

Bad:

```txt
A
Ar
Ari
Arijit
```

Correct:

Use debounce delay:

```txt
300ms
```

Reason:

* fewer requests
* smoother search
* less API spam

---

# API Rate Limit Protection

Unofficial APIs may block excessive requests.

Add:

* request throttling
* retry limits
* caching
* cooldown handling

---

# Queue Persistence

If app closes:

Restore:

* current song
* playback position
* playback queue
* repeat state
* shuffle state

Spotify-like behavior improves UX.

---

# Download File Management

You must handle:

* duplicate downloads
* corrupted downloads
* deleted files
* storage full
* failed downloads

Required:

* file validation
* existence checks
* retry system
* delete management

---

# Storage Permissions

Android storage handling is important.

Decide:

## Option 1

App-specific storage.

Pros:

* simpler
* safer

Cons:

* files hidden from user

---

## Option 2

Public music folder.

Pros:

* user-visible files

Cons:

* more permission complexity

---

# Metadata Consistency

Different providers return inconsistent metadata.

Example:

```txt
Arijit Singh
Arijit
A. Singh
```

You need normalization logic.

Normalize:

* artist names
* song titles
* durations
* album names

---

# Image Loading Optimization

Album arts can hurt performance.

Required:

* image caching
* lazy loading
* thumbnail optimization

Use:

```yaml
cached_network_image
```

---

# Download Format Handling

Providers may return:

* mp3
* m4a
* opus
* webm

You need:

* format compatibility checks
* playback validation
* fallback handling

---

# Search Result Pagination

Large searches may return hundreds of songs.

Example:

```txt
Arijit
```

Need:

* pagination
  OR
* lazy loading

---

# Error Logging

You need debugging logs.

Track:

* provider failures
* playback failures
* download failures
* API timeouts

Without logs debugging becomes difficult.

---

# Memory Leak Prevention

Music apps can leak:

* listeners
* streams
* controllers
* audio sessions

Important:

Dispose resources correctly.

---

# Network Switching Handling

Handle:

```txt
WiFi → Mobile Data
```

During playback.

App should:

* reconnect
* retry stream
* continue playback when possible

---

# Failure-First Architecture Mindset

Your app should assume:

* providers fail
* URLs expire
* playback fails
* downloads fail
* internet disconnects

The app must recover gracefully.

---

# Cache System

VERY IMPORTANT.

Without caching:

* app feels slow
* APIs get spammed
* battery usage increases

---

# Cache These Things

## Metadata Cache

Store:

* song info
* artist info
* albums

---

## Search Cache

Store recent search results.

Example:

```txt
query: arijit
results: [...]
```

---

## Image Cache

Use:

```yaml
cached_network_image
```

---

# Playback Manager

Create ONE global audio manager.

Do NOT create multiple audio players.

Bad:

```dart
final player = AudioPlayer();
```

inside many screens.

Correct:

Single shared player service.

---

# UI Plan

## V1 Screens

### 1. Home

Sections:

* recent songs
* liked songs
* playlists

---

### 2. Search

Features:

* search bar
* recent searches
* results list

---

### 3. Player

Features:

* artwork
* play/pause
* next/previous
* seek bar
* shuffle
* repeat

---

### 4. Library

Features:

* playlists
* downloads
* favorites

---

# Features To IGNORE Initially

Do NOT build these first:

* lyrics sync
* equalizer
* recommendations
* Firebase
* account system
* cloud sync
* themes
* social features
* animations

Reason:

They do not solve core stability.

---

# Actual Development Plan

# Phase 1

## Project Setup

Tasks:

* install Flutter
* setup Riverpod
* setup Hive
* setup audio packages
* create folder structure
* create Song model

Goal:

App boots successfully.

---

# Phase 2

## Saavn Integration

Tasks:

* connect Saavn API
* search songs
* display results
* normalize song model

Goal:

Search works reliably.

---

# Phase 3

## Audio Playback

Tasks:

* play song
* pause song
* seek bar
* background playback
* queue system

Goal:

Stable playback.

---

# Phase 4

## Playlist + Likes

Tasks:

* create playlist
* add/remove songs
* like songs
* recent songs tracking

Goal:

Library system works.

---

# Phase 5

## Offline Downloads

Tasks:

* download songs
* save locally
* play offline
* download manager

Goal:

Reliable offline playback.

---

# Phase 6

## YouTube Fallback

Tasks:

* integrate YouTube Music provider
* parallel search
* fallback logic
* duplicate filtering

Goal:

Search reliability improves.

---

# Phase 7

## Optimization

Tasks:

* metadata cache
* image cache
* search cache
* loading optimization
* queue optimization

Goal:

Fast smooth app.

---

# Recommended Packages

## Core

```yaml
flutter_riverpod
hive
hive_flutter
dio
```

---

## Audio

```yaml
just_audio
audio_service
just_audio_background
```

---

## Downloads

```yaml
path_provider
permission_handler
```

---

## UI

```yaml
cached_network_image
flutter_screenutil
```

---

# Security Reality

Do NOT hardcode:

* API keys
* secret URLs
* tokens

Even for personal apps.

---

# Final Realistic Goal

Build:

* stable player
* fast search
* reliable playlists
* good offline support

Ignore everything else initially.

If V1 becomes stable,
THEN add:

* lyrics
* equalizer
* backend
* sync
* recommendations

---

# Most Important Rule

DO NOT chase features.

Focus on:

1. playback stability
2. queue management
3. caching
4. offline reliability
5. simple architecture

That is what makes music apps hard.
Not UI.

---

# Local Data Storage Architecture

This app is designed as an offline-first local app.

Initially:

* NO backend
* NO Firebase
* NO cloud sync

Everything saves locally on the user device.

---

# What Hive Stores

Hive stores lightweight app data.

Use Hive for:

* playlists
* liked songs
* recent songs
* playback queue state
* cached metadata
* download metadata
* settings

Example:

```json
{
  "playlistName": "Workout",
  "songs": []
}
```

---

# What Device Storage Stores

Actual audio files are NOT stored inside Hive.

Audio files are stored in phone storage.

Example:

```txt
Android/data/app_name/music/
```

OR

```txt
Music/AppName/
```

depending on storage strategy.

---

# Download Storage Flow

```txt
Fetch Stream URL
    ↓
Download Audio File
    ↓
Save Audio File To Device Storage
    ↓
Save Metadata + File Path To Hive
```

---

# Download Metadata Example

```json
{
  "songId": "123",
  "localPath": "/storage/emulated/0/Music/test.mp3"
}
```

---

# Playback State Persistence

Save:

* current song
* playback position
* queue
* repeat state
* shuffle state

This allows app recovery after reopening.

Example:

```json
{
  "currentSong": "abc",
  "position": 120,
  "shuffle": true
}
```

---

# Offline Behavior

Without internet the app should still support:

* downloaded songs
* playlists
* liked songs
* recent songs
* queue state
* cached metadata

Streaming search requires internet.

---

# App Uninstall Behavior

Without cloud sync:

App uninstall removes:

* playlists
* cache
* downloads
* likes
* settings

This is acceptable for V1.

---

# Why Local-Only Architecture Is Better For V1

Advantages:

* simpler architecture
* faster development
* no server costs
* easier debugging
* better offline support
* fewer failure points

---

# Future Upgrade Path

Backend/cloud can be added later for:

* account system
* multi-device sync
* cloud playlists
* recommendations
* analytics

But NOT required for V1.
