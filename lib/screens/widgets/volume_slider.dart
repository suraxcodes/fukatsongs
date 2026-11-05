import 'dart:async';
import 'package:fukatsongs/core/theme/app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';

class VolumeDragController extends StatefulWidget {
  final Widget child;
  const VolumeDragController({super.key, required this.child});

  @override
  _VolumeDragControllerState createState() => _VolumeDragControllerState();
}

class _VolumeDragControllerState extends State<VolumeDragController> {
  static const _voiceChannel = MethodChannel('com.fukatsongs.app/voice_service');

  double _volume = 0.5;
  bool _showVolumeController = false;
  Timer? _hideTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchSystemVolume();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => _fetchSystemVolume(),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSystemVolume() async {
    try {
      final v = await _voiceChannel.invokeMethod<double>('getMediaVolume');
      if (v != null && mounted && (v - _volume).abs() > 0.005) {
        setState(() => _volume = v);
      }
    } catch (_) {}
  }

  Future<void> _setSystemVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    setState(() => _volume = clamped);
    try {
      await _voiceChannel.invokeMethod('setMediaVolume', {'fraction': clamped});
    } catch (_) {}
  }

  void _onDragStart(DragStartDetails details) {
    setState(() => _showVolumeController = true);
    _startHideTimer();
  }

  void _onDragEnd(DragEndDetails details) {
    _startHideTimer();
  }

  void _updateVolume(DragUpdateDetails details) {
    final next = (_volume - details.delta.dy / 200).clamp(0.0, 1.0);
    _setSystemVolume(next);
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showVolumeController = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          setState(() => _showVolumeController = true);
          final next =
              (_volume - (event.scrollDelta.dy / 500)).clamp(0.0, 1.0);
          _setSystemVolume(next);
          _startHideTimer();
        }
      },
      child: GestureDetector(
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _updateVolume,
        onVerticalDragEnd: _onDragEnd,
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: <Widget>[
              widget.child,
              Positioned(
                right: 20.0,
                bottom: 0,
                top: 0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedOpacity(
                    opacity: _showVolumeController ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              (_volume == 0)
                                  ? MingCute.volume_off_fill
                                  : MingCute.volume_fill,
                              color: Default_Theme.primaryColor2,
                            ),
                            RotatedBox(
                              quarterTurns: -1,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  inactiveTrackColor: Default_Theme.primaryColor2
                                      .withValues(alpha: 0.3),
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6.0),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16.0),
                                  trackShape:
                                      const RoundedRectSliderTrackShape(),
                                  trackHeight: 10.0,
                                ),
                                child: Slider(
                                  value: _volume,
                                  onChanged: (value) {
                                    _setSystemVolume(value);
                                    _startHideTimer();
                                  },
                                  onChangeEnd: (value) {
                                    _startHideTimer();
                                  },
                                  min: 0.0,
                                  max: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}