import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/models/playlist.dart';
import 'package:fukat_songs/features/home/presentation/home_notifier.dart';
import 'package:fukat_songs/features/player/presentation/player_notifier.dart';
import 'package:fukat_songs/features/player/presentation/immersive_player_screen.dart';
import 'package:fukat_songs/features/library/presentation/playlist_detail_screen.dart';
import 'package:fukat_songs/core/widgets/song_skeleton.dart';
import 'package:fukat_songs/features/library/presentation/song_options_sheet.dart';
import 'package:fukat_songs/features/main/main_screen_notifier.dart';
import 'package:fukat_songs/features/settings/presentation/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      ref.read(homeNotifierProvider.notifier).fetchMoreFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),
      body: RefreshIndicator(
        color: const Color(0xFFBB86FC),
        backgroundColor: const Color(0xFF1E1E2C),
        onRefresh: () => ref.read(homeNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            homeState.when(
              data: (state) => _buildCategoryChips(state),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            SliverToBoxAdapter(
              child: homeState.when(
                data: (state) => _buildHomeContent(context, state),
                loading: () => _buildLoadingState(),
                error: (err, stack) => _buildErrorState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: const Color(0xFF0D0B1F),
      elevation: 0,
      leadingWidth: 200.w,
      leading: Padding(
        padding: EdgeInsets.only(left: 16.w),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 32.w,
                height: 32.w,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 32.w,
                  height: 32.w,
                  color: const Color(0xFFBB86FC),
                  child: const Icon(Icons.music_note, color: Colors.black, size: 20),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'fukatSongs',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 28),
          onPressed: () => ref.read(mainScreenNotifierProvider.notifier).state = 1,
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white70),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildCategoryChips(HomeState state) {
    final categories = ['Podcasts', 'Romance', 'Relax', 'Feel good', 'Energy', 'Workout'];
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = state.selectedCategory == cat;
            return GestureDetector(
              onTap: () => ref.read(homeNotifierProvider.notifier).setCategory(isSelected ? '' : cat),
              child: Container(
                margin: EdgeInsets.only(right: 10.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFBB86FC) : Colors.white10,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: isSelected ? const Color(0xFFBB86FC) : Colors.white10),
                ),
                alignment: Alignment.center,
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white, 
                    fontSize: 13.sp, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, HomeState state) {
    if (state.selectedCategory.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 16.h),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                  onPressed: () => ref.read(homeNotifierProvider.notifier).setCategory(''),
                ),
                Text(
                  state.selectedCategory, 
                  style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (state.isLoading)
            Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
            )
          else
            _buildSongVerticalList(state.categorySongs),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.speedDialItems.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Text('Speed dial', style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              ],
            ),
          ),
          _buildSpeedDialGrid(state.speedDialItems),
        ],

        if (state.samples.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'Samples for you',
              style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 12.h),
          _buildHorizontalSongList(state.samples, cardWidth: 130.w, cardHeight: 130.w),
        ],

        if (state.trending.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'Trending songs',
              style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 12.h),
          _buildHorizontalSongList(state.trending, cardWidth: 130.w, cardHeight: 130.w),
        ],

        SizedBox(height: 24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick picks', style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  if (state.quickPicks.isNotEmpty) {
                    ref.read(playerNotifierProvider.notifier).setQueueAndPlay(state.quickPicks);
                    openImmersivePlayer(context);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text('Play all', style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                ),
              ),
            ],
          ),
        ),
        _buildSongVerticalList(state.quickPicks),

        if (state.paginatedFeed.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'For You Feed',
              style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSongVerticalList(state.paginatedFeed, isFeed: true),
        ],

        if (state.isFetchingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFFBB86FC))),
          ),

        SizedBox(height: 100.h),
      ],
    );
  }

  Widget _buildHorizontalSongList(List<Song> songs, {required double cardWidth, required double cardHeight}) {
    return SizedBox(
      height: (cardHeight + 64.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
            onTap: () {
              ref.read(playerNotifierProvider.notifier).setQueueAndPlay(songs, startIndex: index);
              openImmersivePlayer(context);
            },
            child: Container(
              width: cardWidth,
              margin: EdgeInsets.only(right: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: CachedNetworkImage(
                          imageUrl: song.imageUrl,
                          width: cardWidth,
                          height: cardHeight,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          placeholder: (_, __) => Container(
                            width: cardWidth,
                            height: cardHeight,
                            color: Colors.white.withOpacity(0.05),
                            child: const Center(
                              child: Icon(Icons.music_note_rounded, color: Colors.white24),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: cardWidth,
                            height: cardHeight,
                            color: Colors.white.withOpacity(0.05),
                            child: const Center(
                              child: Icon(Icons.music_note_rounded, color: Colors.white24),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8.w,
                        bottom: 8.h,
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white54, fontSize: 11.sp),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpeedDialGrid(List<dynamic> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 2.8,
      ),
      itemCount: items.length.clamp(0, 6),
      itemBuilder: (context, index) {
        final item = items[index];
        final String title = item is Song ? item.title : (item as Playlist).name;
        final String imageUrl = item is Song ? item.imageUrl : '';
        
        return GestureDetector(
          onTap: () {
            if (item is Song) {
              ref.read(playerNotifierProvider.notifier).playSong(item);
              openImmersivePlayer(context);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: item as Playlist)),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8.r), bottomLeft: Radius.circular(8.r)),
                  child: imageUrl.isNotEmpty 
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 56.w,
                        height: 56.w,
                        fit: BoxFit.cover,
                        memCacheWidth: 150,
                        errorWidget: (_, __, ___) => _playlistPlaceholder(),
                      )
                    : _playlistPlaceholder(),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _playlistPlaceholder() {
    return Container(
      width: 56.w,
      height: 56.w,
      color: Colors.white10,
      child: const Icon(Icons.queue_music_rounded, color: Colors.white38),
    );
  }

  Widget _buildSongVerticalList(List<Song> songs, {bool isFeed = false}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return RepaintBoundary(
          child: ListTile(
            onTap: () {
              ref.read(playerNotifierProvider.notifier).setQueueAndPlay(songs, startIndex: index);
              openImmersivePlayer(context);
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: CachedNetworkImage(
                imageUrl: song.imageUrl,
                width: 48.w,
                height: 48.w,
                fit: BoxFit.cover,
                memCacheWidth: 120,
                placeholder: (_, __) => Container(
                  width: 48.w,
                  height: 48.w,
                  color: Colors.white.withOpacity(0.05),
                  child: const Center(child: Icon(Icons.music_note, color: Colors.white24, size: 20)),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 48.w,
                  height: 48.w,
                  color: Colors.white.withOpacity(0.05),
                  child: const Center(child: Icon(Icons.music_note, color: Colors.white24, size: 20)),
                ),
              ),
            ),
            title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500)),
            subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
              onPressed: () => showSongOptions(context, song),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(3, (index) => const SongSkeleton()),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white24, size: 48),
          SizedBox(height: 16.h),
          const Text('Something went wrong', style: TextStyle(color: Colors.white70)),
          TextButton(
            onPressed: () => ref.read(homeNotifierProvider.notifier).refresh(),
            child: const Text('Retry', style: TextStyle(color: Color(0xFFBB86FC))),
          ),
        ],
      ),
    );
  }
}
