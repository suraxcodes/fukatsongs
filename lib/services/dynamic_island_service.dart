import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:fukatsongs/services/bloomee_player.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DynamicIslandService {
  static final Set<String> _processedEventLines = <String>{};
  static Timer? _filePoller;
  static void initListener(BloomeeMusicPlayer player) {
    FlutterOverlayWindow.overlayListener.listen((event) {
      // Normalize and process the event
      dynamic evt = event;
      if (event is Map && event.containsKey('action')) evt = event['action'];
      _processEvt(evt, player);
    });

    // Send the currently playing song immediately (if any) so the Island doesn't start as 'Unknown'
    if (player.mediaItem.value != null) {
      final item = player.mediaItem.value!;
      FlutterOverlayWindow.shareData({
        "title": item.title,
        "artist": item.artist ?? "Unknown",
        "cover": item.artUri?.toString() ?? "",
        "isPlaying": player.playbackState.value.playing,
      });
    }

    // Listen to media item changes to update the island UI
    player.mediaItem.listen((item) {
      if (item != null) {
        FlutterOverlayWindow.shareData({
          "title": item.title,
          "artist": item.artist ?? "Unknown",
          "cover": item.artUri?.toString() ?? "",
          "isPlaying": player.playbackState.value.playing,
        });
      }
    });

    // Listen to playback state changes to update the play/pause icon
    player.playbackState.listen((state) {
      FlutterOverlayWindow.shareData({
        "isPlaying": state.playing,
      });
    });

    // Start fallback file poller (helps on devices/ROMs where overlayListener messages are dropped)
    _startFilePoller(player);
  }

  static Future<void> showDynamicIsland() async {
    try {
      print("Checking overlay permission...");
      bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
      print("Permission granted: $isGranted");

      if (isGranted) {
        print("Attempting to show overlay...");
        final isActive = await FlutterOverlayWindow.isActive();
        if (isActive) {
          print("Overlay is already active. Broadcasting show_island...");
          FlutterOverlayWindow.shareData("show_island");
          return;
        }

        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          flag: OverlayFlag.defaultFlag,
          alignment:
              OverlayAlignment.center, // Kept center to avoid MIUI Notch Crash
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          height: 450,
          width: WindowSize.matchParent,
        );
        print("Overlay showed successfully.");
      } else {
        print("Requesting permission...");
        await FlutterOverlayWindow.requestPermission();
      }
    } catch (e) {
      print("Error showing overlay: $e");
    }
  }

  static void _processEvt(dynamic evt, BloomeeMusicPlayer player) {
    try {
      if (evt == "play_pause") {
        if (player.playbackState.value.playing) {
          player.pause();
        } else {
          player.play();
        }
      } else if (evt == "next") {
        player.skipToNext();
      } else if (evt == "previous") {
        player.skipToPrevious();
      } else if (evt == "close_island") {
        closeDynamicIsland();
      }
    } catch (e) {
      try {
        print('DynamicIslandService: _processEvt error: $e');
      } catch (_) {}
    }
  }

  static void _startFilePoller(BloomeeMusicPlayer player) {
    try {
      _filePoller?.cancel();
      _filePoller =
          Timer.periodic(const Duration(milliseconds: 700), (timer) async {
        try {
          final dir = await getExternalStorageDirectory();
          if (dir == null) return;
          final file = File('${dir.path}/dynamic_island_events.log');
          if (!await file.exists()) return;
          final lines = await file.readAsLines();
          for (final l in lines) {
            if (_processedEventLines.contains(l)) continue;
            _processedEventLines.add(l);
            final parts = l.split(' - ');
            final evt = parts.length > 1 ? parts[1].trim() : l.trim();
            try {
              print('DynamicIslandService: polled event -> $evt');
            } catch (_) {}
            _processEvt(evt, player);
          }
        } catch (e) {
          try {
            print('DynamicIslandService: file poll error: $e');
          } catch (_) {}
        }
      });
    } catch (e) {
      try {
        print('DynamicIslandService: startFilePoller failed: $e');
      } catch (_) {}
    }
  }

  static Future<void> closeDynamicIsland() async {
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (_) {}
  }

  /// Cancel the fallback event poller. MUST be called on teardown — this
  /// Timer.periodic otherwise keeps the UI isolate (and the whole process)
  /// alive after the user dismissed the app.
  static void stopPolling() {
    _filePoller?.cancel();
    _filePoller = null;
    _processedEventLines.clear();
  }
}
