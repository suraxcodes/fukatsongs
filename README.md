<div align="center">

# 🎵 FukatMusic

### Your playlists. More ways to listen.

**An Android music player built with Flutter & Rust—bringing local music, plugin-powered sources, playlist imports, and hands-free controls together.**

[![Downloads](https://img.shields.io/github/downloads/suraxcodes/fukatsongs/total?style=for-the-badge&color=7C4DFF)](https://github.com/suraxcodes/fukatsongs/releases)
[![Release](https://img.shields.io/github/v/release/suraxcodes/fukatsongs?style=for-the-badge&color=2962FF)](https://github.com/suraxcodes/fukatsongs/releases)
[![Stars](https://img.shields.io/github/stars/suraxcodes/fukatsongs?style=for-the-badge&color=FFB300)](https://github.com/suraxcodes/fukatsongs/stargazers)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/suraxcodes/fukatsongs/releases)

**[📥 Download](https://github.com/suraxcodes/fukatsongs/releases) · [🐛 Report a Bug](https://github.com/suraxcodes/fukatsongs/issues) · [💡 Suggest a Feature](https://github.com/suraxcodes/fukatsongs/issues)**

</div>

---

## 🎧 Meet FukatMusic

Your music should feel like one collection—not a set of disconnected playlists.

**FukatMusic** brings your local audio and supported online sources into one Android player. Import playlists, explore music through plugins, shape your sound, and control playback with your voice.

When a track fails, smart source fallback can look for a matching recording elsewhere while keeping your saved playlist intact. Spend less time switching between sources and more time enjoying your music. 🎶

---

## ✨ What’s Inside

| | Feature | What you can do |
|---|---|---|
| 🔌 | **Plugin-Powered Sources** | Extend music search and playback through compatible providers, including YouTube Music, YouTube Video and JioSaavn integrations. |
| 📂 | **Local Music** | Listen to supported audio files already stored on your device. |
| 📚 | **Playlist Imports** | Bring supported Spotify and YouTube Music playlists into your library. |
| 🔄 | **Smart Source Fallback** | Look for an alternative matching track when the original source fails, without rewriting your saved playlist. |
| 🎙️ | **Hands-Free Controls** | Use supported voice commands with on-device recognition after a one-time model download. |
| 🎛️ | **Equalizer** | Adjust your sound to suit your headphones and listening preferences. |
| 🌊 | **Crossfade** | Blend the transition between tracks. |
| 🎤 | **Lyrics** | Follow along with lyrics when a compatible provider supplies them. |
| 🌙 | **Sleep Timer** | Choose when your listening session should end. |
| ▶️ | **Background Playback** | Keep listening while using other apps, with notification playback controls. |
| 🫧 | **Floating Player** | Access playback controls through an Android Dynamic Island-style overlay. |
| 🧭 | **Quick Navigation** | Triple-tap a navigation tab to return to its main page from nested screens. |
| 🌍 | **Multiple Languages** | Use the interface in one of the included translations. |

> Features depend on the installed build, enabled plugins, permissions and device support. Music availability can vary by provider and region.

## 🔄 One Song. More Than One Way to Play It.

A saved track can become unavailable even when another source has a playable match.

With automatic source fallback enabled, FukatMusic can:

1. Try the original track’s source.
2. Search loaded providers for matching alternatives if playback fails.
3. Consider a different track from the original provider as well.
4. Check titles, available artist credits, duration and version information before selecting candidates.
5. Continue through a limited number of alternatives rather than retrying indefinitely.

**Your saved playlist entries and their order stay unchanged.**

Matching accommodates differences such as additional artist credits and certain title annotations, while retaining checks against unrelated songs and alternate versions. Incomplete metadata can still make matching uncertain; a playable alternative is not guaranteed.

## 🎙️ Less Tapping. More Listening.

Set up hands-free mode with a one-time download of an approximately **39 MB offline voice model**.

- **On-device recognition:** voice recognition can work offline after setup; streaming still requires connectivity.
- **Built-in command guide:** see the commands the app actually recognises.
- **Easy access:** open the guide from Settings or by long-pressing the microphone icon.

Microphone permission is required. Android battery restrictions may interrupt background listening, especially on devices with aggressive power management.

## 🔌 Make It Yours with Plugins

FukatMusic uses a **Rust-backed WebAssembly plugin runtime** to support an extensible listening experience.

Compatible plugins can provide:

- Music search and playback sources.
- Lyrics.
- Charts and discovery content.
- Playlist imports.
- Search suggestions.

Install and enable the providers you want through the app’s plugin management. Use repositories you trust: provider availability, behaviour and terms can change independently of the app.

---

## 📥 Download & Install

### Android

**[Download an available Android APK from GitHub Releases →](https://github.com/suraxcodes/fukatsongs/releases)**

1. Open the release page and read the release notes.
2. Download the appropriate APK, if provided for that release.
3. Install it on your Android device. If prompted, allow installation from the browser or file manager you used.
4. Open FukatMusic and set up your preferred providers.
5. Search for music, import a supported playlist, or start with local files.

> **Platform status:** This README describes the Android app. Other platform folders in the repository do not establish release readiness or feature parity. iOS support has not been verified.

### 🛡️ Download Safely

Use **[this repository’s Releases page](https://github.com/suraxcodes/fukatsongs/releases)** as your download reference. Avoid APKs from unknown mirrors or sites that claim affiliation without a link from this repository.

---


Translation coverage may vary between releases. Found an awkward phrase or a missing translation? **[Open an issue](https://github.com/suraxcodes/fukatsongs/issues)** or contribute an improvement.

## 🔐 Permissions, Explained

Optional features may request additional access:

| Access | Used for |
|---|---|
| **Microphone** | Hands-free voice recognition. |
| **Music/media access** | Finding and opening local audio, where requested. |
| **Notifications** | Playback and service notifications, where requested. |
| **Display over other apps** | The floating player overlay. |

You do not need to enable every optional feature to use the player. Provider-backed features make network requests to the services they use; offline voice recognition does not mean the entire app works offline.

---



</details>

<details>
<summary><strong>Why does a song play from one source but not another?</strong></summary>

Providers can have different track IDs, catalogues, restrictions and stream availability. Automatic fallback can try matching alternatives. If a song still fails, manually searching another provider helps identify a working result.

</details>

<details>
<summary><strong>Can I listen without internet?</strong></summary>

Supported local music files can be played without an online source. Online search, streaming, playlist imports and provider-supplied content generally need a connection. Hands-free recognition needs its model downloaded before offline use.

</details>

<details>
<summary><strong>Why does an imported song show “Unknown Artist”?</strong></summary>

Some imports do not supply usable artist metadata. The app displays a fallback label rather than inventing an artist credit. Missing details can also make automatic matching less reliable.

</details>

<details>
<summary><strong>Is the floating player Apple’s Dynamic Island?</strong></summary>

No. It is an Android overlay inspired by that interaction style. It is not Apple’s Dynamic Island or an iOS implementation.

</details>

---

## 💖 Support the Project

You can help FukatMusic grow without spending anything:

- ⭐ **Star the repository** if you find the app useful.
- 🐛 **Report reproducible bugs** with clear steps.
- 🌍 **Improve translations** and documentation.
- 🧪 **Test releases** on different Android devices.
- 💡 **Share thoughtful feature suggestions.**

Every useful report and contribution helps make the next listening session better.

## 🤝 Contribute to FukatMusic

Code improvements, documentation, translations and testing are welcome.

1. **Discuss:** open an issue before starting a substantial change.
2. **Fork:** create your own copy of the repository.
3. **Branch:** keep your change focused on one feature or fix.
4. **Verify:** run analysis and relevant tests; test on Android where applicable.
5. **Submit:** open a pull request explaining the change and what you tested.

Please preserve upstream attribution and comply with the applicable project and dependency licences.

### Reporting a Playback Problem

Include:

- App version, Android version and device model.
- Song title, artist if known, and the selected provider.
- Whether the track was imported or found through search.
- Whether another provider plays it manually.
- Reproduction steps and relevant logs, with sensitive information removed.

**[Report an issue →](https://github.com/suraxcodes/fukatsongs/issues)**

## 🛠️ Built With

**Flutter · Dart · Rust · WebAssembly · media_kit · Isar Community**

Flutter powers the interface, Dart coordinates application behaviour, and Rust supports the plugin runtime.

## 🙏 Credits & Acknowledgments

FukatMusic builds upon **BloomeeTunes**, created by **Hemant Arya**, and the work of its contributors.

Thank you to the upstream project, plugin authors, dependency maintainers, translators and testers whose work supports this app. FukatMusic’s identity does not replace or remove those contributions or their licensing requirements.

## 📄 Licensing & Responsible Use

The app, its upstream components and individual plugins may carry separate licensing obligations. Consult their applicable licence files and notices before modifying, redistributing or using them commercially. This README does not grant additional rights.

FukatMusic is not affiliated with or endorsed by Spotify, YouTube, YouTube Music, JioSaavn or Apple. Names and trademarks belong to their respective owners.

Use sources and content only as permitted by applicable law, provider terms and rights holders. A playable stream does not itself grant permission to download, redistribute or commercially exploit the music.

## 📫 Get in Touch

- **Bugs and suggestions:** [GitHub Issues](https://github.com/suraxcodes/fukatsongs/issues)
- **Code contributions:** [Pull Requests](https://github.com/suraxcodes/fukatsongs/pulls)
- **Project updates:** [Releases](https://github.com/suraxcodes/fukatsongs/releases)
- **Maintainer profile:** [@suraxcodes](https://github.com/suraxcodes)

---

<div align="center">

### 🎶 Bring your library together. Keep listening.

**[Download FukatMusic](https://github.com/suraxcodes/fukatsongs/releases) · [Star the Project](https://github.com/suraxcodes/fukatsongs)**

</div>
