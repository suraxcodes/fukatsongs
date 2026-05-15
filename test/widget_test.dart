import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fukat_songs/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:audio_service/audio_service.dart';
import 'package:fukat_songs/core/audio/audio_handler_provider.dart';
import 'package:fukat_songs/core/audio/audio_handler.dart';

class MockAudioHandler extends MusicAudioHandler {}

void main() {
  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox<String>('search_cache');
    await Hive.openBox('queue_state');
  });

  testWidgets('Smoke test', (WidgetTester tester) async {
    final mockHandler = MockAudioHandler();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioHandlerProvider.overrideWithValue(mockHandler),
        ],
        child: const FukatSongsApp(),
      ),
    );
    
    // Allow for ScreenUtil and initial load
    await tester.pumpAndSettle();
    
    // Verify foundation is ready
    expect(find.byType(TextField), findsOneWidget);
  });
}
