import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/audio_handler_provider.dart';

class SleepTimerState {
  final int minutesLeft;
  final bool isActive;

  SleepTimerState({this.minutesLeft = 0, this.isActive = false});

  SleepTimerState copyWith({int? minutesLeft, bool? isActive}) {
    return SleepTimerState(
      minutesLeft: minutesLeft ?? this.minutesLeft,
      isActive: isActive ?? this.isActive,
    );
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  final Ref ref;
  Timer? _timer;

  SleepTimerNotifier(this.ref) : super(SleepTimerState());

  void setTimer(int minutes) {
    _timer?.cancel();
    if (minutes <= 0) {
      state = SleepTimerState();
      return;
    }

    state = SleepTimerState(minutesLeft: minutes, isActive: true);
    
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (state.minutesLeft <= 1) {
        _timer?.cancel();
        state = SleepTimerState();
        _stopPlayback();
      } else {
        state = state.copyWith(minutesLeft: state.minutesLeft - 1);
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    state = SleepTimerState();
  }

  void _stopPlayback() {
    final handler = ref.read(audioHandlerProvider);
    handler.pause();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sleepTimerProvider = StateNotifierProvider<SleepTimerNotifier, SleepTimerState>((ref) {
  return SleepTimerNotifier(ref);
});
