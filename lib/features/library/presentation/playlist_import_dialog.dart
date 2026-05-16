import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fukat_songs/features/library/logic/playlist_import_notifier.dart';
import 'package:fukat_songs/features/library/logic/playlist_notifier.dart';
import 'package:fukat_songs/features/library/logic/download_notifier.dart';

class PlaylistImportDialog extends ConsumerStatefulWidget {
  const PlaylistImportDialog({super.key});

  @override
  ConsumerState<PlaylistImportDialog> createState() => _PlaylistImportDialogState();
}

class _PlaylistImportDialogState extends ConsumerState<PlaylistImportDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _autoDownload = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(playlistImportNotifierProvider);
    final downloadState = ref.watch(downloadNotifierProvider);
    final notifier = ref.read(playlistImportNotifierProvider.notifier);

    return Dialog(
      backgroundColor: const Color(0xFF16142E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.import_export_rounded, color: const Color(0xFFBB86FC), size: 28.sp),
                SizedBox(width: 12.w),
                Text(
                  'Import Playlist',
                  style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: importState.isAutoDownloadEnabled,
              onChanged: (v) => notifier.toggleAutoDownload(v),
              title: Text('Auto-Download matched songs', style: TextStyle(color: Colors.white, fontSize: 13.sp)),
              subtitle: Text('Offline ready as they are found', style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
              activeColor: const Color(0xFFBB86FC),
            ),
            SizedBox(height: 8.h),
            if (importState.status == ImportStatus.idle || importState.status == ImportStatus.error) ...[
              Text(
                'Bring your music here from YouTube or Spotify. We\'ll find the best quality versions for you.',
                style: TextStyle(color: Colors.white70, fontSize: 13.sp),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.check_circle_outline_rounded, 'Migrate existing playlists'),
                    SizedBox(height: 6.h),
                    _buildInfoRow(Icons.high_quality_rounded, 'Auto-match high-quality audio'),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'YouTube or Spotify link...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.link_rounded, color: Colors.white38),
                ),
              ),
              if (importState.errorMessage != null) ...[
                SizedBox(height: 12.h),
                Text(
                  importState.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () => notifier.importFromUrl(_urlController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6200EE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: const Text('Analyze'),
                  ),
                ],
              ),
            ] else if (importState.status == ImportStatus.parsing || importState.status == ImportStatus.matching) ...[
              SizedBox(height: 20.h),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60.w,
                    height: 60.w,
                    child: CircularProgressIndicator(
                      value: importState.totalCount > 0 ? importState.currentCount / importState.totalCount : null,
                      color: const Color(0xFF6200EE),
                      strokeWidth: 6,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                  Text(
                    '${importState.currentCount}',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                importState.status == ImportStatus.parsing ? 'Analyzing link...' : 'Matching songs...',
                style: const TextStyle(color: Colors.white70),
              ),
              if (importState.playlistName != null) ...[
                SizedBox(height: 8.h),
                Text(
                  importState.playlistName!,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
              ],
              if (importState.importedSongs.isNotEmpty) ...[
                SizedBox(height: 20.h),
                Container(
                  height: 150.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.all(12.w),
                    itemCount: importState.importedSongs.length,
                    itemBuilder: (context, index) {
                      final song = importState.importedSongs[importState.importedSongs.length - 1 - index];
                      final isDownloading = downloadState.containsKey(song.id);
                      
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDownloading ? () {
                                ref.read(downloadNotifierProvider.notifier).cancelDownload(song.id);
                              } : null,
                              child: Icon(
                                isDownloading ? Icons.cancel_outlined : Icons.check_circle_rounded, 
                                color: isDownloading ? Colors.redAccent : Colors.greenAccent, 
                                size: 16.sp
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                song.title,
                                style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isDownloading) ...[
                              SizedBox(width: 4.w),
                              Text(
                                '${(downloadState[song.id]! * 100).toInt()}%',
                                style: TextStyle(color: const Color(0xFFBB86FC), fontSize: 9.sp),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(playlistNotifierProvider.notifier).createPlaylist(
                        importState.playlistName ?? 'Imported Playlist',
                        songs: importState.importedSongs,
                      );
                      notifier.reset();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: const Text('Save what\'s found & Play'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ]
 else if (importState.status == ImportStatus.completed) ...[
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                'Import Complete!',
                style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                '${importState.importedSongs.length} songs found. ${importState.failedSongs.length} songs skipped.',
                style: const TextStyle(color: Colors.white70),
              ),
              if (importState.failedSongs.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  constraints: BoxConstraints(maxHeight: 100.h),
                  child: SingleChildScrollView(
                    child: Column(
                      children: importState.failedSongs.map((s) => Text(
                        '• $s',
                        style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )).toList(),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Create the playlist in Hive
                    ref.read(playlistNotifierProvider.notifier).createPlaylist(
                      importState.playlistName ?? 'Imported Playlist',
                      songs: importState.importedSongs,
                    );
                    notifier.reset();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.withOpacity(0.2),
                    foregroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: const Text('Save to Library'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16.sp),
        SizedBox(width: 8.w),
        Text(
          text,
          style: TextStyle(color: Colors.white54, fontSize: 11.sp),
        ),
      ],
    );
  }
}

void showPlaylistImportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const PlaylistImportDialog(),
  );
}
