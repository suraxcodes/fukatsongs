import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:fukatsongs/services/bloomee_player.dart';
import 'dart:developer';

class DynamicIslandService {
  static void initListener(BloomeeMusicPlayer player) {
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event == "play_pause") {
        if (player.playbackState.value.playing) {
          player.pause();
        } else {
          player.play();
        }
      } else if (event == "next") {
        player.skipToNext();
      } else if (event == "previous") {
        player.skipToPrevious();
      }
    });

    // Send the currently playing song immediately (if any) so the Island doesn't start as 'Unknown'
    if (player.mediaItem.value != null) {
      final item = player.mediaItem.value!;
      FlutterOverlayWindow.shareData({
        "title": item.title,
        "artist": item.artist ?? "Unknown",
        "cover": item.artUri?.toString() ?? "",
      });
    }

    // Listen to media item changes to update the island UI
    player.mediaItem.listen((item) {
      if (item != null) {
        FlutterOverlayWindow.shareData({
          "title": item.title,
          "artist": item.artist ?? "Unknown",
          "cover": item.artUri?.toString() ?? "",
        });
      }
    });
  }

  static Future<void> showDynamicIsland() async {
    try {
      print("Checking overlay permission...");
      bool isGranted = await FlutterOverlayWindow.isPermissionGranted();
      print("Permission granted: $isGranted");
      
      if (isGranted) {
        print("Attempting to show overlay...");
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          flag: OverlayFlag.defaultFlag,
          alignment: OverlayAlignment.center, // Kept center to avoid MIUI Notch Crash
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          height: 250,
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

  static Future<void> closeDynamicIsland() async {
    await FlutterOverlayWindow.closeOverlay();
  }
}
