import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fukat_songs/core/constants/hive_boxes.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowChangelog();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(homeNotifierProvider.notifier).fetchMoreFeed();
    }
  }

  void _checkAndShowChangelog() {
    if (!mounted) return;
    final box = Hive.box(HiveBoxes.settings);
    const String appVersion = '1.2.0';
    final String? lastShown = box.get('last_shown_changelog_version');

    if (lastShown != appVersion) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            backgroundColor: const Color(0xFF131124),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: const BorderSide(color: Color(0x33BB86FC), width: 1.5),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x22BB86FC),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'WHAT\'S NEW IN V$appVersion',
                        style: TextStyle(
                          color: const Color(0xFFBB86FC),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Welcome to fukatSongs! 🎧', 
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Please read this carefully: occasionally, some songs might take 2-3 seconds to load or may fail to stream on the first attempt due to active block-bypass routing. Don\'t worry—simply try playing the song again, and it will work perfectly in 1 or 2 tries!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildChangelogItem(
                    icon: Icons.download_done_rounded,
                    title: 'High Fidelity Offline Downloads',
                    description:
                        'Save songs directly to your device and play them completely offline with zero data consumption.',
                  ),
                  _buildChangelogItem(
                    icon: Icons.lyrics_rounded,
                    title: 'Live Synced Lyrics',
                    description:
                        'Sing along with beautifully synchronized lyrics scrolling in real-time with the playhead.',
                  ),
                  _buildChangelogItem(
                    icon: Icons.tune_rounded,
                    title: 'Smart Audio Quality Control',
                    description:
                        'Switch between Low, Medium, and High audio streaming and download qualities to manage your data.',
                  ),
                  _buildChangelogItem(
                    icon: Icons.playlist_add_rounded,
                    title: 'Spotify & YouTube Playlist Imports',
                    description:
                        'Paste any public playlist link! The app automatically searches, matches, and saves all tracks to a local playlist for instant streaming or offline downloading.',
                  ),
                  _buildChangelogItem(
                    icon: Icons.favorite_rounded,
                    title: 'Custom Local Playlists & Favorites',
                    description:
                        'Create, organize, and manage your own custom local playlists and easily track your Liked Songs.',
                  ),
                  _buildChangelogItem(
                    icon: Icons.queue_music_rounded,
                    title: 'Stable Uninterrupted Queue',
                    description:
                        'Queue up your songs with confidence. Next tracks preload in the background to eliminate any gaps!',
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.hourglass_empty_rounded,
                          color: const Color(0xFFBB86FC),
                          size: 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⏱️ Loading Delay Notice',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'If a song takes 1-2 seconds to load, our advanced streaming engine is actively bypassing carrier blocks to keep your music running. Gaps are completely eliminated in queues via background preloading!\n\nNote: You might hear a brief \'pip-pip\' or \'bit-bit\' sound at the start of a song; this is normal and will automatically normalize after 5-7 seconds.',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11.sp,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0x1103DAC6),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0x3303DAC6)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.bug_report_rounded,
                          color: const Color(0xFF03DAC6),
                          size: 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🛠️ Help Us Improve!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'If you find any bugs, glitches, or things that need improvement while using fukatSongs, please inform me immediately so I can fix them!',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11.sp,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: ElevatedButton(
                      onPressed: () {
                        box.put('last_shown_changelog_version', appVersion);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBB86FC),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Let\'s Play! 🎵',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildChangelogItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFBB86FC), size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11.sp,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              error: (err, stack) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
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
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.black,
                    size: 20,
                  ),
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
          onPressed: () =>
              ref.read(mainScreenNotifierProvider.notifier).state = 1,
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
    final categories = [
      'Podcasts',
      'Romance',
      'Relax',
      'Feel good',
      'Energy',
      'Workout',
    ];
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
              onTap: () => ref
                  .read(homeNotifierProvider.notifier)
                  .setCategory(isSelected ? '' : cat),
              child: Container(
                margin: EdgeInsets.only(right: 10.w),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFBB86FC) : Colors.white10,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFBB86FC)
                        : Colors.white10,
                  ),
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
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white70,
                  ),
                  onPressed: () =>
                      ref.read(homeNotifierProvider.notifier).setCategory(''),
                ),
                Text(
                  state.selectedCategory,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (state.isLoading)
            Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFBB86FC)),
              ),
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
                Text(
                  'Speed dial',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          _buildHorizontalSongList(
            state.samples,
            cardWidth: 130.w,
            cardHeight: 130.w,
          ),
        ],

        if (state.trending.isNotEmpty) ...[
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              'Trending songs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          _buildHorizontalSongList(
            state.trending,
            cardWidth: 130.w,
            cardHeight: 130.w,
          ),
        ],

        SizedBox(height: 24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick picks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (state.quickPicks.isNotEmpty) {
                    ref
                        .read(playerNotifierProvider.notifier)
                        .setQueueAndPlay(state.quickPicks);
                    openImmersivePlayer(context);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    'Play all',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
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
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSongVerticalList(state.paginatedFeed, isFeed: true),
        ],

        if (state.isFetchingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFBB86FC)),
            ),
          ),

        SizedBox(height: 100.h),
      ],
    );
  }

  Widget _buildHorizontalSongList(
    List<Song> songs, {
    required double cardWidth,
    required double cardHeight,
  }) {
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
              ref
                  .read(playerNotifierProvider.notifier)
                  .setQueueAndPlay(songs, startIndex: index);
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
                              child: Icon(
                                Icons.music_note_rounded,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            width: cardWidth,
                            height: cardHeight,
                            color: Colors.white.withOpacity(0.05),
                            child: const Center(
                              child: Icon(
                                Icons.music_note_rounded,
                                color: Colors.white24,
                              ),
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
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
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
        final String title = item is Song
            ? item.title
            : (item as Playlist).name;
        final String imageUrl = item is Song ? item.imageUrl : '';

        return GestureDetector(
          onTap: () {
            if (item is Song) {
              ref.read(playerNotifierProvider.notifier).playSong(item);
              openImmersivePlayer(context);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PlaylistDetailScreen(playlist: item as Playlist),
                ),
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
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.r),
                    bottomLeft: Radius.circular(8.r),
                  ),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
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
              ref
                  .read(playerNotifierProvider.notifier)
                  .setQueueAndPlay(songs, startIndex: index);
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
                  child: const Center(
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 48.w,
                  height: 48.w,
                  color: Colors.white.withOpacity(0.05),
                  child: const Center(
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white54, fontSize: 12.sp),
            ),
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
    return Column(children: List.generate(3, (index) => const SongSkeleton()));
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white24,
            size: 48,
          ),
          SizedBox(height: 16.h),
          const Text(
            'Something went wrong',
            style: TextStyle(color: Colors.white70),
          ),
          TextButton(
            onPressed: () => ref.read(homeNotifierProvider.notifier).refresh(),
            child: const Text(
              'Retry',
              style: TextStyle(color: Color(0xFFBB86FC)),
            ),
          ),
        ],
      ),
    );
  }
}
