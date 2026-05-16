import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeAudioSource extends StreamAudioSource {
  final String videoId;
  final YoutubeExplode yt;
  StreamManifest? _manifest;

  YouTubeAudioSource(this.videoId, this.yt);

  Future<StreamManifest> _getManifest() async {
    _manifest ??= await yt.videos.streamsClient.getManifest(videoId);
    return _manifest!;
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    print('--- YouTubeAudioSource request: $videoId (start: $start, end: $end)');
    try {
      final manifest = await _getManifest();
      final audioStream = manifest.audioOnly.withHighestBitrate();
      
      print('--- YT Stream URL: ${audioStream.url}');
      print('--- YT Stream Size: ${audioStream.size}');
      print('--- YT Container: ${audioStream.container.name}');

      // Get the actual byte stream from YouTube
      final stream = yt.videos.streamsClient.get(audioStream);
      
      final contentType = audioStream.container.name == 'mp4' ? 'audio/mp4' : 'audio/webm';
      
      return StreamAudioResponse(
        sourceLength: audioStream.size.totalBytes,
        contentLength: audioStream.size.totalBytes,
        offset: start ?? 0,
        stream: stream,
        contentType: contentType,
      );
    } catch (e) {
      print('--- YouTubeAudioSource ERROR: $e');
      rethrow;
    }
  }
}
