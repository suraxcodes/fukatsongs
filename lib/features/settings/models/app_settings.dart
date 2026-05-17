import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('320') String streamingQuality,
    @Default('320') String downloadQuality,
    @Default(true) bool useSystemTheme,
    @Default(false) bool isDarkMode,
    @Default(true) bool highFidelityMode,
    @Default(false) bool loudnessEnhancement,
    @Default(true) bool isAutoplayEnabled,
    @Default(false) bool isGaplessPlayback,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
