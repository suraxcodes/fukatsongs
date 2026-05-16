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
import 'package:fukat_songs/core/widgets/premium_widgets.dart';
import 'package:fukat_songs/core/widgets/song_skeleton.dart';
import 'package:fukat_songs/features/library/presentation/song_options_sheet.dart';
import 'package:fukat_songs/features/main/main_screen_notifier.dart';
import 'package:fukat_songs/features/settings/presentation/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),
      body: RefreshIndicator(
        color: const Color(0xFFBB86FC),
        backgroundColor: const Color(0xFF1E1E2C),
        onRefresh: () => ref.read(homeNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
          slivers: [
            _buildAppBar(context, ref),
            homeState.when(
              data: (state) => _buildCategoryChips(ref, state),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            SliverToBoxAdapter(
              child: homeState.when(
                data: (state) => _buildHomeContent(context, state, ref),
                loading: () => _buildLoadingState(),
                error: (err, stack) => _buildErrorState(ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
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

  Widget _buildCategoryChips(WidgetRef ref, HomeState state) {
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

  Widget _buildHomeContent(BuildContext context, HomeState state, WidgetRef ref) {
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
            _buildQuickPicksList(state.categorySongs, ref),
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
          _buildSpeedDialGrid(state.speedDialItems, ref),
        ],
        SizedBox(height: 24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quick picks', style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text('Play all', style: TextStyle(color: Colors.white, fontSize: 12.sp)),
              ),
            ],
          ),
        ),
        _buildQuickPicksList(state.quickPicks, ref),
        SizedBox(height: 100.h),
      ],
    );
  }

  Widget _buildSpeedDialGrid(List<dynamic> items, WidgetRef ref) {
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
                        memCacheWidth: 150, // Optimize memory for thumbnails
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

  Widget _buildQuickPicksList(List<Song> songs, WidgetRef ref) {
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
              borderRadius: BorderRadius.circular(4.r),
              child: CachedNetworkImage(
                imageUrl: song.imageUrl,
                width: 48.w,
                height: 48.w,
                fit: BoxFit.cover,
                memCacheWidth: 120,
              ),
            ),
            title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
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

  Widget _buildErrorState(WidgetRef ref) {
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
