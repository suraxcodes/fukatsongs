import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/providers/music_repository_provider.dart';
import 'package:fukat_songs/core/constants/hive_boxes.dart';

class DownloadNotifier extends StateNotifier<Map<String, double>> {
  final Ref ref;
  final _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadNotifier(this.ref) : super({});

  Future<void> downloadSong(Song song) async {
    if (state.containsKey(song.id)) return;

    final cancelToken = CancelToken();
    _cancelTokens[song.id] = cancelToken;

    try {
      final repository = ref.read(musicRepositoryProvider);
      final streamUrl = await repository.getStreamUrl(song);
      if (streamUrl == null) throw Exception("Could not fetch stream URL");

      final appDocDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDocDir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath = '${downloadDir.path}/${song.id}.m4a';
      
      state = {...state, song.id: 0.0};
      
      // Saavn requires specific headers for stream access
      final headers = <String, String>{
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
        if (song.source == 'saavn') 'Referer': 'https://www.jiosaavn.com/',
      };

      await _dio.download(
        streamUrl,
        filePath,
        cancelToken: cancelToken,
        options: Options(headers: headers),
        onReceiveProgress: (count, total) {
          if (total != -1) {
            state = {...state, song.id: count / total};
          }
        },
      );

      final updatedSong = song.copyWith(localPath: filePath);
      final downloadsBox = Hive.box<Song>(HiveBoxes.downloads);
      await downloadsBox.put(updatedSong.id, updatedSong);
      
    } on DioException catch (e) {
      if (!CancelToken.isCancel(e)) {
        rethrow;
      }
    } finally {
      _cancelTokens.remove(song.id);
      state = {...state}..remove(song.id);
    }
  }

  void cancelDownload(String songId) {
    _cancelTokens[songId]?.cancel();
    _cancelTokens.remove(songId);
    state = {...state}..remove(songId);
  }

  Future<void> removeDownload(String songId) async {
    debugPrint('removeDownload called for: $songId');
    final downloadsBox = Hive.box<Song>(HiveBoxes.downloads);
    final song = downloadsBox.get(songId);

    if (song != null && song.localPath != null) {
      debugPrint('Found song in box, path: ${song.localPath}');
      final file = File(song.localPath!);
      try {
        if (await file.exists()) {
          await file.delete();
          debugPrint('File deleted successfully');
        } else {
          debugPrint('File did not exist at path');
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
      }
    } else {
      debugPrint('Song not found in box or localPath is null');
    }

    await downloadsBox.delete(songId);
    debugPrint('Entry deleted from Hive box');
  }
}

final downloadNotifierProvider = StateNotifierProvider<DownloadNotifier, Map<String, double>>((ref) {
  return DownloadNotifier(ref);
});

Future<File?> getLocalAudioFile(String songId) async {
  final box = Hive.box<Song>(HiveBoxes.downloads);
  final song = box.get(songId);
  if (song != null && song.localPath != null) {
    final file = File(song.localPath!);
    if (await file.exists()) {
      return file;
    }
  }
  return null;
}
