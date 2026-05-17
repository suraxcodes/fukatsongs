import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_service/audio_service.dart';
import 'models/song.dart';
import 'features/main/main_screen.dart';
import 'features/main/presentation/splash_screen.dart';
import 'core/audio/audio_handler.dart';
import 'core/audio/audio_handler_provider.dart';
import 'core/constants/hive_boxes.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Hive
    await Hive.initFlutter();
    
    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SongAdapter());
    }

    // Open Core Boxes
    await Future.wait([
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox<Song>(HiveBoxes.songs),
      Hive.openBox(HiveBoxes.likedSongs),
      Hive.openBox<Song>(HiveBoxes.recentSongs),
      Hive.openBox<String>(HiveBoxes.searchCache),
      Hive.openBox(HiveBoxes.queueState),
      Hive.openBox(HiveBoxes.library),
      Hive.openBox(HiveBoxes.playlists),
      Hive.openBox<String>(HiveBoxes.searchHistory),
      Hive.openBox<Song>(HiveBoxes.downloads),
      Hive.openBox(HiveBoxes.auth),
      Hive.openBox<int>(HiveBoxes.playStats),
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
  } catch (e, stackTrace) {
    debugPrint('FATAL STARTUP ERROR: $e');
    debugPrint('STACKTRACE: $stackTrace');
    // Still run the app but show an error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Startup Error: $e\n\nPlease check logs.'),
        ),
      ),
    ));
  }
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
          home: const SplashScreen(),
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
