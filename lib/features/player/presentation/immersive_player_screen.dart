import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:fukat_songs/features/player/presentation/player_notifier.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/features/library/presentation/song_options_sheet.dart';
import 'package:fukat_songs/features/library/logic/playlist_notifier.dart';
import 'package:fukat_songs/features/library/logic/song_download_notifier.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fukat_songs/core/constants/hive_boxes.dart';
import 'package:fukat_songs/features/player/logic/lyrics_notifier.dart';
import 'package:fukat_songs/features/player/presentation/player_state.dart';
import 'package:fukat_songs/features/player/presentation/widgets/lyrics_view.dart';
import 'package:fukat_songs/features/search/presentation/browse_screen.dart';
import 'package:fukat_songs/features/settings/logic/settings_notifier.dart';

/// Guard flag — prevents duplicate player sheets from stacking
bool _isPlayerOpen = false;

/// Opens the immersive player with a slide-up transition.
/// Safe to call multiple times — only one sheet will ever be open.
void openImmersivePlayer(BuildContext context) {
  if (_isPlayerOpen) return; // Already open — ignore duplicate calls
  _isPlayerOpen = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => const ImmersivePlayerScreen(),
  ).whenComplete(() {
    _isPlayerOpen = false; // Reset when dismissed
  });
}

class ImmersivePlayerScreen extends ConsumerStatefulWidget {
  const ImmersivePlayerScreen({super.key});

  @override
  ConsumerState<ImmersivePlayerScreen> createState() => _ImmersivePlayerScreenState();
}

class _ImmersivePlayerScreenState extends ConsumerState<ImmersivePlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _artworkController;
  late Animation<double> _artworkScale;
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
    _artworkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _artworkScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _artworkController, curve: Curves.easeOutBack),
    );
    _artworkController.forward();
  }

  @override
  void dispose() {
    _artworkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerNotifierProvider);
    final notifier = ref.read(playerNotifierProvider.notifier);
    final song = playerState.currentSong;

    if (song == null) return const SizedBox.shrink();

    final isLoading = playerState.processingState == AudioProcessingState.loading ||
        playerState.processingState == AudioProcessingState.buffering;

    final lowPerf = ref.watch(settingsNotifierProvider.select((s) => s.lowPerformanceMode));
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.5, 1.0],
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0B1F),
          body: Stack(
            children: [
              if (!lowPerf) ...[
                // Blurred background artwork
                _buildBackground(song),
                // Frosted overlay
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0D0B1F).withOpacity(0.6),
                          const Color(0xFF0D0B1F).withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Solid high-performance deep dark background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0D0B1F),
                        Color(0xFF06050F),
                      ],
                    ),
                  ),
                ),
              ],
              // Content
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Half: Artwork / Lyrics
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  const SizedBox(height: 16),
                                  // Artwork or Lyrics
                                  RepaintBoundary(
                                    child: AnimatedCrossFade(
                                      duration: const Duration(milliseconds: 300),
                                      crossFadeState: _showLyrics ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                      firstChild: ScaleTransition(
                                        scale: _artworkScale,
                                        child: Container(
                                          width: 320,
                                          height: 320,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: lowPerf ? null : [
                                              BoxShadow(
                                                color: const Color(0xFF6200EE).withOpacity(0.5),
                                                blurRadius: 40,
                                                spreadRadius: 8,
                                                offset: const Offset(0, 12),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: CachedNetworkImage(
                                              imageUrl: song.imageUrl.replaceAll('150x150', '500x500'),
                                              fit: BoxFit.cover,
                                              memCacheWidth: 600,
                                              placeholder: (context, url) => Container(
                                                color: Colors.white10,
                                                child: const Icon(Icons.music_note, size: 80, color: Colors.white24),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: Colors.white10,
                                                child: const Icon(Icons.music_note, size: 80, color: Colors.white24),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      secondChild: Container(
                                        width: 320,
                                        height: 320,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: Colors.white10),
                                        ),
                                        child: const LyricsView(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSourceBadge(song),
                                ],
                              ),
                            ),
                            const SizedBox(width: 40),
                            // Right Half: Controls, Queue & details
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              song.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(context, MaterialPageRoute(
                                                  builder: (_) => BrowseScreen(
                                                    title: song.artist,
                                                    query: song.artist,
                                                    imageUrl: song.imageUrl,
                                                  ),
                                                ));
                                              },
                                              child: Text(
                                                song.artist,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white60,
                                                  decoration: TextDecoration.underline,
                                                  decorationColor: Colors.white30,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildQualityBadge(),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  _buildSeekBar(playerState, notifier),
                                  const SizedBox(height: 24),
                                  _buildControls(playerState, notifier, isLoading),
                                  const SizedBox(height: 24),
                                  _buildBottomActions(song, playerState, notifier),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            children: [
                              SizedBox(height: 12.h),
                              // Drag handle
                              Container(
                                width: 40.w,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: Colors.white30,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              // Header row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        'NOW PLAYING',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white54,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      _buildSourceBadge(song),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                                    onPressed: () => showSongOptions(context, song),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24.h),
                              // Artwork or Lyrics
                              RepaintBoundary(
                                child: AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 300),
                                  crossFadeState: _showLyrics ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                  firstChild: ScaleTransition(
                                    scale: _artworkScale,
                                    child: Container(
                                      width: 300.w,
                                      height: 300.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24.r),
                                        boxShadow: lowPerf ? null : [
                                          BoxShadow(
                                            color: const Color(0xFF6200EE).withOpacity(0.5),
                                            blurRadius: 40,
                                            spreadRadius: 8,
                                            offset: const Offset(0, 12),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24.r),
                                        child: CachedNetworkImage(
                                          imageUrl: song.imageUrl.replaceAll('150x150', '500x500'),
                                          fit: BoxFit.cover,
                                          memCacheWidth: 600,
                                          placeholder: (context, url) => Container(
                                            color: Colors.white10,
                                            child: const Icon(Icons.music_note, size: 80, color: Colors.white24),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.white10,
                                            child: const Icon(Icons.music_note, size: 80, color: Colors.white24),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  secondChild: Container(
                                    width: 300.w,
                                    height: 300.w,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(24.r),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: const LyricsView(),
                                  ),
                                ),
                              ),
                              SizedBox(height: 32.h),
                              // Title, Artist & Like row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          song.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 22.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => BrowseScreen(
                                                title: song.artist,
                                                query: song.artist,
                                                imageUrl: song.imageUrl,
                                              ),
                                            ));
                                          },
                                          child: Text(
                                            song.artist,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              color: Colors.white60,
                                              decoration: TextDecoration.underline,
                                              decorationColor: Colors.white30,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildQualityBadge(),
                                ],
                              ),
                              SizedBox(height: 28.h),
                              // Seek Bar
                              _buildSeekBar(playerState, notifier),
                              SizedBox(height: 24.h),
                              // Controls
                              _buildControls(playerState, notifier, isLoading),
                              SizedBox(height: 24.h),
                              // Up Next queue
                              _buildUpNext(playerState, notifier),
                              SizedBox(height: 24.h),
                              // Volume & More row
                              _buildBottomActions(song, playerState, notifier),
                              SizedBox(height: 24.h),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground(Song song) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: song.imageUrl.replaceAll('150x150', '500x500'),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              memCacheWidth: 100, // Small cache for blurred background saves tons of RAM
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(Song song) {
    final source = song.source;
    final isYouTube = source == 'youtube';
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isYouTube ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isYouTube ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isYouTube ? Icons.play_circle_filled_rounded : Icons.music_note_rounded,
            color: isYouTube ? Colors.red : Colors.greenAccent,
            size: 12.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            isYouTube ? 'YouTube' : 'Saavn',
            style: TextStyle(
              color: isYouTube ? Colors.red : Colors.greenAccent,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF6200EE).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFF6200EE).withOpacity(0.4)),
      ),
      child: Text(
        'HD',
        style: TextStyle(
          color: const Color(0xFFBB86FC),
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSeekBar(playerState, notifier) {
    final position = playerState.position;
    final duration = playerState.totalDuration;
    final maxVal = duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0;
    final curVal = position.inSeconds.toDouble().clamp(0.0, maxVal);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: const Color(0xFF6200EE),
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
            overlayColor: const Color(0xFF6200EE).withOpacity(0.2),
          ),
          child: Slider(
            value: curVal,
            max: maxVal,
            onChanged: (val) => notifier.seek(Duration(seconds: val.toInt())),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(position), style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
              Text(_fmt(duration), style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(playerState, notifier, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: playerState.isShuffleModeEnabled ? const Color(0xFF6200EE) : Colors.white54,
            size: 26,
          ),
          onPressed: () => notifier.toggleShuffle(),
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 44),
          onPressed: () => notifier.skipToPrevious(),
        ),
        // Play/Pause button
        GestureDetector(
          onTap: () => playerState.isPlaying ? notifier.pause() : notifier.resume(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 68.w,
            height: 68.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2FF7), Color(0xFF6200EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6200EE).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Icon(
                      playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 44),
          onPressed: () => notifier.skipToNext(),
        ),
        IconButton(
          icon: Icon(
            playerState.repeatMode == AudioServiceRepeatMode.none
                ? Icons.repeat_rounded
                : playerState.repeatMode == AudioServiceRepeatMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
            color: playerState.repeatMode != AudioServiceRepeatMode.none
                ? const Color(0xFF6200EE)
                : Colors.white54,
            size: 26,
          ),
          onPressed: () => notifier.cycleRepeatMode(),
        ),
      ],
    );
  }

  Widget _buildUpNext(PlayerState playerState, PlayerNotifier notifier) {
    final queue = (playerState.queue as List<Song>);
    final currentIndex = playerState.currentIndex as int;
    
    // We want to reorder the "upcoming" part of the queue
    final upcoming = queue.length > currentIndex + 1
        ? queue.sublist(currentIndex + 1)
        : <Song>[];

    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Up Next', style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              )),
              Text('${upcoming.length} songs', style: TextStyle(
                color: Colors.white38,
                fontSize: 12.sp,
              )),
            ],
          ),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: upcoming.length,
          onReorder: (oldIndex, newIndex) {
            // Adjust indices for the full queue
            notifier.reorderQueue(currentIndex + 1 + oldIndex, currentIndex + 1 + newIndex);
          },
          itemBuilder: (context, index) {
            final s = upcoming[index];
            final idx = currentIndex + 1 + index;
            return GestureDetector(
              key: ValueKey(s.id + idx.toString()), // Unique key per position
              onTap: () => notifier.skipToIndex(idx),
              child: Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: CachedNetworkImage(
                        imageUrl: s.imageUrl,
                        width: 48.w,
                        height: 48.w,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 48.w,
                          height: 48.w,
                          color: Colors.white10,
                          child: const Icon(Icons.music_note, color: Colors.white24),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                          Text(s.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
                        ],
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle_rounded, color: Colors.white24, size: 22.sp),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomActions(Song song, PlayerState playerState, PlayerNotifier notifier) {
    final isDownloaded = Hive.box<Song>(HiveBoxes.downloads).containsKey(song.id);
    final downloadState = ref.watch(downloadNotifierProvider);
    final isDownloading = downloadState.containsKey(song.id);
    final progress = downloadState[song.id] ?? 0.0;
    
    final playlists = ref.watch(playlistNotifierProvider);
    final isInPlaylist = playlists.any((pl) => pl.songs.any((s) => s.id == song.id));
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        _actionButton(Icons.devices_rounded, 'Devices', () {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(const SnackBar(content: Text('Device switching coming soon')));
        }),
        SizedBox(width: 15.w),
        _actionButton(
          isInPlaylist ? Icons.playlist_add_check_rounded : Icons.playlist_add_rounded, 
          isInPlaylist ? 'Added' : 'Playlist', 
          () {
            if (isInPlaylist) {
              _showPlaylistOptions(context, ref, song);
            } else {
              showAddToPlaylistSheet(context, ref, song);
            }
          },
          color: isInPlaylist ? const Color(0xFFBB86FC) : Colors.white70,
        ),
        SizedBox(width: 15.w),
        _actionButton(
          isDownloading ? Icons.downloading_rounded : (isDownloaded ? Icons.download_done_rounded : Icons.download_rounded), 
          isDownloading ? '${(progress * 100).toInt()}%' : (isDownloaded ? 'Saved' : 'Download'),
          () {
            final messenger = ScaffoldMessenger.of(context);
            if (isDownloaded) {
              messenger.showSnackBar(const SnackBar(content: Text('Already downloaded')));
            } else if (isDownloading) {
              ref.read(downloadNotifierProvider.notifier).cancelDownload(song.id);
              messenger.showSnackBar(const SnackBar(content: Text('Download cancelled')));
            } else {
              ref.read(downloadNotifierProvider.notifier).downloadSong(song);
              messenger.showSnackBar(const SnackBar(content: Text('Starting download...')));
            }
          },
          color: isDownloaded ? Colors.greenAccent : (isDownloading ? const Color(0xFF6200EE) : Colors.white70),
          trailing: isDownloading ? SizedBox(
            width: 14.w,
            height: 14.w,
            child: CircularProgressIndicator(value: progress, strokeWidth: 2, color: const Color(0xFF6200EE)),
          ) : null,
        ),
        SizedBox(width: 15.w),
        _actionButton(Icons.share_rounded, 'Share', () {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(const SnackBar(content: Text('Sharing coming soon')));
        }),
        SizedBox(width: 15.w),
        _actionButton(
          _showLyrics ? Icons.lyrics_rounded : Icons.lyrics_outlined,
          'Lyrics',
          () {
            setState(() {
              _showLyrics = !_showLyrics;
            });
            if (_showLyrics) {
              ref.read(lyricsProvider.notifier).fetchLyrics(song);
            }
          },
          color: _showLyrics ? const Color(0xFFBB86FC) : Colors.white70,
        ),
      ],
    ),
  );
}

  Widget _actionButton(IconData icon, String label, VoidCallback onTap, {Color color = Colors.white70, Widget? trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32.r),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  if (trailing != null)
                    Positioned.fill(child: Center(child: trailing)),
                ],
              ),
              SizedBox(height: 6.h),
              Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, WidgetRef ref, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16142E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Container(width: 40.w, height: 4.h, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2.r))),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: Colors.white70),
              title: const Text('Add to another playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                showAddToPlaylistSheet(context, ref, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_remove_rounded, color: Colors.redAccent),
              title: const Text('Remove from all playlists', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                ref.read(playlistNotifierProvider.notifier).removeSongFromAllPlaylists(song.id);
                Navigator.pop(ctx);
                messenger.showSnackBar(const SnackBar(content: Text('Removed from all playlists')));
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16.h),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
