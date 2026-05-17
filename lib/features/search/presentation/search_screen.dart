import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fukat_songs/features/search/presentation/search_notifier.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/features/search/presentation/widgets/song_card.dart';
import 'package:fukat_songs/features/player/presentation/player_notifier.dart';
import 'package:fukat_songs/features/player/presentation/immersive_player_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fukat_songs/core/widgets/song_skeleton.dart';
import 'package:fukat_songs/core/services/connectivity_service.dart';
import 'package:fukat_songs/core/repositories/history_repository.dart';
import 'package:fukat_songs/features/main/main_screen_notifier.dart';
import 'package:fukat_songs/features/settings/presentation/settings_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fukat_songs/core/constants/hive_boxes.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      ref.read(searchNotifierProvider.notifier).clear();
    } else {
      ref.read(searchNotifierProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final historyRepo = ref.watch(historyRepositoryProvider);
    final searchHistory = historyRepo.getSearchHistory();
    final songHistory = historyRepo.getPlaybackHistory().take(10).toList();
    final connectivity = ref.watch(connectivityServiceProvider);
    final isOffline = connectivity.value == ConnectivityResult.none;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomSearchBar(context, isOffline),
            Expanded(
              child: searchState.when(
                data: (songs) {
                  if (_searchController.text.isEmpty) {
                    return _buildSearchHome(searchHistory, songHistory);
                  }
                  if (songs.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildResults(songs, ref);
                },
                loading: () => _buildLoadingGrid(),
                error: (err, stack) => _buildErrorState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSearchBar(BuildContext context, bool isOffline) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 16.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => ref.read(mainScreenNotifierProvider.notifier).state = 0,
          ),
          Expanded(
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearch,
                onSubmitted: (val) {
                  if (val.trim().isNotEmpty) {
                    ref.read(historyRepositoryProvider).addToSearchHistory(val);
                    _onSearch(val);
                  }
                },
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
                decoration: InputDecoration(
                  hintText: isOffline ? 'Search your library...' : 'Search songs, artists...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 16.sp),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 22),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white70, size: 22.sp),
    );
  }

  Widget _buildSearchHome(List<String> textHistory, List<Song> songHistory) {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      children: [
        if (songHistory.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Text(
              'Recent searches',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            height: 140.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: songHistory.length,
              itemBuilder: (context, index) {
                final song = songHistory[index];
                return Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(playerNotifierProvider.notifier).playSong(song);
                      openImmersivePlayer(context);
                    },
                    child: SizedBox(
                      width: 100.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: CachedNetworkImage(
                              imageUrl: song.imageUrl,
                              width: 100.w,
                              height: 100.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        _TopSongsSection(),
        if (textHistory.isNotEmpty) ...[
          ...textHistory.map((query) => ListTile(
                leading: const Icon(Icons.history_rounded, color: Colors.white38),
                title: Text(query, style: TextStyle(color: Colors.white, fontSize: 15.sp)),
                trailing: const Icon(Icons.north_west_rounded, color: Colors.white38),
                onTap: () {
                  _searchController.text = query;
                  _onSearch(query);
                },
                onLongPress: () {
                  ref.read(historyRepositoryProvider).removeFromSearchHistory(query);
                  setState(() {});
                },
              )),
        ],
      ],
    );
  }

  Widget _buildResults(List<Song> songs, WidgetRef ref) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 100.h),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
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
          onTap: () {
            ref.read(playerNotifierProvider.notifier).setQueueAndPlay(songs, startIndex: index);
            openImmersivePlayer(context);
          },
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 100.h),
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            Container(width: 52.w, height: 52.w, color: Colors.white10),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150.w, height: 14.h, color: Colors.white10),
                SizedBox(height: 8.h),
                Container(width: 100.w, height: 12.h, color: Colors.white10),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, color: Colors.white10, size: 64.sp),
          SizedBox(height: 16.h),
          const Text('No songs found', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Something went wrong', style: TextStyle(color: Colors.white70)),
          TextButton(
            onPressed: () => _onSearch(_searchController.text),
            child: const Text('Retry', style: TextStyle(color: Color(0xFFBB86FC))),
          ),
        ],
      ),
    );
  }
}

class _TopSongsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyRepo = ref.watch(historyRepositoryProvider);
    final topSongIds = historyRepo.getTopSongIds(limit: 5);
    
    if (topSongIds.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Top Songs',
            style: TextStyle(color: Colors.white70, fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12.h),
          ...topSongIds.map((entry) {
            // Try to find the song in the recent box or songs box
            late final Song song;
            try {
               song = Hive.box<Song>(HiveBoxes.recentSongs).values.firstWhere(
                (s) => s.id == entry.key,
                orElse: () => Hive.box<Song>(HiveBoxes.songs).values.firstWhere(
                  (s) => s.id == entry.key,
                  orElse: () => Hive.box<Song>(HiveBoxes.downloads).values.firstWhere(
                    (s) => s.id == entry.key,
                    orElse: () => throw Exception('Not found'),
                  ),
                ),
              );
            } catch (_) {
              return const SizedBox.shrink();
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: song.imageUrl,
                  width: 44.w,
                  height: 44.w,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(song.title, style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600)),
              subtitle: Text('${entry.value} plays', style: TextStyle(color: Colors.white38, fontSize: 11.sp)),
              onTap: () {
                ref.read(playerNotifierProvider.notifier).playSong(song);
                openImmersivePlayer(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
