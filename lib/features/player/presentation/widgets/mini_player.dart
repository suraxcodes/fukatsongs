import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../player_notifier.dart';
import '../immersive_player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerNotifierProvider);
    final notifier = ref.read(playerNotifierProvider.notifier);
    final currentSong = playerState.currentSong;

    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => openImmersivePlayer(context),
      child: Container(
        height: 68.h,
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFF16142E).withOpacity(0.95),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            const BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Progress Bar at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
                child: LinearProgressIndicator(
                  value: playerState.totalDuration.inSeconds > 0
                      ? playerState.position.inSeconds / playerState.totalDuration.inSeconds
                      : 0,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6200EE)),
                  minHeight: 2,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CachedNetworkImage(
                      imageUrl: currentSong.imageUrl,
                      width: 44.w,
                      height: 44.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentSong.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          currentSong.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                    onPressed: () => notifier.skipToPrevious(),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => playerState.isPlaying ? notifier.pause() : notifier.resume(),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                    onPressed: () => notifier.skipToNext(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
