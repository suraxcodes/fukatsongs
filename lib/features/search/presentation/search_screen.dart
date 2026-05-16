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
            _buildSourceFilter(),
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

  Widget _buildSourceFilter() {
    final currentSource = ref.watch(searchSourceProvider);
    
    return Container(
      height: 40.h,
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _filterChip(
            label: 'All',
            icon: Icons.all_inclusive_rounded,
            isSelected: currentSource == SearchSource.both,
            onTap: () => _updateSource(SearchSource.both),
          ),
          _filterChip(
            label: 'JioSaavn',
            icon: Icons.music_note_rounded,
            isSelected: currentSource == SearchSource.saavn,
            onTap: () => _updateSource(SearchSource.saavn),
          ),
          _filterChip(
            label: 'YouTube',
            icon: Icons.play_circle_fill_rounded,
            isSelected: currentSource == SearchSource.youtube,
            onTap: () => _updateSource(SearchSource.youtube),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6200EE) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSource(SearchSource source) {
    ref.read(searchSourceProvider.notifier).state = source;
    if (_searchController.text.isNotEmpty) {
      _onSearch(_searchController.text);
    }
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
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 100.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
      ),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return SongCard(
          song: song,
          onTap: () {
            ref.read(playerNotifierProvider.notifier).setQueueAndPlay(songs, startIndex: index);
            openImmersivePlayer(context);
          },
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 100.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const SongSkeleton(),
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
