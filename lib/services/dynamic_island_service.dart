import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:fukatsongs/services/bloomee_player.dart';
import 'dart:developer';

class DynamicIslandService {
  static void initListener(BloomeeMusicPlayer player) {
    try {
      print('DynamicIslandService: initListener called');
    } catch (_) {}

    FlutterOverlayWindow.overlayListener.listen((event) {
      // Debug log to verify overlay events arrive in the main app process
      try {
        log('DynamicIslandService: overlay event received -> $event');
      } catch (_) {}
      // Also print so the `flutter run` terminal shows it directly
      try {
        print('DynamicIslandService: overlay event received -> $event');
      } catch (_) {}

      // Normalize event: overlay may send a String or a Map payload
      dynamic evt = event;
      if (event is Map && event.containsKey('action')) {
        evt = event['action'];
      }

      try {
        print('DynamicIslandService: normalized evt -> $evt');
      } catch (_) {}

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
          // Keep alignment centered so island appears in the center of the screen
          alignment: OverlayAlignment.center,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          // Use default height so we don't increase overlay size
          height: 400,
          width: WindowSize.matchParent,
        );
        // Ensure native overlay window accepts clicks so taps reach the widget
        try {
          await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
        } catch (_) {}
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

  // No file-poller in production.

  static Future<void> closeDynamicIsland() async {
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (_) {}
  }
}
