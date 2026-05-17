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
import 'background_import_indicator.dart';

final librarySearchProvider = StateProvider<String>((ref) => '');

enum LibrarySort { title, artist, album, recentlyAdded, duration, custom }
enum LibraryView { compact, list }

final librarySortProvider = StateProvider<LibrarySort>((ref) => LibrarySort.recentlyAdded);
final libraryViewProvider = StateProvider<LibraryView>((ref) => LibraryView.list);

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
        child: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
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
                        // Sort and View Options Bar
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showSortBottomSheet(context, ref),
                                child: Row(
                                  children: [
                                    Icon(Icons.sort_rounded, color: const Color(0xFFBB86FC), size: 18.sp),
                                    SizedBox(width: 6.w),
                                    Consumer(
                                      builder: (context, ref, _) {
                                        final sort = ref.watch(librarySortProvider);
                                        return Text(
                                          _getSortName(sort),
                                          style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.w500),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Consumer(
                                builder: (context, ref, _) {
                                  final view = ref.watch(libraryViewProvider);
                                  return IconButton(
                                    icon: Icon(
                                      view == LibraryView.list ? Icons.list_rounded : Icons.grid_view_rounded,
                                      color: Colors.white54,
                                      size: 20.sp,
                                    ),
                                    onPressed: () => ref.read(libraryViewProvider.notifier).state = 
                                      view == LibraryView.list ? LibraryView.compact : LibraryView.list,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        labelColor: const Color(0xFF6200EE),
                        unselectedLabelColor: Colors.white54,
                        indicatorColor: const Color(0xFF6200EE),
                        indicatorSize: TabBarIndicatorSize.label,
                        tabAlignment: TabAlignment.start,
                        tabs: const [
                          Tab(text: 'Downloads'),
                          Tab(text: 'Playlists'),
                          Tab(text: 'Liked'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _DownloadsTab(),
                  _PlaylistsTab(onCreatePlaylist: () => _showCreatePlaylistDialog(context)),
                  _LikedSongsTab(),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0, 
              child: const BackgroundImportIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortName(LibrarySort sort) {
    switch (sort) {
      case LibrarySort.title: return 'Title';
      case LibrarySort.artist: return 'Artist';
      case LibrarySort.album: return 'Album';
      case LibrarySort.recentlyAdded: return 'Recently added';
      case LibrarySort.duration: return 'Duration';
      case LibrarySort.custom: return 'Custom order';
    }
  }

  void _showSortBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16142E),
      isScrollControlled: true, // Allow it to expand
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final currentSort = ref.watch(librarySortProvider);
          final currentView = ref.watch(libraryViewProvider);

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                    child: Text('Sort by', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                  ...LibrarySort.values.map((sort) => _buildSortOption(context, ref, sort, currentSort)),
                  const Divider(color: Colors.white10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                    child: Text('View as', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  ),
                  _buildViewOption(context, ref, LibraryView.list, currentView, Icons.list_rounded, 'List'),
                  _buildViewOption(context, ref, LibraryView.compact, currentView, Icons.grid_view_rounded, 'Compact'),
                  SizedBox(height: 12.h), // Safe space at bottom
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortOption(BuildContext context, WidgetRef ref, LibrarySort sort, LibrarySort current) {
    final isSelected = sort == current;
    return ListTile(
      onTap: () {
        ref.read(librarySortProvider.notifier).state = sort;
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
      title: Text(_getSortName(sort), style: TextStyle(color: isSelected ? const Color(0xFFBB86FC) : Colors.white70, fontSize: 14.sp)),
      trailing: isSelected ? Icon(Icons.check_rounded, color: const Color(0xFFBB86FC), size: 20.sp) : null,
    );
  }

  Widget _buildViewOption(BuildContext context, WidgetRef ref, LibraryView view, LibraryView current, IconData icon, String label) {
    final isSelected = view == current;
    return ListTile(
      onTap: () {
        ref.read(libraryViewProvider.notifier).state = view;
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
      leading: Icon(icon, color: isSelected ? const Color(0xFFBB86FC) : Colors.white38),
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFBB86FC) : Colors.white70, fontSize: 14.sp)),
      trailing: isSelected ? Icon(Icons.check_rounded, color: const Color(0xFFBB86FC), size: 20.sp) : null,
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

List<Song> _getSortedSongs(List<Song> songs, LibrarySort sort) {
  final sorted = List<Song>.from(songs);
  switch (sort) {
    case LibrarySort.title:
      sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case LibrarySort.artist:
      sorted.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
      break;
    case LibrarySort.album:
      sorted.sort((a, b) => a.albumName.toLowerCase().compareTo(b.albumName.toLowerCase()));
      break;
    case LibrarySort.recentlyAdded:
      // Assuming original order is recently added (Hive behavior or insertion order)
      // If we had a timestamp, we'd use it. For now, reverse of insertion if desired.
      return sorted.reversed.toList();
    case LibrarySort.duration:
      sorted.sort((a, b) => b.duration.compareTo(a.duration));
      break;
    case LibrarySort.custom:
      break;
  }
  return sorted;
}

class _DownloadsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerNotifier = ref.read(playerNotifierProvider.notifier);
    final sortMode = ref.watch(librarySortProvider);
    final viewMode = ref.watch(libraryViewProvider);

    return ValueListenableBuilder(
      valueListenable: Hive.box<Song>(HiveBoxes.downloads).listenable(),
      builder: (context, Box<Song> box, _) {
        if (box.isEmpty) {
          return _emptyState(icon: Icons.download_done_rounded, message: 'No downloads yet');
        }

        final searchQuery = ref.watch(librarySearchProvider).toLowerCase();
        var songs = box.values.toList();
        
        // Apply Sort
        songs = _getSortedSongs(songs, sortMode);

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
              viewMode: viewMode,
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
    final sortMode = ref.watch(librarySortProvider);
    final viewMode = ref.watch(libraryViewProvider);

    var songs = List<Song>.from(likedSongs);
    
    // Apply Sort
    songs = _getSortedSongs(songs, sortMode);

    if (searchQuery.isNotEmpty) {
      songs = songs.where((s) => 
        s.title.toLowerCase().contains(searchQuery) || 
        s.artist.toLowerCase().contains(searchQuery)
      ).toList();
    }

    if (songs.isEmpty) {
      return _emptyState(
        icon: Icons.favorite_rounded,
        message: 'Songs you like\nwill appear here',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 12.h, 0, 120.h),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return _SongListTile(
          song: song,
          viewMode: viewMode,
          trailing: IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
            onPressed: () => ref.read(likedSongsNotifierProvider.notifier).toggle(song),
          ),
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
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SongListTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final Widget? trailing;
  final LibraryView viewMode;
  const _SongListTile({
    required this.song, 
    required this.onTap, 
    this.trailing, 
    this.viewMode = LibraryView.list
  });

  @override
  Widget build(BuildContext context) {
    if (viewMode == LibraryView.compact) {
      return ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: CachedNetworkImage(
            imageUrl: song.imageUrl,
            width: 32.w,
            height: 32.w,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => const Icon(Icons.music_note, size: 16),
          ),
        ),
        title: Text(
          song.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white, fontSize: 13.sp),
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white54, fontSize: 11.sp),
        ),
        onTap: onTap,
        trailing: trailing,
      );
    }

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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0D0B1F),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
