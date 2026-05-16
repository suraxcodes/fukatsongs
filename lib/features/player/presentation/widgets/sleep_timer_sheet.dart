import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../logic/sleep_timer_notifier.dart';

class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sleepTimerProvider);

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF16142E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sleep Timer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (timerState.isActive)
                TextButton(
                  onPressed: () {
                    ref.read(sleepTimerProvider.notifier).cancelTimer();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            timerState.isActive
                ? 'Timer is running: ${timerState.minutesLeft} mins left'
                : 'Select when to stop the music',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
          ),
          SizedBox(height: 24.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              _timerOption(context, ref, 15),
              _timerOption(context, ref, 30),
              _timerOption(context, ref, 45),
              _timerOption(context, ref, 60),
              _timerOption(context, ref, 90),
              _timerOption(context, ref, 120),
            ],
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _timerOption(BuildContext context, WidgetRef ref, int minutes) {
    return InkWell(
      onTap: () {
        ref.read(sleepTimerProvider.notifier).setTimer(minutes);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Music will stop in $minutes minutes'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFBB86FC),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
