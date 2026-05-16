import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'player_notifier.dart';
import '../../library/presentation/song_options_sheet.dart';
import '../../../models/song.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerNotifierProvider);
    final notifier = ref.read(playerNotifierProvider.notifier);
    final currentSong = playerState.currentSong;

    if (currentSong == null) return const Scaffold(body: Center(child: Text("No song playing")));

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () => showSongOptions(context, currentSong),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Artwork
              Center(
                child: Container(
                  width: 300.w,
                  height: 300.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6200EE).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: CachedNetworkImage(
                      imageUrl: currentSong.imageUrl.replaceAll('150x150', '500x500'),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.white10),
                      errorWidget: (context, url, error) => const Icon(Icons.music_note, size: 100, color: Colors.white24),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              // Title & Artist
              Text(
                currentSong.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                currentSong.artist,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 32.h),
              // Seek Bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: playerState.position.inSeconds.toDouble(),
                  max: playerState.totalDuration.inSeconds.toDouble() > 0 
                      ? playerState.totalDuration.inSeconds.toDouble() 
                      : 1.0,
                  onChanged: (val) => notifier.seek(Duration(seconds: val.toInt())),
                  activeColor: const Color(0xFF6200EE),
                  inactiveColor: Colors.white10,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(playerState.position), style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                    Text(_formatDuration(playerState.totalDuration), style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle_rounded, color: Colors.white70),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                    onPressed: () => notifier.skipToPrevious(),
                  ),
                  Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6200EE),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: (playerState.processingState == AudioProcessingState.loading || 
                              playerState.processingState == AudioProcessingState.buffering)
                          ? const CircularProgressIndicator(color: Colors.white)
                          : IconButton(
                              iconSize: 40,
                              icon: Icon(
                                playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => playerState.isPlaying ? notifier.pause() : notifier.resume(),
                            ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                    onPressed: () => notifier.skipToNext(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat_rounded, color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
