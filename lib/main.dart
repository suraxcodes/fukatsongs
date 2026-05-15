import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_service/audio_service.dart';
import 'models/song.dart';
import 'features/search/presentation/search_screen.dart';
import 'core/audio/audio_handler.dart';
import 'core/audio/audio_handler_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(SongImplAdapter());

  // Open Core Boxes
  await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox<Song>('songs'),
    Hive.openBox<Song>('liked_songs'),
    Hive.openBox<Song>('recent_songs'),
    Hive.openBox<String>('search_cache'),
    Hive.openBox('queue_state'),
  ]);

  // Initialize Audio Service
  final audioHandler = await AudioService.init(
    builder: () => MusicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.fukatsongs.app.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const FukatSongsApp(),
    ),
  );
}

class FukatSongsApp extends StatelessWidget {
  const FukatSongsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'fukatSongs',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          home: const SearchScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0B1F), // Deep Midnight
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6200EE), // Electric Indigo
        brightness: Brightness.dark,
        surface: const Color(0xFF16142E),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
