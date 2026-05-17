import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fukat_songs/models/song.dart';
import 'package:fukat_songs/providers/music_repository_provider.dart';
import 'package:fukat_songs/features/player/presentation/player_notifier.dart';
import 'package:fukat_songs/features/library/presentation/song_options_sheet.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  final String title;
  final String query;
  final String? imageUrl;

  const BrowseScreen({
    super.key,
    required this.title,
    required this.query,
    this.imageUrl,
  });

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  List<Song>? _songs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSongs();
  }

  Future<void> _fetchSongs() async {
    try {
      final songs = await ref.read(musicRepositoryProvider).search(widget.query);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1F),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_songs == null || _songs!.isEmpty)
            const SliverFillRemaining(child: Center(child: Text('No songs found', style: TextStyle(color: Colors.white54))))
          else
            _buildSongList(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250.h,
      pinned: true,
      backgroundColor: const Color(0xFF16142E),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(blurRadius: 10, color: Colors.black)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.imageUrl != null)
              CachedNetworkImage(
                imageUrl: widget.imageUrl!,
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6200EE), Color(0xFF0D0B1F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Icon(Icons.person_rounded, size: 100.sp, color: Colors.white10),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0D0B1F).withOpacity(0.8),
                    const Color(0xFF0D0B1F),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = _songs![index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: song.imageUrl,
                  width: 50.w,
                  height: 50.w,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                onPressed: () => showSongOptions(context, song),
              ),
              onTap: () {
                ref.read(playerNotifierProvider.notifier).setQueueAndPlay(_songs!, startIndex: index);
              },
            );
          },
          childCount: _songs!.length,
        ),
      ),
    );
  }
}
