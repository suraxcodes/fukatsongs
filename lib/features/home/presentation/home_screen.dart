import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/song.dart';
import 'home_notifier.dart';
import '../../player/presentation/player_notifier.dart';
import '../../player/presentation/immersive_player_screen.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../core/widgets/song_skeleton.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: homeState.when(
              data: (state) => _buildHomeContent(context, state, ref),
              loading: () => _buildLoadingHome(),
              error: (err, stack) => _buildErrorHome(ref),
            ),
          ),
          // Extra space for mini player
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'fukatSongs',
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history_rounded, color: Colors.white70),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white70),
          onPressed: () {},
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildHomeContent(BuildContext context, HomeState state, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.quickPicks.isNotEmpty) ...[
          const PremiumSectionHeader(title: 'Quick Picks'),
          _buildQuickPicksGrid(state.quickPicks, ref),
        ],
        const PremiumSectionHeader(title: 'Trending Now'),
        _buildTrendingSection(state.trending, ref),
      ],
    );
  }

  Widget _buildQuickPicksGrid(List<Song> songs, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
      ),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return GestureDetector(
          onTap: () {
            ref.read(playerNotifierProvider.notifier).setQueueAndPlay(
              List<Song>.from(songs),
              startIndex: index,
            );
            Future.delayed(const Duration(milliseconds: 200), () {
              if (context.mounted) openImmersivePlayer(context);
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.white10),
                    errorWidget: (context, url, error) => const Icon(Icons.music_note, color: Colors.white24),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.sp, color: Colors.white54),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendingSection(List<Song> songs, WidgetRef ref) {
    return SizedBox(
      height: 220.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: GestureDetector(
              onTap: () {
                ref.read(playerNotifierProvider.notifier).setQueueAndPlay(
                  List<Song>.from(songs),
                  startIndex: index,
                );
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (context.mounted) openImmersivePlayer(context);
                });
              },
              child: SizedBox(
                width: 140.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassContainer(
                      borderRadius: 20,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: CachedNetworkImage(
                          imageUrl: song.imageUrl.replaceAll('150x150', '500x500'),
                          width: 140.w,
                          height: 140.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingHome() {
    return Column(
      children: [
        const PremiumSectionHeader(title: 'Quick Picks'),
        SizedBox(
          height: 150.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: 3,
            itemBuilder: (context, index) => const SongSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorHome(WidgetRef ref) {
    return Center(
      child: Column(
        children: [
          const Text('Failed to load home', style: TextStyle(color: Colors.white70)),
          TextButton(
            onPressed: () => ref.read(homeNotifierProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
