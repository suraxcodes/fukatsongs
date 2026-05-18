import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/song.dart';
import 'features/main/presentation/splash_screen.dart';
import 'core/audio/audio_handler.dart';
import 'core/audio/audio_handler_provider.dart';
import 'core/constants/hive_boxes.dart';
import 'features/auth/logic/kill_switch_provider.dart';
import 'features/auth/presentation/banned_screen.dart';

import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Safely try initializing Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase successfully initialized.');
    } catch (e) {
      debugPrint('Firebase not initialized (missing config or offline): $e');
    }

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

class FukatSongsApp extends ConsumerWidget {
  const FukatSongsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBanned = ref.watch(killSwitchProvider);

    // Safely calculate screen size at root level without MediaQuery context
    final physicalSize = ui.PlatformDispatcher.instance.views.first.physicalSize;
    final devicePixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final width = physicalSize.width / (devicePixelRatio > 0 ? devicePixelRatio : 1.0);
    final height = physicalSize.height / (devicePixelRatio > 0 ? devicePixelRatio : 1.0);
    final isDesktop = width > 800;

    return ScreenUtilInit(
      designSize: isDesktop ? Size(width, height) : const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          key: ValueKey(isBanned),
          title: 'fukatSongs',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          home: isBanned ? const BannedScreen() : const SplashScreen(),
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
