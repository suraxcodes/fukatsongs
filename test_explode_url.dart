import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:dio/dio.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Fetching video details for VhRJ-3T4Rcw...');
    final manifest = await yt.videos.streamsClient.getManifest('VhRJ-3T4Rcw');
    final streamInfo = manifest.audioOnly.withHighestBitrate();
    print('Stream URL: ${streamInfo.url}');
    
    // try to get the stream to see if it gives 403
    final dio = Dio();
    final res = await dio.head(streamInfo.url.toString());
    print('Stream HTTP Status: ${res.statusCode}');
  } catch(e, st) {
    print('Error: $e');
    print(st);
  } finally {
    yt.close();
  }
}
