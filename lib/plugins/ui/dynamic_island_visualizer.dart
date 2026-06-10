import 'dart:math';
import 'package:flutter/material.dart';

/// Lightweight animated visualizer for Dynamic Island mini-player.
///
/// Usage:
/// ```dart
/// final key = GlobalKey<DynamicIslandVisualizerState>();
/// DynamicIslandVisualizer(key: key, isPlaying: isPlaying);
/// // Then from player state changes:
/// if (isPlaying) key.currentState?.start(); else key.currentState?.stop();
/// ```
class DynamicIslandVisualizer extends StatefulWidget {
  final int barCount;
  final double barWidth;
  final double maxHeight;
  final Color color;
  final bool isPlaying;
  final double spacing;

  const DynamicIslandVisualizer({
    super.key,
    this.barCount = 6,
    this.barWidth = 3.0,
    this.maxHeight = 28.0,
    this.color = Colors.white,
    this.isPlaying = false,
    this.spacing = 4.0,
  });

  @override
  DynamicIslandVisualizerState createState() => DynamicIslandVisualizerState();
}

class DynamicIslandVisualizerState extends State<DynamicIslandVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _phases;
  late final List<double> _speeds;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(() => setState(() {}));

    // Per-bar random phases and speed multipliers for organic movement.
    _phases =
        List.generate(widget.barCount, (_) => _rand.nextDouble() * pi * 2);
    _speeds =
        List.generate(widget.barCount, (_) => 0.8 + _rand.nextDouble() * 0.8);

    if (widget.isPlaying) {
      start();
    }
  }

  @override
  void didUpdateWidget(covariant DynamicIslandVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.barCount != oldWidget.barCount) {
      // regenerate phases/speeds if bar count changed
      _phases.clear();
      _speeds.clear();
      _phases.addAll(
          List.generate(widget.barCount, (_) => _rand.nextDouble() * pi * 2));
      _speeds.addAll(List.generate(
          widget.barCount, (_) => 0.8 + _rand.nextDouble() * 0.8));
    }

    if (widget.isPlaying && !_controller.isAnimating) start();
    if (!widget.isPlaying && _controller.isAnimating) stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void start() {
    if (!_controller.isAnimating) _controller.repeat();
  }

  void stop() {
    if (_controller.isAnimating) {
      _controller.stop();
      // gently settle to idle by forwarding to a small value
      _controller.value = 0.0;
    }
  }

  double _barHeight(int index, double t) {
    // Smooth periodic movement per-bar using sine waves with different speeds/phases.
    final speed = _speeds[index];
    final phase = _phases[index];
    final v = 0.5 * (1 + sin(2 * pi * t * speed + phase));

    // Apply easing to avoid jitter (smoothstep-like)
    final eased = v * v * (3 - 2 * v);

    // Clamp to a subtle range so bars never get huge.
    const min = 0.08; // idle low height fraction
    const max = 0.92; // max relative
    final h = min + (max - min) * eased;
    return h * widget.maxHeight;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxHeight,
      child: CustomPaint(
        painter: _VisualizerPainter(
          barCount: widget.barCount,
          barWidth: widget.barWidth,
          spacing: widget.spacing,
          color: widget.color,
          controllerValue: _controller.value,
          heightCallback: _barHeight,
          isPlaying: _controller.isAnimating,
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final int barCount;
  final double barWidth;
  final double spacing;
  final Color color;
  final double controllerValue;
  final double Function(int index, double t) heightCallback;
  final bool isPlaying;

  _VisualizerPainter({
    required this.barCount,
    required this.barWidth,
    required this.spacing,
    required this.color,
    required this.controllerValue,
    required this.heightCallback,
    required this.isPlaying,
  }) : super(repaint: AlwaysStoppedAnimation(controllerValue));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final totalWidth = barCount * barWidth + (barCount - 1) * spacing;
    final startX = (size.width - totalWidth) / 2;

    for (var i = 0; i < barCount; i++) {
      final x = startX + i * (barWidth + spacing);
      final t = controllerValue;
      final h = isPlaying ? heightCallback(i, t) : widgetIdleHeight(size);
      final y = size.height - h;
      final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, h), const Radius.circular(2));
      canvas.drawRRect(rrect, paint);
    }
  }

  double widgetIdleHeight(Size size) => size.height * 0.12;

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    return oldDelegate.controllerValue != controllerValue ||
        oldDelegate.isPlaying != isPlaying;
  }
}
