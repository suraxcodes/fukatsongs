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

  void _scrollToCurrentLine(int index, double containerHeight) {
    if (index == -1 || !_scrollController.hasClients) return;
    
    // Exact center focus:
    // With padding set to (containerHeight - itemHeight) / 2,
    // scrolling to index * itemHeight will place the item exactly in the center.
    final itemHeight = 75.h;
    final targetOffset = index * itemHeight;
    
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsProvider);
    final playerNotifier = ref.read(playerNotifierProvider.notifier);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerHeight = constraints.maxHeight;
        final itemHeight = 75.h;
        final verticalPadding = (containerHeight - itemHeight) / 2;
        
        return StreamBuilder<Duration>(
          stream: playerNotifier.positionStream,
          builder: (context, snapshot) {
            final currentPosition = snapshot.data ?? Duration.zero;

            if (lyricsState.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.white24));
            }

            // Synced Lyrics UI
            if (lyricsState.lyrics.isNotEmpty) {
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToCurrentLine(newIndex, containerHeight);
                });
              }

              return ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, 0.2, 0.8, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: verticalPadding, 
                    bottom: verticalPadding,
                    left: 24.w,
                    right: 24.w,
                  ),
                  itemCount: lyricsState.lyrics.length,
                  itemExtent: itemHeight, 
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final line = lyricsState.lyrics[index];
                    final isActive = index == _currentIndex;

                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: isActive ? 1.0 : 0.3,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          line.text,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
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
                padding: EdgeInsets.all(28.w),
                child: Text(
                  lyricsState.plainLyrics!,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.6,
                  ),
                ),
              );
            }

            return Center(
              child: Text(
                lyricsState.error ?? 'Lyrics not available',
                style: TextStyle(color: Colors.white38, fontSize: 16.sp),
              ),
            );
          },
        );
      },
    );
  }
}
