import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fukat_songs/core/audio/audio_handler_provider.dart';

class BannedScreen extends ConsumerWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 💎 CRITICAL SECURITY GUARD: Instantly stop all background music playback!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(audioHandlerProvider).stop();
      } catch (e) {
        debugPrint('Failed to stop audio on ban: $e');
      }
    });
    return Scaffold(
      backgroundColor: const Color(0xFF090715),
      body: Stack(
        children: [
          // Background Aesthetic glowing spots
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.redAccent.withOpacity(0.08),
                    Colors.redAccent.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.deepPurple.withOpacity(0.08),
                    Colors.deepPurple.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Beautiful glowing shield lock icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withOpacity(0.05),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.1),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gpp_bad_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Headline
                  const Text(
                    'ACCESS REVOKED',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Subtitle description
                  const Text(
                    'This device has been blacklisted from using the fukatSongs service. Private distributions are monitored, and access is controlled by the application administration.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white38,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  // Footer info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 16,
                          color: Colors.white30,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'DEVICE ID FLAGGED',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Colors.white30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
