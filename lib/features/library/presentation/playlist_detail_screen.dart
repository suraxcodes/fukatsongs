import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fukat_songs/models/playlist.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/features/player/presentation/player_notifier.dart';
import 'package:fukat_songs/features/player/presentation/immersive_player_screen.dart';
import 'package:fukat_songs/features/library/logic/playlist_notifier.dart';
import 'package:fukat_songs/features/library/presentation/song_options_sheet.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String? playlistId;
  final Playlist? playlist;
  const PlaylistDetailScreen({super.key, this.playlistId, this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetPlaylist = playlist ?? 
      ref.watch(playlistNotifierProvider).firstWhere(
        (p) => p.id == playlistId,
        orElse: () => const Playlist(id: '', name: 'Not Found'),
      );

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, targetPlaylist, ref),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = targetPlaylist.songs[index];
                return _buildSongTile(context, ref, targetPlaylist, song, index);
              },
              childCount: targetPlaylist.songs.length,
            ),
          ),
          if (targetPlaylist.songs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.queue_music_rounded, size: 64, color: Colors.white24),
                    SizedBox(height: 16.h),
                    Text(
                      'No songs yet\nSearch and save songs here',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16.sp),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Playlist playlist, WidgetRef ref) {
    final hasSongs = playlist.songs.isNotEmpty;
    final coverUrl = hasSongs ? playlist.songs.first.imageUrl : null;

    return SliverAppBar(
      expandedHeight: 260.h,
      backgroundColor: const Color(0xFF0D0B1F),
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white70),
          onPressed: () => _renamePlaylist(context, ref, playlist),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
          onPressed: () => _confirmDelete(context, ref, playlist),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl != null)
              CachedNetworkImage(
                imageUrl: coverUrl.replaceAll('150x150', '500x500'),
                fit: BoxFit.cover,
              )
            else
              Container(
                color: const Color(0xFF16142E),
                child: const Icon(Icons.queue_music_rounded, size: 80, color: Colors.white12),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, const Color(0xFF0D0B1F)],
                ),
              ),
            ),
            Positioned(
              bottom: 16.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${playlist.songs.length} songs',
                    style: TextStyle(color: Colors.white60, fontSize: 14.sp),
                  ),
                  SizedBox(height: 16.h),
                  if (hasSongs)
                    Row(
                      children: [
                        _headerButton(
                          icon: Icons.play_arrow_rounded,
                          label: 'Play',
                          primary: true,
                          onTap: () {
                            ref.read(playerNotifierProvider.notifier).setQueueAndPlay(playlist.songs);
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (context.mounted) openImmersivePlayer(context);
                            });
                          },
                        ),
                        SizedBox(width: 12.w),
                        _headerButton(
                          icon: Icons.shuffle_rounded,
                          label: 'Shuffle',
                          primary: false,
                          onTap: () {
                            ref.read(playerNotifierProvider.notifier).setQueueAndPlay(playlist.songs);
                            ref.read(playerNotifierProvider.notifier).toggleShuffle();
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (context.mounted) openImmersivePlayer(context);
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF6200EE) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24.r),
          border: primary ? null : Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 6.w),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
    Song song,
    int index,
  ) {
    return Dismissible(
      key: Key('${playlist.id}_${song.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        color: Colors.red.withOpacity(0.2),
        child: const Icon(Icons.delete_rounded, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        ref.read(playlistNotifierProvider.notifier).removeSong(playlist.id, song.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${song.title}" removed from playlist')),
        );
      },
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: CachedNetworkImage(
            imageUrl: song.imageUrl,
            width: 52.w,
            height: 52.w,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.sp),
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
        onTap: () {
          ref.read(playerNotifierProvider.notifier).setQueueAndPlay(
            playlist.songs,
            startIndex: index,
          );
          Future.delayed(const Duration(milliseconds: 200), () {
            if (context.mounted) openImmersivePlayer(context);
          });
        },
        trailing: IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
          onPressed: () => showSongOptions(context, song),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Playlist playlist) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16142E),
        title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${playlist.name}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              ref.read(playlistNotifierProvider.notifier).deletePlaylist(playlist.id);
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to library
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _renamePlaylist(BuildContext context, WidgetRef ref, Playlist playlist) {
    final ctrl = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16142E),
        title: const Text('Rename Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6200EE))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF6200EE), width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(playlistNotifierProvider.notifier).renamePlaylist(playlist.id, ctrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Rename', style: TextStyle(color: Color(0xFF6200EE))),
          ),
        ],
      ),
    );
  }
}
