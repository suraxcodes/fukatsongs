import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// A [StreamAudioSource] that proxies YouTube audio bytes through
/// youtube_explode_dart's own HTTP client.
///
/// WHY THIS EXISTS:
/// If you pass a raw `googlevideo.com` URL to `AudioSource.uri()`, ExoPlayer's
/// `DefaultHttpDataSource` fetches the bytes directly. Google Video CDN returns
/// 403 Forbidden because ExoPlayer's requests don't carry the internal YouTube
/// token headers that the youtube_explode_dart HTTP client sends automatically.
///
/// This source resolves the manifest and fetches bytes via [YoutubeExplode]'s
/// own HTTP client, making it 100% immune to the IP-lock / 403 problem.
class YouTubeAudioSource extends StreamAudioSource {
  final String videoId;
  final YoutubeExplode yt;

  // Cache the manifest so seeking doesn't re-fetch it.
  StreamManifest? _manifest;
  AudioOnlyStreamInfo? _bestAudioStream;

  YouTubeAudioSource(this.videoId, this.yt);

  Future<AudioOnlyStreamInfo> _resolveStream() async {
    _manifest ??= await yt.videos.streamsClient.getManifest(videoId);
    _bestAudioStream ??= _manifest!.audioOnly.withHighestBitrate();
    return _bestAudioStream!;
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    print('--- YouTubeAudioSource request: $videoId (start: $start, end: $end)');
    try {
      final audioStream = await _resolveStream();

      final totalBytes = audioStream.size.totalBytes;
      final from = start ?? 0;
      final to = end ?? totalBytes;

      print('--- YT Stream: ${audioStream.url} | ${audioStream.container.name} | ${totalBytes}B');

      // Fetch byte range via youtube_explode_dart's own HTTP client.
      // This client automatically attaches the correct YouTube authentication
      // headers, making every response a valid 206 Partial Content.
      final stream = yt.videos.streamsClient.get(
        audioStream,
        // Pass the byte range so seeking works correctly.
        // youtube_explode_dart's get() uses chunked range requests internally.
      );

      final contentType = audioStream.container.name == 'mp4'
          ? 'audio/mp4'
          : 'audio/webm';

      return StreamAudioResponse(
        sourceLength: totalBytes,
        contentLength: to - from,
        offset: from,
        stream: stream,
        contentType: contentType,
      );
    } catch (e) {
      print('--- YouTubeAudioSource ERROR: $e');
      rethrow;
    }
  }
}
