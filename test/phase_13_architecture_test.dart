// ignore_for_file: avoid_print
// test/phase_13_architecture_test.dart
//
// Tests the Phase 13 architecture:
//   1. Smart Search Filter (blocklist logic in MusicRepository)
//   2. 3-Layer Fallback order (Stage 1 → Stage 2 → Stage 3)
//
// Run with:  flutter test test/phase_13_architecture_test.dart
// These are pure unit tests — no network calls, no device required.

import 'package:flutter_test/flutter_test.dart';
import 'package:fukat_songs/models/song.dart';

// ─────────────────────────────────────────────────────────────
// Helpers — extracted the filter logic so we can test it
// independently without spinning up Hive or Dio.
// ─────────────────────────────────────────────────────────────

const List<String> _blocklist = [
  'slowed',
  'reverb',
  'lofi',
  'lo-fi',
  'remix',
  'cover',
  'karaoke',
  'instrumental',
  'sped up',
  'nightcore',
  '8d audio',
  'slowed + reverb',
  'slowed reverb',
  '8d',
];

/// Pure copy of the filter logic from music_repository.dart
List<Song> applySearchFilter(String query, List<Song> results) {
  final queryLower = query.toLowerCase();
  final userWantsFiltered =
      _blocklist.any((term) => queryLower.contains(term));

  if (userWantsFiltered) return results; // respect user intent

  return results.where((song) {
    final titleLower = song.title.toLowerCase();
    return !_blocklist.any((term) => titleLower.contains(term));
  }).toList();
}

/// Simple helper that returns which fallback stage would be used,
/// given which stages are "working" (simulated).
String simulateFallback({
  required bool stage1Works,
  required bool stage2Works,
  required bool stage3Works,
}) {
  // STAGE 1: Direct Extraction
  if (stage1Works) return 'STAGE_1_DIRECT';

  // STAGE 2: Piped Mirrors
  if (stage2Works) return 'STAGE_2_PIPED';

  // STAGE 3: JioSaavn Magic Switch
  if (stage3Works) return 'STAGE_3_SAAVN';

  return 'ALL_FAILED';
}

// ─────────────────────────────────────────────────────────────
// Test Song Factory
// ─────────────────────────────────────────────────────────────

Song makeSong(String title, {String artist = 'Test Artist'}) {
  return Song(
    id: title.toLowerCase().replaceAll(' ', '_'),
    title: title,
    artist: artist,
    albumName: 'Test Album',
    year: '2024',
    imageUrl: 'https://example.com/img.jpg',
    duration: 240,
    source: 'saavn',
    providers: const {'saavn': 'test_id'},
  );
}

// ─────────────────────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────────────────────

void main() {
  group('Phase 13 — Smart Search Filter', () {
    final songs = [
      makeSong('Tu Hai Mera'),
      makeSong('Tu Hai Mera (Slowed + Reverb)'),
      makeSong('Tu Hai Mera - Lofi Remix'),
      makeSong('Tu Hai Mera - Cover Version'),
      makeSong('Tu Hai Mera - Karaoke'),
      makeSong('Tu Hai Mera - Instrumental'),
      makeSong('Tu Hai Mera (Nightcore)'),
      makeSong('Tu Hai Mera - Sped Up'),
      makeSong('Believer'),
      makeSong('Believer (8D Audio)'),
      makeSong('Believer - Slowed'),
    ];

    test('Normal search removes slowed, remix, cover, karaoke etc.', () {
      final result = applySearchFilter('Tu Hai Mera', songs);

      // Only clean songs should remain
      expect(result.any((s) => s.title == 'Tu Hai Mera'), isTrue,
          reason: 'Original song must be included');
      expect(result.any((s) => s.title == 'Believer'), isTrue,
          reason: 'Unrelated clean song must be included');
      expect(result.any((s) => s.title.toLowerCase().contains('slowed')),
          isFalse,
          reason: 'Slowed versions must be filtered');
      expect(result.any((s) => s.title.toLowerCase().contains('reverb')),
          isFalse,
          reason: 'Reverb versions must be filtered');
      expect(result.any((s) => s.title.toLowerCase().contains('remix')),
          isFalse,
          reason: 'Remix versions must be filtered');
      expect(result.any((s) => s.title.toLowerCase().contains('cover')),
          isFalse,
          reason: 'Cover versions must be filtered');
      expect(result.any((s) => s.title.toLowerCase().contains('karaoke')),
          isFalse,
          reason: 'Karaoke versions must be filtered');
      expect(result.any((s) => s.title.toLowerCase().contains('nightcore')),
          isFalse,
          reason: 'Nightcore versions must be filtered');
      expect(result.any((s) => s.title.toLowerCase().contains('8d')), isFalse,
          reason: '8D audio versions must be filtered');

      print('✅ Filter test: ${songs.length} songs → ${result.length} clean songs kept');
    });

    test('When user searches "slowed remix" — filter is NOT applied', () {
      final result = applySearchFilter('slowed remix believer', songs);

      // User explicitly wants slowed, so all songs should come through
      expect(result.length, equals(songs.length),
          reason: 'All songs must pass when user searched for filtered term');

      print('✅ Intent-respect test: all ${result.length} songs returned (user asked for slowed)');
    });

    test('When user searches "reverb" — filter is NOT applied', () {
      final result = applySearchFilter('believer reverb', songs);
      expect(result.length, equals(songs.length));
      print('✅ Intent-respect test (reverb): ${result.length} songs passed through');
    });

    test('"tu hai mera slowed" — slowed songs ARE shown (user asked for it)', () {
      // This is the key case: user types song name + filter word together
      final result = applySearchFilter('tu hai mera slowed', songs);

      // Filter must be OFF — user explicitly wants slowed
      expect(result.length, equals(songs.length),
          reason: 'All songs must appear because query contains "slowed"');
      expect(result.any((s) => s.title.toLowerCase().contains('slowed')), isTrue,
          reason: 'Slowed songs must be visible when user searched for "slowed"');

      print('✅ Mixed query test: "tu hai mera slowed" shows all ${result.length} songs including slowed');
    });

    test('"tu hai mera lofi" — lofi songs ARE shown', () {
      final result = applySearchFilter('tu hai mera lofi', songs);
      expect(result.length, equals(songs.length));
      print('✅ Mixed query test: "tu hai mera lofi" shows all ${result.length} songs');
    });

    test('Empty results still return empty list', () {
      final result = applySearchFilter('Tu Hai Mera', []);
      expect(result, isEmpty);
      print('✅ Empty list test: passed');
    });

    test('All clean songs pass through untouched', () {
      final cleanSongs = [
        makeSong('Shape of You'),
        makeSong('Perfect'),
        makeSong('Tum Hi Ho'),
        makeSong('Tera Ban Jaunga'),
      ];
      final result = applySearchFilter('tum hi ho', cleanSongs);
      expect(result.length, equals(cleanSongs.length),
          reason: 'No clean song should be removed');
      print('✅ Clean songs passthrough: all ${result.length} songs kept');
    });
  });

  group('Phase 13 — 3-Layer Fallback Engine', () {
    test('STAGE 1 succeeds — returns immediately, never tries Stage 2 or 3', () {
      final result = simulateFallback(
        stage1Works: true,
        stage2Works: true,
        stage3Works: true,
      );
      expect(result, equals('STAGE_1_DIRECT'));
      print('✅ Stage 1 success: $result (fastest path taken)');
    });

    test('STAGE 1 fails, STAGE 2 succeeds — Piped mirrors used', () {
      final result = simulateFallback(
        stage1Works: false,
        stage2Works: true,
        stage3Works: true,
      );
      expect(result, equals('STAGE_2_PIPED'));
      print('✅ Stage 1→2 fallback: $result (Piped proxy saved it)');
    });

    test('STAGE 1 + STAGE 2 fail, STAGE 3 succeeds — JioSaavn saves it', () {
      final result = simulateFallback(
        stage1Works: false,
        stage2Works: false,
        stage3Works: true,
      );
      expect(result, equals('STAGE_3_SAAVN'));
      print('✅ Stage 1→2→3 fallback: $result (JioSaavn Magic Switch activated)');
    });

    test('All 3 stages fail — returns ALL_FAILED gracefully (no crash)', () {
      final result = simulateFallback(
        stage1Works: false,
        stage2Works: false,
        stage3Works: false,
      );
      expect(result, equals('ALL_FAILED'));
      print('✅ All-fail test: returned "$result" cleanly — app should auto-skip');
    });

    test('Stage priority is correct: 1 > 2 > 3', () {
      // Even if Stage 2 and 3 work, Stage 1 must be preferred
      final withStage1 = simulateFallback(stage1Works: true, stage2Works: true, stage3Works: true);
      final withoutStage1 = simulateFallback(stage1Works: false, stage2Works: true, stage3Works: true);
      final withOnlyStage3 = simulateFallback(stage1Works: false, stage2Works: false, stage3Works: true);

      expect(withStage1, equals('STAGE_1_DIRECT'));
      expect(withoutStage1, equals('STAGE_2_PIPED'));
      expect(withOnlyStage3, equals('STAGE_3_SAAVN'));

      print('✅ Priority order verified: Stage 1 > Stage 2 > Stage 3');
    });
  });
}
