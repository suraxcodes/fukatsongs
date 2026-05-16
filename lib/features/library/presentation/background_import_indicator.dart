import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fukat_songs/features/library/logic/playlist_import_notifier.dart';
import 'package:fukat_songs/features/library/presentation/playlist_import_dialog.dart';

class BackgroundImportIndicator extends ConsumerWidget {
  const BackgroundImportIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(playlistImportNotifierProvider);
    final notifier = ref.read(playlistImportNotifierProvider.notifier);

    if (importState.status != ImportStatus.matching && importState.status != ImportStatus.parsing) {
      return const SizedBox.shrink();
    }

    final progress = importState.totalCount > 0 ? importState.currentCount / importState.totalCount : 0.0;

    return GestureDetector(
      onTap: () => showPlaylistImportDialog(context),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFF6200EE).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                value: importState.status == ImportStatus.parsing ? null : progress,
                strokeWidth: 3,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    importState.status == ImportStatus.parsing ? 'Analyzing Playlist...' : 'Importing: ${importState.playlistName}',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (importState.status == ImportStatus.matching)
                    Text(
                      'Matched ${importState.currentCount} of ${importState.totalCount} songs',
                      style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 24),
              onPressed: () => notifier.stopImport(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
