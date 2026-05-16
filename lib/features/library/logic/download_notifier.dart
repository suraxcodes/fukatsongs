import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/song.dart';
import '../../../providers/music_repository_provider.dart';

part 'download_notifier.g.dart';

@riverpod
class DownloadNotifier extends _$DownloadNotifier {
  final _dio = Dio();
  
  @override
  Map<String, double> build() => {};

  Future<void> downloadSong(Song song) async {
    if (state.containsKey(song.id)) return;

    try {
      // 1. Fetch Stream URL
      final repository = ref.read(musicRepositoryProvider);
      final streamUrl = await repository.getStreamUrl(song);
      if (streamUrl == null) throw Exception("Could not fetch stream URL");

      // 2. Prepare Directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${appDocDir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final filePath = '${downloadDir.path}/${song.id}.mp3';
      
      // 3. Start Download
      state = {...state, song.id: 0.0};
      
      await _dio.download(
        streamUrl,
        filePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            state = {...state, song.id: count / total};
          }
        },
      );

      // 4. Persistence
      final updatedSong = song.copyWith(localPath: filePath);
      final libraryBox = Hive.box('library');
      await libraryBox.put(updatedSong.id, updatedSong.toJson());
      
      // Clear progress on success
      state = {...state}..remove(song.id);
      
    } catch (e) {
      print("Download error: $e");
      state = {...state}..remove(song.id);
    }
  }
  
  bool isDownloading(String id) => state.containsKey(id);
  double getProgress(String id) => state[id] ?? 0.0;
}
