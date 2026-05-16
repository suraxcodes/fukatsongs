import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../logic/lyrics_notifier.dart';
import '../../../../models/song.dart';

class LyricsView extends ConsumerWidget {
  final Song song;
  const LyricsView({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricsState = ref.watch(lyricsProvider);

    if (lyricsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFBB86FC)),
      );
    }

    if (lyricsState.error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_dissatisfied_rounded, color: Colors.white24, size: 48.sp),
              SizedBox(height: 12.h),
              Text(
                lyricsState.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14.sp),
              ),
              TextButton(
                onPressed: () => ref.read(lyricsProvider.notifier).fetchLyrics(song),
                child: const Text('Retry', style: TextStyle(color: Color(0xFFBB86FC))),
              ),
            ],
          ),
        ),
      );
    }

    final lyrics = lyricsState.plainLyrics ?? lyricsState.syncedLyrics;

    if (lyrics == null || lyrics.isEmpty) {
      return Center(
        child: Text(
          'No lyrics found for this song',
          style: TextStyle(color: Colors.white38, fontSize: 14.sp),
        ),
      );
    }

    // Process synced lyrics to remove timestamps for now (V1)
    final cleanLyrics = _cleanLyrics(lyrics);

    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.transparent, Colors.transparent, Colors.black],
          stops: [0.0, 0.1, 0.9, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
        child: Text(
          cleanLyrics,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 18.sp,
            height: 1.8,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _cleanLyrics(String lyrics) {
    // Remove timestamps [00:00.00]
    final regex = RegExp(r'\[\d{2}:\d{2}\.\d{2,3}\]');
    return lyrics.replaceAll(regex, '').trim();
  }
}
