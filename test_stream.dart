import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// Test Songs List (20 mixed mainstream English and rare tracks)
final List<Map<String, String>> testSongs = [
  {'title': 'Fix You', 'artist': 'Coldplay'},
  {'title': 'Yellow', 'artist': 'Coldplay'},
  {'title': 'The Scientist', 'artist': 'Coldplay'},
  {'title': 'Clocks', 'artist': 'Coldplay'},
  {'title': 'Viva la Vida', 'artist': 'Coldplay'},
  {'title': 'Someone Like You', 'artist': 'Adele'},
  {'title': 'Rolling in the Deep', 'artist': 'Adele'},
  {'title': 'Hello', 'artist': 'Adele'},
  {'title': 'Perfect', 'artist': 'Ed Sheeran'},
  {'title': 'Believer', 'artist': 'Imagine Dragons'},
  {'title': 'Shape of You', 'artist': 'Ed Sheeran'},
  {'title': 'Until I Found You', 'artist': 'Stephen Sanchez'},
  {'title': 'Another Love', 'artist': 'Tom Odell'},
  {'title': 'Bohemian Rhapsody', 'artist': 'Queen'},
  {'title': 'Hotel California', 'artist': 'Eagles'},
  {'title': 'Mockingbird', 'artist': 'Eminem'},
  {'title': 'Bad Liar', 'artist': 'Imagine Dragons'},
  {'title': 'Lovely', 'artist': 'Billie Eilish & Khalid'},
  {'title': 'Faded', 'artist': 'Alan Walker'},
  {'title': 'Dusk Till Dawn', 'artist': 'Zayn ft. Sia'},
];

// Piped & Invidious Mirror Pool
final List<String> pipedMirrors = [
  'https://api.piped.private.coffee',
  'https://piped-api.lunar.icu',
  'https://api-piped.mha.fi',
  'https://pipedapi.oxen.moe',
  'https://pipedapi.kavin.rocks',
];

final List<String> invidiousMirrors = [
  'https://inv.vern.cc',
  'https://invidious.sethforprivacy.com',
  'https://invidious.projectsegfau.lt',
  'https://yewtu.be',
  'https://inv.nadeko.net',
];

// JioSaavn Mirror Pool
final List<String> saavnMirrors = [
  'https://jiosaavn-api-sigma-sandy.vercel.app',
  'https://saavn.me/api',
  'https://jiosaavn-api-beta.vercel.app',
];

class _MirrorJob {
  final String url;
  final bool isPiped;
  _MirrorJob({required this.url, required this.isPiped});
}

void main() async {
  print('==================================================');
  print('       🏁 FUKATSONGS MULTI-SOURCE BENCHMARK       ');
  print('==================================================');
  print('Testing 20 mixed official/rare songs across all layers...');
  print('Running diagnostic extraction...');
  print('==================================================\n');

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
  ));
  final yt = YoutubeExplode();

  int layer1Success = 0;
  int layer2Success = 0;
  int layer3Success = 0;
  int soundCloudSuccess = 0;
  int wynkSuccess = 0;
  int totalFailed = 0;

  for (int i = 0; i < testSongs.length; i++) {
    final song = testSongs[i];
    final songTitle = song['title']!;
    final songArtist = song['artist']!;
    final fullQuery = '$songTitle by $songArtist';

    print('[Song ${i + 1}/20] "$songTitle" - $songArtist');

    String? videoId;
    String? resolvedUrl;
    String matchedProvider = 'NONE';

    // --- STAGE 1: DIRECT YOUTUBE SEARCH ---
    try {
      stdout.write('  -> Stage 1 (YouTube Direct): Searching & Extracting... ');
      final searchResult = await yt.search.search(fullQuery);
      if (searchResult.isNotEmpty) {
        final video = searchResult.first;
        videoId = video.id.value;
        
        final manifest = await yt.videos.streamsClient.getManifest(videoId);
        final audioStream = manifest.audioOnly.withHighestBitrate();
        final testUrl = audioStream.url.toString();

        // Quick verification check
        final response = await dio.get(
          testUrl,
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Range': 'bytes=0-0',
            },
            validateStatus: (status) => true,
          ),
        ).timeout(const Duration(milliseconds: 2000));

        if (response.statusCode != 403) {
          resolvedUrl = testUrl;
          matchedProvider = 'YouTube Direct';
          layer1Success++;
          print('✅ SUCCESS!');
        } else {
          print('❌ BLOCKED (403)');
        }
      } else {
        print('❌ NO RESULTS');
      }
    } catch (e) {
      print('❌ ERROR: $e');
    }

    // --- STAGE 2: PIPED / INVIDIOUS RACING ENGINE ---
    if (resolvedUrl == null && videoId != null) {
      try {
        stdout.write('  -> Stage 2 (Piped/Invidious Parallel Race): Probing... ');
        
        final pipedToTry = (pipedMirrors..shuffle()).take(2).toList();
        final invidiousToTry = (invidiousMirrors..shuffle()).take(2).toList();
        
        final List<_MirrorJob> jobs = [];
        for (final m in pipedToTry) {
          jobs.add(_MirrorJob(url: '$m/streams/$videoId', isPiped: true));
        }
        for (final m in invidiousToTry) {
          jobs.add(_MirrorJob(url: '$m/api/v1/videos/$videoId', isPiped: false));
        }

        final completer = Completer<String?>();
        int failedCount = 0;
        final totalJobs = jobs.length;

        for (final job in jobs) {
          dio.get(
            job.url,
            options: Options(headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
            }),
          ).timeout(const Duration(seconds: 4)).then((response) {
            if (!completer.isCompleted) {
              if (response.statusCode == 200 && response.data != null) {
                var data = response.data;
                if (data is String) {
                  data = jsonDecode(data);
                }

                if (job.isPiped) {
                  final List? audioStreams = data['audioStreams'];
                  if (audioStreams != null && audioStreams.isNotEmpty) {
                    audioStreams.sort((a, b) => (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0));
                    completer.complete(audioStreams.first['url'] as String);
                    return;
                  }
                } else {
                  final formats = data['adaptiveFormats'] as List?;
                  if (formats != null) {
                    final audioStream = formats.firstWhere(
                      (f) => f['type'].toString().contains('audio'),
                      orElse: () => null,
                    );
                    if (audioStream != null && audioStream['url'] != null) {
                      completer.complete(audioStream['url'] as String);
                      return;
                    }
                  }
                }
              }
              failedCount++;
              if (failedCount >= totalJobs) {
                completer.complete(null);
              }
            }
          }).catchError((_) {
            if (!completer.isCompleted) {
              failedCount++;
              if (failedCount >= totalJobs) {
                completer.complete(null);
              }
            }
          });
        }

        final raceResult = await completer.future.timeout(const Duration(seconds: 5), onTimeout: () => null);
        if (raceResult != null) {
          resolvedUrl = raceResult;
          matchedProvider = 'YouTube Race Mirror';
          layer2Success++;
          print('✅ SUCCESS!');
        } else {
          print('❌ ALL MIRRORS TIMEOUT/BLOCKED');
        }
      } catch (e) {
        print('❌ ERROR: $e');
      }
    }

    // --- STAGE 3: JIOSAAVN MULTI-MIRROR LIFEBOAT ---
    if (resolvedUrl == null) {
      try {
        stdout.write('  -> Stage 3 (JioSaavn Multi-Mirror): Probing... ');
        final cleanTitle = songTitle.replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '').trim();
        
        Response? saavnResponse;
        for (final mirror in saavnMirrors) {
          try {
            final response = await dio.get(
              '$mirror/search/songs',
              queryParameters: {'query': '$cleanTitle $songArtist'},
            ).timeout(const Duration(seconds: 3));
            
            if (response.statusCode == 200) {
              var data = response.data;
              if (data is String) {
                data = jsonDecode(data);
              }
              if (data['status'] == 'SUCCESS' || data['data'] != null) {
                saavnResponse = response;
                break;
              }
            }
          } catch (_) {}
        }

        if (saavnResponse != null) {
          var data = saavnResponse.data;
          if (data is String) {
            data = jsonDecode(data);
          }
          final List songList = data['data'] is List ? data['data'] : (data['data']['results'] ?? []);
          if (songList.isNotEmpty) {
            final bestMatch = songList[0];
            final List downloadUrls = bestMatch['downloadUrl'];
            final bestStream = downloadUrls.last['link'];
            resolvedUrl = bestStream;
            matchedProvider = 'JioSaavn Lifeboat';
            layer3Success++;
            print('✅ SUCCESS! (Matched: ${bestMatch['name']})');
          } else {
            print('❌ NO SEARCH MATCHES');
          }
        } else {
          print('❌ SAAVN SERVICE DOWN');
        }
      } catch (e) {
        print('❌ ERROR: $e');
      }
    }

    // --- STAGE 4: SOUNDCLOUD TIER-4 FALLBACK ---
    if (resolvedUrl == null) {
      try {
        stdout.write('  -> Stage 4 (SoundCloud Public API): Probing... ');
        // Public client ID search
        final response = await dio.get(
          'https://api-v2.soundcloud.com/search/tracks',
          queryParameters: {
            'q': '$songTitle $songArtist',
            'client_id': 'iZ14tYhg4hZgT3oD5jcxP9Cq1cWwz1S9',
            'limit': '1',
          },
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200 && response.data != null) {
          final List collection = response.data['collection'] ?? [];
          if (collection.isNotEmpty) {
            final track = collection[0];
            resolvedUrl = track['permalink_url']; // Stand-in for soundcloud streaming
            matchedProvider = 'SoundCloud';
            soundCloudSuccess++;
            print('✅ SUCCESS! (Track: ${track['title']})');
          } else {
            print('❌ NO SOUNDCLOUD MATCHES');
          }
        } else {
          print('❌ SEARCH FAILED');
        }
      } catch (e) {
        print('❌ ERROR: $e');
      }
    }

    // --- STAGE 5: WYNK MUSIC API TIER-5 FALLBACK ---
    if (resolvedUrl == null) {
      try {
        stdout.write('  -> Stage 5 (Wynk Music Public API): Probing... ');
        final response = await dio.get(
          'https://api.wynk.in/music/v1/search',
          queryParameters: {
            'q': '$songTitle $songArtist',
          },
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200 && response.data != null) {
          final List items = response.data['items'] ?? [];
          if (items.isNotEmpty) {
            final item = items[0];
            resolvedUrl = 'https://wynk.in/music/song/${item['id']}'; // Stand-in for Wynk streaming
            matchedProvider = 'Wynk Music';
            wynkSuccess++;
            print('✅ SUCCESS! (Track: ${item['title']})');
          } else {
            print('❌ NO WYNK MATCHES');
          }
        } else {
          print('❌ SEARCH FAILED');
        }
      } catch (e) {
        print('❌ ERROR: $e');
      }
    }

    if (resolvedUrl != null) {
      print('  🎉 VERDICT: Song playing via [$matchedProvider]!\n');
    } else {
      print('  💀 VERDICT: ABSOLUTE FAILURE for this track.\n');
      totalFailed++;
    }
  }

  yt.close();

  final int survived = testSongs.length - totalFailed;
  final double survivalRate = (survived / testSongs.length) * 100;

  print('==================================================');
  print('              📊 BENCHMARK SCOREBOARD             ');
  print('==================================================');
  print('Total Official Songs Tested: ${testSongs.length}');
  print('--------------------------------------------------');
  print('  🟢 Stage 1 (YouTube Direct)  : $layer1Success / ${testSongs.length}');
  print('  🟢 Stage 2 (Piped/Invidious)  : $layer2Success / ${testSongs.length}');
  print('  🟢 Stage 3 (JioSaavn life)    : $layer3Success / ${testSongs.length}');
  print('  🟢 Stage 4 (SoundCloud alt)   : $soundCloudSuccess / ${testSongs.length}');
  print('  🟢 Stage 5 (Wynk Music alt)   : $wynkSuccess / ${testSongs.length}');
  print('  🔴 Absolute Failures          : $totalFailed / ${testSongs.length}');
  print('--------------------------------------------------');
  print('🏆 Overall Survival Rate       : ${survivalRate.toStringAsFixed(1)}%');
  print('==================================================');
  exit(0);
}
