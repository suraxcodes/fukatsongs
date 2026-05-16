import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../logic/lyrics_notifier.dart';
import '../player_notifier.dart';

class LyricsView extends ConsumerStatefulWidget {
  const LyricsView({super.key});

  @override
  ConsumerState<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends ConsumerState<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLine(int index) {
    if (index == -1 || !_scrollController.hasClients) return;
    
    // Estimate line height is roughly 60.h (text + padding)
    final targetOffset = index * 50.h; 
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsProvider);
    final playerState = ref.watch(playerNotifierProvider);
    final currentPosition = playerState.position;

    if (lyricsState.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white24));
    }

    if (lyricsState.error != null) {
      return Center(
        child: Text(
          lyricsState.error!,
          style: TextStyle(color: Colors.white38, fontSize: 16.sp),
        ),
      );
    }

    // Synced Lyrics UI
    if (lyricsState.lyrics.isNotEmpty) {
      // Find current line index
      int newIndex = -1;
      for (int i = 0; i < lyricsState.lyrics.length; i++) {
        if (currentPosition >= lyricsState.lyrics[i].time) {
          newIndex = i;
        } else {
          break;
        }
      }

      if (newIndex != _currentIndex) {
        _currentIndex = newIndex;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentLine(newIndex));
      }

      return ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
            stops: [0.0, 0.1, 0.9, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.symmetric(vertical: 150.h, horizontal: 24.w),
          itemCount: lyricsState.lyrics.length,
          itemBuilder: (context, index) {
            final line = lyricsState.lyrics[index];
            final isActive = index == _currentIndex;

            return AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: isActive ? 24.sp : 18.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : Colors.white38,
                height: 1.5,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  line.text,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      );
    }

    // Fallback to Plain Lyrics
    if (lyricsState.plainLyrics != null) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Text(
          lyricsState.plainLyrics!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18.sp,
            height: 1.8,
          ),
        ),
      );
    }

    return Center(
      child: Text(
        'No lyrics available',
        style: TextStyle(color: Colors.white38, fontSize: 16.sp),
      ),
    );
  }
}
