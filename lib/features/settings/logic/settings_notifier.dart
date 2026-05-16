import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/app_settings.dart';

part 'settings_notifier.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  late Box _box;
  static const String _boxName = 'settings';
  static const String _key = 'app_settings';

  @override
  AppSettings build() {
    _box = Hive.box(_boxName);
    final String? jsonString = _box.get(_key);
    
    if (jsonString != null) {
      try {
        return AppSettings.fromJson(json.decode(jsonString));
      } catch (e) {
        return const AppSettings();
      }
    }
    
    return const AppSettings();
  }

  Future<void> updateStreamingQuality(String quality) async {
    state = state.copyWith(streamingQuality: quality);
    await _save();
  }

  Future<void> updateDownloadQuality(String quality) async {
    state = state.copyWith(downloadQuality: quality);
    await _save();
  }

  Future<void> toggleDarkMode(bool isDark) async {
    state = state.copyWith(isDarkMode: isDark, useSystemTheme: false);
    await _save();
  }

  Future<void> _save() async {
    await _box.put(_key, json.encode(state.toJson()));
  }
}
