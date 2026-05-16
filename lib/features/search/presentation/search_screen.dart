import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fukat_songs/features/search/presentation/search_notifier.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/features/search/presentation/widgets/song_card.dart';
import 'package:fukat_songs/features/player/presentation/player_notifier.dart';
import 'package:fukat_songs/features/settings/presentation/settings_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fukat_songs/core/widgets/song_skeleton.dart';
import 'package:fukat_songs/core/services/connectivity_service.dart';
import 'package:fukat_songs/core/repositories/history_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    ref.read(searchNotifierProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final notifier = ref.read(searchNotifierProvider.notifier);
    final connectivity = ref.watch(connectivityServiceProvider);
    final history = ref.watch(historyRepositoryProvider).getSearchHistory();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(context, notifier, connectivity),
            if (history.isNotEmpty && _searchController.text.isEmpty)
              _buildRecentSearches(history),
            Expanded(
              child: searchState.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildResults(songs, ref);
                },
                loading: () => _buildLoadingGrid(),
                error: (err, stack) => _buildErrorState(notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(List<String> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ),
        SizedBox(
          height: 40.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final query = history[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: InputChip(
                  label: Text(query),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  labelStyle: TextStyle(color: Colors.white, fontSize: 12.sp),
                  onPressed: () {
                    _searchController.text = query;
                    _onSearch(query);
                  },
                  onDeleted: () {
                    ref.read(historyRepositoryProvider).removeFromSearchHistory(query);
                    setState(() {});
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, SearchNotifier notifier, AsyncValue<ConnectivityResult> connectivity) {
    final isOffline = connectivity.value == ConnectivityResult.none;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: isOffline ? 'Search your library...' : 'Search songs, artists...',
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20.w),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const SettingsScreen())
            ),
            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
          ),
        ],
      ),
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

  Widget _buildResults(List songs, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 100.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'Results',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 8.w),
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
                  ref.read(playerNotifierProvider.notifier).setQueueAndPlay(
                    List<Song>.from(songs),
                    startIndex: index,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No songs found',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildErrorState(SearchNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Something went wrong', style: TextStyle(color: Colors.white70)),
          TextButton(
            onPressed: () {
              _searchController.clear();
              _onSearch('');
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
