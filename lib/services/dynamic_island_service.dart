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
      } else if (event == "close_island") {
        closeDynamicIsland();
      }
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
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (_) {}
  }
}
