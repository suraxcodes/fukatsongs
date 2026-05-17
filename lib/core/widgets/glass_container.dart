import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fukat_songs/features/settings/logic/settings_notifier.dart';

class GlassContainer extends ConsumerWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.05,
    this.borderRadius = 20,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowPerf = ref.watch(settingsNotifierProvider.select((s) => s.lowPerformanceMode));

    if (lowPerf) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A33).withOpacity(0.9),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: child,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
