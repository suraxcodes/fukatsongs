import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

enum IslandState { compact, expanded, dismissed }

class DynamicIslandOverlay extends StatefulWidget {
  final Stream<double>? progressStream;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const DynamicIslandOverlay({
    Key? key,
    this.progressStream,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  State<DynamicIslandOverlay> createState() => _DynamicIslandOverlayState();
}

class _DynamicIslandOverlayState extends State<DynamicIslandOverlay>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<IslandState> _state = ValueNotifier(IslandState.compact);

  String _title = "No Music";
  String _artist = "Unknown Artist";
  String _coverUrl = "";
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        setState(() {
          _title = event['title'] ?? _title;
          _artist = event['artist'] ?? _artist;
          _coverUrl = event['cover'] ?? _coverUrl;
          if (event.containsKey('isPlaying')) {
            _isPlaying = event['isPlaying'];
          }
        });
      } else if (event == "show_island") {
        if (_state.value == IslandState.dismissed) {
          _state.value = IslandState.compact;
          try {
            FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
          } catch (_) {}
        }
      }
    });
  }

  final Duration _duration = const Duration(milliseconds: 600);
  final Curve _curve = const ElasticOutCurve(0.9);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: ValueListenableBuilder<IslandState>(
          valueListenable: _state,
          builder: (context, state, child) {
            if (state == IslandState.dismissed) return const SizedBox.shrink();

            final isExpanded = state == IslandState.expanded;

            return GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! > 0) {
                    // Swiped Right -> Previous
                    widget.onPrevious();
                  } else if (details.primaryVelocity! < 0) {
                    // Swiped Left -> Next
                    widget.onNext();
                  }
                }
              },
              onLongPress: () async {
                // To avoid the freeze bug on Android and the "goes to the side" OS behavior,
                // we don't close or resize the window. We just hide the UI and tell Android
                // to let all touches pass through the transparent window.
                _state.value = IslandState.dismissed;
                try {
                  await FlutterOverlayWindow.updateFlag(
                      OverlayFlag.clickThrough);
                } catch (_) {}
              },
              onTap: () {
                if (_state.value == IslandState.expanded) {
                  _state.value = IslandState.compact;
                } else if (_state.value == IslandState.compact) {
                  _state.value = IslandState.expanded;
                  // Ensure overlay accepts clicks when expanded so controls render and work
                  try {
                    FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
                  } catch (_) {}
                }
              },
              child: AnimatedContainer(
                duration: _duration,
                curve: _curve,
                // keep original expanded height so overlay size isn't increased
                height: isExpanded ? 200.0 : 48.0,
                width: isExpanded
                    ? MediaQuery.of(context).size.width * 0.9
                    : 180.0,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(isExpanded ? 32.0 : 20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isExpanded ? 32.0 : 20.0),
                  child: SizedBox(
                    height: isExpanded ? 200.0 : 48.0,
                    width: isExpanded
                        ? MediaQuery.of(context).size.width * 0.9
                        : 180.0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child:
                          isExpanded ? _buildExpandedUI() : _buildCompactUI(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactUI() {
    return Padding(
      key: const ValueKey('compact'),
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: Container(
              width: 24,
              height: 24,
              color: Colors.grey[800],
              child: _coverUrl.isNotEmpty
                  ? Image.network(_coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.music_note,
                          size: 12, color: Colors.white))
                  : const Icon(Icons.music_note, size: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _artist,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (index) => _buildWaveBar()),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildWaveBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 3,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.greenAccent,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // No file-based diagnostics in production.

  Widget _buildExpandedUI() {
    return SingleChildScrollView(
      key: const ValueKey('expanded'),
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        // reduce vertical padding so controls sit closer to title
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[800],
                    child: _coverUrl.isNotEmpty
                        ? Image.network(_coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.music_note,
                                color: Colors.white))
                        : const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(_artist,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            // smaller gap between title row and controls to bring buttons closer
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () {
                      try {
                        print('DynamicIslandOverlay: previous pressed');
                      } catch (_) {}
                      try {
                        widget.onPrevious();
                      } catch (_) {}
                      try {
                        FlutterOverlayWindow.shareData({"action": "previous"});
                      } catch (e) {
                        try {
                          print(
                              'DynamicIslandOverlay: shareData previous failed: $e');
                        } catch (_) {}
                      }
                    }),
                IconButton(
                    icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 40),
                    onPressed: () {
                      try {
                        print('DynamicIslandOverlay: play_pause pressed');
                      } catch (_) {}
                      try {
                        widget.onPlayPause();
                      } catch (_) {}
                      try {
                        FlutterOverlayWindow.shareData({"action": "play_pause"});
                      } catch (e) {
                        try {
                          print(
                              'DynamicIslandOverlay: shareData play_pause failed: $e');
                        } catch (_) {}
                      }
                    }),
                IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () {
                      try {
                        print('DynamicIslandOverlay: next pressed');
                      } catch (_) {}
                      try {
                        widget.onNext();
                      } catch (_) {}
                      try {
                        FlutterOverlayWindow.shareData({"action": "next"});
                      } catch (e) {
                        try {
                          print(
                              'DynamicIslandOverlay: shareData next failed: $e');
                        } catch (_) {}
                      }
                    }),
              ],
            )
          ],
        ),
      ),
    );
  }
}
