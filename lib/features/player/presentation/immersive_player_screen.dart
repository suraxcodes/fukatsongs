import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'player_notifier.dart';
import '../../../models/song.dart';

/// Opens the immersive player with a slide-up transition.
void openImmersivePlayer(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => const ImmersivePlayerScreen(),
  );
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

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.5, 1.0],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Stack(
            children: [
              // Blurred background artwork
              _buildBackground(song),
              // Frosted overlay
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
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
              // Content
              SafeArea(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                              onPressed: () {},
                            ),
                          ],
                        ),
                        SizedBox(height: 24.h),
                        // Artwork with animation
                        ScaleTransition(
                          scale: _artworkScale,
                          child: Container(
                            width: 300.w,
                            height: 300.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
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
                                  Text(
                                    song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.white60,
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
                        _buildBottomActions(song),
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

  Widget _buildUpNext(playerState, notifier) {
    final queue = (playerState.queue as List<Song>);
    final currentIndex = playerState.currentIndex as int;
    final upcoming = queue.length > currentIndex + 1
        ? queue.sublist(currentIndex + 1, (currentIndex + 4).clamp(0, queue.length))
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
              Text('${queue.length - currentIndex - 1} songs', style: TextStyle(
                color: Colors.white38,
                fontSize: 12.sp,
              )),
            ],
          ),
        ),
        ...upcoming.asMap().entries.map((entry) {
          final idx = currentIndex + 1 + entry.key;
          final s = entry.value;
          return GestureDetector(
            onTap: () => notifier.skipToIndex(idx),
            child: Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CachedNetworkImage(
                      imageUrl: s.imageUrl,
                      width: 44.w,
                      height: 44.w,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 44.w,
                        height: 44.w,
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
                  Icon(Icons.drag_handle_rounded, color: Colors.white24, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomActions(Song song) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(Icons.devices_rounded, 'Devices'),
        _actionButton(Icons.playlist_add_rounded, 'Playlist'),
        _actionButton(Icons.download_rounded, 'Download'),
        _actionButton(Icons.share_rounded, 'Share'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Icon(icon, color: Colors.white70, size: 22),
        ),
        SizedBox(height: 6.h),
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 10.sp)),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
