import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 15,
    this.height = 40.0,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _baseHeights = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    for (int i = 0; i < widget.barCount; i++) {
      _baseHeights.add(_random.nextDouble() * 0.7 + 0.3);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      // Gently return to resting height
      return RepaintBoundary(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(
            widget.barCount,
            (index) => Container(
              width: 3.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: BoxDecoration(
                color: const Color(0xFFBB86FC).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              widget.barCount,
              (index) {
                // Generate a smooth staggered wave pattern based on index and controller progress
                final double phase = (index / widget.barCount) * 2 * pi;
                final double rawValue = sin(_controller.value * 2 * pi + phase);
                final double normalized = (rawValue + 1.0) / 2.0; // 0.0 to 1.0
                
                // Add minor random fluctuation to make it feel natural
                final double noise = sin(_controller.value * 4 * pi * _baseHeights[index]) * 0.1;
                final double finalHeight = ((normalized * _baseHeights[index]) + noise).clamp(0.15, 1.0) * widget.height.h;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: 3.w,
                  height: finalHeight,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7B2FF7),
                        const Color(0xFFBB86FC),
                        const Color(0xFFE2B0FF).withOpacity(0.9),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(2.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBB86FC).withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
