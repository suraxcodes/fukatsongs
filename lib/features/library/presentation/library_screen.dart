import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/song.dart';
import '../../../models/playlist.dart';
import '../logic/playlist_notifier.dart';
import '../../player/presentation/player_notifier.dart';
import '../../player/presentation/immersive_player_screen.dart';
import 'playlist_detail_screen.dart';
import 'song_options_sheet.dart';
import '../../../core/constants/hive_boxes.dart';
import '../../../providers/playlist_repository_provider.dart';
import '../../main/main_screen_notifier.dart';
import '../../settings/presentation/settings_screen.dart';
import 'playlist_import_dialog.dart';

final librarySearchProvider = StateProvider<String>((ref) => '');

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Library',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.import_export_rounded, color: Colors.white, size: 28),
                        onPressed: () => showPlaylistImportDialog(context),
                        tooltip: 'Import Playlist',
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                        onPressed: () => _showCreatePlaylistDialog(context),
                        tooltip: 'New Playlist',
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            // Search Bar for Library
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  onChanged: (val) => ref.read(librarySearchProvider.notifier).state = val,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search in library...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF6200EE),
              unselectedLabelColor: Colors.white54,
              indicatorColor: const Color(0xFF6200EE),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Downloads'),
                Tab(text: 'Playlists'),
                Tab(text: 'Liked'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _DownloadsTab(),
                  _PlaylistsTab(onCreatePlaylist: () => _showCreatePlaylistDialog(context)),
                  _LikedSongsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
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
            hintText: 'Give it a name...',
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
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(playlistNotifierProvider.notifier).createPlaylist(ctrl.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFF6200EE))),
          ),
        ],
      ),
    );
  }
}

class _DownloadsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerNotifier = ref.read(playerNotifierProvider.notifier);

    return ValueListenableBuilder(
      valueListenable: Hive.box<Song>(HiveBoxes.downloads).listenable(),
      builder: (context, Box<Song> box, _) {
        if (box.isEmpty) {
// ...
        }

        final searchQuery = ref.watch(librarySearchProvider).toLowerCase();
        var songs = box.values.toList();
        if (searchQuery.isNotEmpty) {
          songs = songs.where((s) => 
            s.title.toLowerCase().contains(searchQuery) || 
            s.artist.toLowerCase().contains(searchQuery)
          ).toList();
        }

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(0, 12.h, 0, 120.h),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return _SongListTile(
              song: song,
              onTap: () {
                playerNotifier.setQueueAndPlay(
                  List<Song>.from(songs),
                  startIndex: index,
                );
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (context.mounted) openImmersivePlayer(context);
                });
              },
            );
          },
        );
      },
    );
  }
}

// ─── Playlists Tab ───────────────────────────────────────────────────────────

class _PlaylistsTab extends ConsumerWidget {
  final VoidCallback onCreatePlaylist;
  const _PlaylistsTab({required this.onCreatePlaylist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistNotifierProvider);
    final searchQuery = ref.watch(librarySearchProvider).toLowerCase();

    var filteredPlaylists = playlists;
    if (searchQuery.isNotEmpty) {
      filteredPlaylists = playlists.where((p) => 
        p.name.toLowerCase().contains(searchQuery)
      ).toList();
    }

    if (filteredPlaylists.isEmpty) {
      return _emptyState(
        icon: Icons.queue_music_rounded,
        message: 'No playlists yet\nTap + to create one',
        action: TextButton.icon(
          icon: const Icon(Icons.add_rounded, color: Color(0xFF6200EE)),
          label: const Text('Create Playlist', style: TextStyle(color: Color(0xFF6200EE))),
          onPressed: onCreatePlaylist,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 120.h),
      itemCount: filteredPlaylists.length,
      itemBuilder: (context, index) {
        final pl = filteredPlaylists[index];
        return _PlaylistTile(playlist: pl);
      },
    );
  }
}

class _PlaylistTile extends ConsumerWidget {
  final Playlist playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cover = playlist.songs.isNotEmpty ? playlist.songs.first.imageUrl : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: cover != null
                  ? CachedNetworkImage(
                      imageUrl: cover,
                      width: 60.w,
                      height: 60.w,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60.w,
                      height: 60.w,
                      color: Colors.white10,
                      child: const Icon(Icons.queue_music_rounded, color: Colors.white24),
                    ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
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
                    '${playlist.songs.length} songs',
                    style: TextStyle(color: Colors.white54, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38),
              onPressed: () => ref.read(playlistNotifierProvider.notifier).deletePlaylist(playlist.id),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ─── Liked Songs Tab ─────────────────────────────────────────────────────────

class _LikedSongsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likedSongs = ref.watch(likedSongsNotifierProvider);
    final searchQuery = ref.watch(librarySearchProvider).toLowerCase();
    final playerNotifier = ref.read(playerNotifierProvider.notifier);

    var filteredSongs = likedSongs;
    if (searchQuery.isNotEmpty) {
      filteredSongs = likedSongs.where((s) => 
        s.title.toLowerCase().contains(searchQuery) || 
        s.artist.toLowerCase().contains(searchQuery)
      ).toList();
    }

    if (filteredSongs.isEmpty) {
      return _emptyState(
        icon: Icons.favorite_rounded,
        message: 'Songs you like\nwill appear here',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 12.h, 0, 120.h),
      itemCount: filteredSongs.length,
      itemBuilder: (context, index) {
        final song = filteredSongs[index];
        return _SongListTile(
          song: song,
          trailing: IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            onPressed: () => ref.read(likedSongsNotifierProvider.notifier).toggle(song),
          ),
          onTap: () {
            playerNotifier.setQueueAndPlay(
              List<Song>.from(filteredSongs),
              startIndex: index,
            );
            Future.delayed(const Duration(milliseconds: 200), () {
              if (context.mounted) openImmersivePlayer(context);
            });
          },
        );
      },
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SongListTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final Widget? trailing;
  const _SongListTile({required this.song, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: CachedNetworkImage(
          imageUrl: song.imageUrl,
          width: 52.w,
          height: 52.w,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: Colors.white10,
            child: const Icon(Icons.music_note, color: Colors.white24),
          ),
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
      onTap: onTap,
      trailing: trailing ?? IconButton(
        icon: const Icon(Icons.more_vert_rounded, color: Colors.white38),
        onPressed: () => showSongOptions(context, song),
      ),
    );
  }
}

Widget _emptyState({
  required IconData icon,
  required String message,
  Widget? action,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.white24),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          action,
        ],
      ],
    ),
  );
}
