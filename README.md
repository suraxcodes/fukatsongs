<div align="center">

# FukatMusic

### Your playlists. More ways to listen.

An Android music player that brings playlist imports, extensible music sources, local playback, and hands-free controls into one listening experience.

**Android · Flutter + Rust · Plugin-powered**

[Explore Releases](https://github.com/suraxcodes/fukatsongs/releases) · [Report an Issue](https://github.com/suraxcodes/fukatsongs/issues) · [View Source](https://github.com/suraxcodes/fukatsongs)

</div>

---

## Built around the way you listen

Your music collection does not have to begin and end with a single source.

FukatMusic helps you bring playlists together, discover music through installed providers, and play the files already on your device. When an online track fails, automatic source fallback can look for a matching recording elsewhere—without replacing the song in your saved playlist.

Add hands-free voice controls, an equalizer, crossfade, and a floating player, and you have a music app designed to make everyday listening more convenient.

## What makes FukatMusic different

### More than one way to play a song

A broken stream should not always mean the end of a song.

With automatic source fallback enabled, FukatMusic can search loaded providers for another matching track when the original fails. Matching considers song titles, available artist credits, duration, and version information to help avoid unrelated recordings.

- Tries alternatives without changing the original saved playlist entry.
- Can consider a different track from the same provider.
- Allows additional artist credits instead of requiring identical credit lists.
- Uses bounded attempts rather than retrying indefinitely.

**Availability still depends on your providers, connection, region, and the quality of the track metadata. Fallback cannot guarantee a playable match for every song.**

### Bring your playlists with you

Import supported playlists from services such as **YouTube Music and Spotify**, then listen using the playback sources available in FukatMusic.

Playlist import brings track information into your library. It is not a transfer of a subscription, music licence, or guaranteed access to the original service’s audio.

### Control playback with your voice

Enable hands-free mode to use supported voice commands without repeatedly opening the player.

- One-time download of an approximately **39 MB offline voice model**.
- On-device voice recognition after setup; online music still needs a connection.
- A built-in command reference based on the app’s actual recognition grammar.
- Access the command list through Settings or by long-pressing the microphone icon.

Microphone permission is required. Background listening can be affected by Android battery restrictions and device-specific behaviour.

### Make the player your own

| Feature | What it brings to your listening |
|---|---|
| **Local music playback** | Listen to supported music files stored on your device. |
| **Equalizer** | Adjust the sound to your preferences. |
| **Crossfade** | Blend transitions between tracks. |
| **Sleep timer** | Set listening to end after your chosen interval. |
| **Lyrics** | View lyrics when a compatible provider has them available. |
| **Background playback** | Keep listening while using other apps. |
| **Notification controls** | Access playback controls without returning to the app. |
| **Floating player overlay** | Keep playback controls within reach with the Android Dynamic Island-style overlay. |

Some features require permissions, compatible providers, or device support.

## A player that grows through plugins

FukatMusic uses a **Rust-backed WebAssembly plugin system** to extend what the app can do.

Depending on the plugins you install and enable, providers can add music search and playback, lyrics, charts, playlist imports, and search suggestions. Available source integrations include YouTube Music, YouTube Video, and JioSaavn.

The app and its providers are separate parts of the experience: a provider may change, become unavailable, or return different results over time. Install plugins only from repositories you trust.

## Get started

1. **Visit [Releases](https://github.com/suraxcodes/fukatsongs/releases).** Choose an available Android APK and read its release notes.
2. **Install the app.** Android may ask you to allow installation from the browser or file manager you used. Enable that permission only for a source you trust.
3. **Set up your sources.** Use the app’s plugin management to install and enable the providers you want.
4. **Start listening.** Search for a song, import a supported playlist, or open your local music library.
5. **Explore optional features.** Enable automatic source fallback, configure your audio settings, or complete hands-free setup.

> **Platform status:** This README describes the Android app. The repository contains other platform projects, but their presence does not establish feature parity or release readiness. iOS support is not verified.

## Permissions, explained

Enable optional permissions only for the features you want to use.

| Permission or setting | Purpose |
|---|---|
| **Microphone** | Hands-free voice recognition. |
| **Music/media access, where requested** | Discover and open local audio files. |
| **Notifications, where requested** | Show playback or service notifications. |
| **Display over other apps** | Enable the floating player overlay. |
| **Device battery settings** | May help Android avoid interrupting background hands-free listening. |

Music providers receive the network requests needed for their features. Offline voice recognition does not mean every part of the app works offline.

## Frequently asked questions

### Why does a song work from one source but not another?

Providers can have different catalogues, track IDs, restrictions, and stream availability. Try another source or enable automatic fallback. Better artist and duration metadata helps the app find a reliable match.

### Why does an imported track show “Unknown Artist”?

The import may not have supplied usable artist information. FukatMusic should not invent an artist credit. Missing metadata can also make automatic matching less reliable.

### Can I use it without an internet connection?

Local music playback does not require an online music source. Online search, streaming, playlist imports, and provider-supplied content generally require connectivity. The hands-free voice model must be downloaded before offline recognition can be used.

### Does it replace a Spotify or YouTube Music subscription?

No. FukatMusic is an independent player. Importing a playlist does not transfer subscription benefits or grant access rights to another service.

### Does the floating player work like Apple’s Dynamic Island?

It is an **Android overlay inspired by that style of interaction**, not Apple’s Dynamic Island or an iOS implementation.

## Help improve FukatMusic

Found a problem? [Open an issue](https://github.com/suraxcodes/fukatsongs/issues) with:

- App version, Android version, and device model.
- The feature or provider involved.
- Clear steps to reproduce the problem.
- What you expected and what happened instead.
- Relevant logs, with personal information and credentials removed.

For playback problems, include the song title, artist if known, and whether it plays when selected manually from another provider. This helps distinguish a matching problem from a stream or audio-output failure.

Code contributions, documentation improvements, and reproducible bug reports are welcome. For substantial changes, discuss the scope in an issue first.

## Built with—and built upon

FukatMusic combines **Flutter and Dart** for the application with **Rust and WebAssembly** for its plugin runtime, alongside projects such as **media_kit** and **Isar Community**.

This project builds upon **BloomeeTunes**, created by **Hemant Arya**, and the work of its contributors. Credit also belongs to the maintainers of the libraries and plugins that make the experience possible.

## Responsible use and licensing

FukatMusic is not affiliated with or endorsed by Spotify, YouTube, YouTube Music, JioSaavn, or Apple. Service names and trademarks belong to their respective owners.

Use the app and its providers only in ways permitted by applicable law, provider terms, and the rights holders. Access to a stream does not itself grant permission to download, redistribute, or commercially exploit the music.

The application, its upstream components, and individual plugins may carry separate licensing obligations. Consult their applicable licence files and notices before modifying, redistributing, or using them commercially. This README does not grant additional rights.

---

<div align="center">

**Bring your library together. Find your next favourite. Keep listening.**

[Explore FukatMusic](https://github.com/suraxcodes/fukatsongs)

</div>
