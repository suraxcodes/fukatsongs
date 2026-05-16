import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/song.dart';
import '../../../library/logic/download_notifier.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../player/presentation/immersive_player_screen.dart';
import '../../../library/presentation/song_options_sheet.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/hive_boxes.dart';

class SongCard extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;

  const SongCard({
    super.key,
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(downloadNotifierProvider);
    final downloadNotifier = ref.read(downloadNotifierProvider.notifier);
    
    final isDownloading = downloadState.containsKey(song.id);
    final progress = downloadState[song.id] ?? 0.0;
    
    // Check if song is downloaded by looking at the downloads box
    final isDownloaded = Hive.box<Song>(HiveBoxes.downloads).containsKey(song.id);

    return GestureDetector(
      onTap: () {
        onTap();
        // Auto-open immersive player
        Future.delayed(const Duration(milliseconds: 200), () {
          if (context.mounted) openImmersivePlayer(context);
        });
      },
      onLongPress: () => showSongOptions(context, song),
      child: GlassContainer(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                    child: CachedNetworkImage(
                      imageUrl: song.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // 7-day cache TTL
                      cacheKey: song.imageUrl,
                      placeholder: (context, url) => Container(color: Colors.white10),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Source Badge(s)
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                children: song.providers.keys.map((source) {
                  return Container(
                    margin: EdgeInsets.only(right: 4.w),
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          source == 'youtube' ? Icons.play_circle_fill : Icons.music_note,
                          color: source == 'youtube' ? Colors.red : Colors.tealAccent,
                          size: 10.sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          source == 'youtube' ? 'YT' : 'SN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            // Download Overlay
            Positioned(
              top: 8,
              right: 8,
              child: _buildDownloadIndicator(
                isDownloading,
                progress,
                isDownloaded,
                () => downloadNotifier.downloadSong(song),
              ),
            ),
            // More Options (Three-dot menu)
            Positioned(
              bottom: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 20),
                onPressed: () => showSongOptions(context, song),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadIndicator(
    bool isDownloading,
    double progress,
    bool isDownloaded,
    VoidCallback onDownload,
  ) {
    if (isDownloaded) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
      );
    }

    if (isDownloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            color: const Color(0xFF6200EE),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
        ],
      );
    }

    return IconButton(
      icon: const Icon(Icons.cloud_download_rounded, color: Colors.white70),
      onPressed: onDownload,
    );
  }
}
