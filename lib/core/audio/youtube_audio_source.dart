import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Routes YouTube audio bytes through youtube_explode_dart's own authenticated
/// HTTP session — the ONLY way to satisfy YouTube's Proof-of-Origin (xpc) token.
///
/// ExoPlayer cannot pass the xpc check with headers alone because the token is
/// bound to the youtube_explode_dart session that generated the stream URL.
/// This source proxies bytes through that same session so the PO check passes.
class YouTubeAudioSource extends StreamAudioSource {
  final String videoId;
  final YoutubeExplode yt;

  // Cache the resolved stream info so subsequent requests (seeks) don't re-fetch.
  AudioOnlyStreamInfo? _cachedStream;

  YouTubeAudioSource(this.videoId, this.yt);

  Future<AudioOnlyStreamInfo> _getStream() async {
    if (_cachedStream != null) return _cachedStream!;
    final manifest = await yt.videos.streamsClient.getManifest(videoId);
    _cachedStream = manifest.audioOnly.withHighestBitrate();
    print('--- YouTubeAudioSource: Resolved stream for $videoId'
        ' | ${_cachedStream!.container.name}'
        ' | ${_cachedStream!.size.totalBytes}B ---');
    return _cachedStream!;
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    print('--- YouTubeAudioSource request: $videoId start=$start end=$end ---');
    try {
      final audioStream = await _getStream();
      final totalBytes = audioStream.size.totalBytes;
      final from = start ?? 0;

      // youtube_explode_dart's get() fetches via its own authenticated HTTP
      // client — this is what carries the session and satisfies the xpc token.
      final stream = yt.videos.streamsClient.get(audioStream);

      final contentType = audioStream.container.name == 'mp4'
          ? 'audio/mp4'
          : 'audio/webm';

      return StreamAudioResponse(
        sourceLength: totalBytes,
        contentLength: totalBytes - from,
        offset: from,
        stream: stream,
        contentType: contentType,
      );
    } catch (e) {
      print('--- YouTubeAudioSource ERROR: $e ---');
      rethrow;
    }
  }
}
