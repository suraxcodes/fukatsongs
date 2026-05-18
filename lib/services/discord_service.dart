import 'dart:developer';
import 'dart:io';
import 'package:fukatsongs/core/models/exported.dart';
import 'package:fukatsongs/core/constants/sentinel_values.dart';
// Removed dart_discord_rpc import for Android-only build compatibility

class DiscordService {
  /// Initializes Discord RPC once (No-op on Android)
  static void initialize() {
    log("Discord RPC is disabled in this build.", name: "DiscordService");
  }

  /// Updates the Discord presence (No-op on Android)
  static void updatePresence({
    required Track track,
    required bool isPlaying,
  }) {
    // No-op
  }

  /// Clears Discord presence (No-op on Android)
  static void clearPresence() {
    // No-op
  }
}
