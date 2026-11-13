import 'dart:math' as math;

/// Pure accounting, independent of UI/global history. Uses wall-clock time
/// confirmed by forward playback progress; position jumps do not add time.
class PlayAccumulator {
  static const thresholdMs = 60000;
  double listenedMs = 0;
  bool counted = false;
  bool hadSeek = false;
  int? _lastNow;
  int? _lastPosition;

  void gap() {
    _lastNow = null;
    _lastPosition = null;
  }

  void seeked() {
    hadSeek = true;
    gap();
  }

  bool sample({
    required int nowMs,
    required int positionMs,
    required bool playing,
    double speed = 1,
  }) {
    if (!playing || speed <= 0 || !speed.isFinite) {
      gap();
      return false;
    }
    final previousTime = _lastNow;
    final previousPosition = _lastPosition;
    if (previousTime == null || previousPosition == null) {
      _lastNow = nowMs;
      _lastPosition = positionMs;
      return false;
    }
    final wall = nowMs - previousTime;
    final progress = positionMs - previousPosition;
    if (progress == 0 && wall <= 2000) return false;
    _lastNow = nowMs;
    _lastPosition = positionMs;
    if (wall <= 0 ||
        wall > 2000 ||
        progress <= 0 ||
        progress > wall * speed + 1000)
      return false;
    listenedMs += math.min(wall.toDouble(), progress / speed);
    if (!counted && listenedMs >= thresholdMs) {
      counted = true;
      return true;
    }
    return false;
  }

  bool completeShort({required int durationMs, double speed = 1}) {
    if (counted ||
        hadSeek ||
        durationMs <= 0 ||
        durationMs >= thresholdMs ||
        speed <= 0 ||
        !speed.isFinite)
      return false;
    // Natural completion must be supported by listening evidence, not a seek.
    final minimum = math.max(1.0, durationMs / speed - 1500);
    if (listenedMs < minimum) return false;
    counted = true;
    return true;
  }
}
