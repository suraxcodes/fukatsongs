// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      streamingQuality: json['streamingQuality'] as String? ?? '320',
      downloadQuality: json['downloadQuality'] as String? ?? '320',
      useSystemTheme: json['useSystemTheme'] as bool? ?? true,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      highFidelityMode: json['highFidelityMode'] as bool? ?? true,
      loudnessEnhancement: json['loudnessEnhancement'] as bool? ?? false,
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'streamingQuality': instance.streamingQuality,
      'downloadQuality': instance.downloadQuality,
      'useSystemTheme': instance.useSystemTheme,
      'isDarkMode': instance.isDarkMode,
      'highFidelityMode': instance.highFidelityMode,
      'loudnessEnhancement': instance.loudnessEnhancement,
    };
