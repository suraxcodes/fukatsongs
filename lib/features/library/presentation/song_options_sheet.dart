import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/models/playlist.dart';
import 'package:fukat_songs/features/library/logic/playlist_notifier.dart';
import 'package:fukat_songs/features/player/presentation/player_notifier.dart';
import 'package:fukat_songs/features/library/logic/download_notifier.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fukat_songs/core/constants/hive_boxes.dart';

/// Shows the three-dot options sheet for a song.
void showSongOptions(BuildContext context, Song song) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SongOptionsSheet(song: song),
  );
}

/// Shows the 'Add to Playlist' sheet directly.
void showAddToPlaylistSheet(BuildContext context, WidgetRef ref, Song song) {
  final playlists = ref.read(playlistNotifierProvider);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddToPlaylistSheet(song: song, playlists: playlists),
  );
}

class SongOptionsSheet extends ConsumerWidget {
  final Song song;
  const SongOptionsSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistNotifierProvider);
    final isLiked = ref.watch(likedSongsNotifierProvider.notifier).isLiked(song.id);
    
    // Check if song is downloaded by looking at the downloads box
    final isDownloaded = Hive.box<Song>(HiveBoxes.downloads).containsKey(song.id);
    final downloadState = ref.watch(downloadNotifierProvider);
    final isDownloading = downloadState.containsKey(song.id);
    final progress = downloadState[song.id] ?? 0.0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16142E).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: EdgeInsets.only(top: 12.h, bottom: 8.h),
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              // Song info header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Image.network(
                        song.imageUrl,
                        width: 56.w,
                        height: 56.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56.w,
                          height: 56.w,
                          color: Colors.white10,
                          child: const Icon(Icons.music_note, color: Colors.white24),
                        ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
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
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white60, fontSize: 13.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              // Options List
              if (isDownloaded)
                _option(
                  context,
                  icon: Icons.download_done_rounded,
                  color: Colors.greenAccent,
                  label: 'Downloaded',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Song already downloaded')),
                    );
                    Navigator.pop(context);
                  },
                )
              else if (isDownloading)
                _option(
                  context,
                  icon: Icons.downloading_rounded,
                  label: 'Downloading (${(progress * 100).toInt()}%)',
                  onTap: () {},
                  trailing: SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(value: progress, strokeWidth: 2),
                  ),
                )
              else
                _option(
                  context,
                  icon: Icons.download_for_offline_rounded,
                  label: 'Download Song',
                  onTap: () {
                    ref.read(downloadNotifierProvider.notifier).downloadSong(song);
                    Navigator.pop(context);
                  },
                ),
              _option(
                context,
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isLiked ? Colors.redAccent : Colors.white70,
                label: isLiked ? 'Remove from Liked' : 'Like Song',
                onTap: () {
                  ref.read(likedSongsNotifierProvider.notifier).toggle(song);
                  Navigator.pop(context);
                },
              ),
              _option(
                context,
                icon: Icons.playlist_add_rounded,
                label: 'Save to Playlist',
                onTap: () {
                  Navigator.pop(context);
                  showAddToPlaylistSheet(context, ref, song);
                },
              ),
              _option(
                context,
                icon: Icons.queue_music_rounded,
                label: 'Add to Queue',
                onTap: () {
                  ref.read(playerNotifierProvider.notifier).addSongToQueue(song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to queue')),
                  );
                },
              ),
              _option(
                context,
                icon: Icons.skip_next_rounded,
                label: 'Play Next',
                onTap: () {
                  ref.read(playerNotifierProvider.notifier).playNext(song);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playing next')),
                  );
                },
              ),
              _option(
                context,
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 12.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white70,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(label, style: TextStyle(color: Colors.white, fontSize: 15.sp)),
      onTap: onTap,
      trailing: trailing,
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
    );
  }

  void _showAddToPlaylistSheet(
    BuildContext context,
    WidgetRef ref,
    Song song,
    List<Playlist> playlists,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToPlaylistSheet(song: song, playlists: playlists),
    );
  }
}

class _AddToPlaylistSheet extends ConsumerWidget {
  final Song song;
  final List<Playlist> playlists;
  const _AddToPlaylistSheet({required this.song, required this.playlists});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16142E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add to Playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Create new playlist
                TextButton.icon(
                  icon: const Icon(Icons.add_rounded, color: Color(0xFF6200EE)),
                  label: const Text('New', style: TextStyle(color: Color(0xFF6200EE))),
                  onPressed: () => _showCreateDialog(context, ref),
                ),
              ],
            ),
          ),
          if (playlists.isEmpty)
            Padding(
              padding: EdgeInsets.all(32.w),
              child: Text(
                'No playlists yet. Create one!',
                style: TextStyle(color: Colors.white54, fontSize: 14.sp),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final pl = playlists[index];
                return ListTile(
                  leading: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const Icon(Icons.queue_music_rounded, color: Colors.white54),
                  ),
                  title: Text(pl.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${pl.songs.length} songs',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  onTap: () {
                    final messenger = ScaffoldMessenger.of(context);
                    ref.read(playlistNotifierProvider.notifier).addSong(pl.id, song);
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Added to "${pl.name}"')),
                    );
                  },
                );
              },
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16.h),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16142E),
        title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6200EE)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6200EE), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await ref.read(playlistNotifierProvider.notifier).createPlaylist(ctrl.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFF6200EE))),
          ),
        ],
      ),
    );
  }
}
