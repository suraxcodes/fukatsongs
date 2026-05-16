import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:fukat_songs/core/audio/audio_handler.dart';
import 'package:fukat_songs/core/audio/audio_handler_provider.dart';

class EqualizerSheet extends ConsumerWidget {
  const EqualizerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider) as MusicAudioHandler;
    final equalizer = handler.equalizer;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0B1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Equalizer',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              StreamBuilder<bool>(
                stream: equalizer.enabledStream,
                builder: (context, snapshot) {
                  final enabled = snapshot.data ?? false;
                  return Switch(
                    value: enabled,
                    onChanged: (val) => equalizer.setEnabled(val),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<AndroidEqualizerParameters>(
            future: equalizer.parameters,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final params = snapshot.data!;
              final bands = params.bands;
              return Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: bands.map((band) => _buildBandSlider(band, params.minDecibels, params.maxDecibels)).toList(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildPresets(bands),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBandSlider(AndroidEqualizerBand band, double min, double max) {
    return Column(
      children: [
        StreamBuilder<double>(
          stream: band.gainStream,
          builder: (context, snapshot) {
            return SizedBox(
              height: 180,
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  min: min,
                  max: max,
                  value: (snapshot.data ?? 0.0).clamp(min, max),
                  onChanged: (val) => band.setGain(val),
                  activeColor: const Color(0xFF6200EE),
                  inactiveColor: Colors.white10,
                ),
              ),
            );
          },
        ),
        Text(
          '${(band.centerFrequency / 1000).round()}Hz',
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildPresets(List<AndroidEqualizerBand> bands) {
    final presets = {
      'Normal': [0.0, 0.0, 0.0, 0.0, 0.0],
      'Pop': [-1.0, 2.0, 5.0, 1.0, -2.0],
      'Rock': [5.0, 3.0, -1.0, 3.0, 5.0],
      'Jazz': [3.0, 1.0, 0.0, 3.0, 5.0],
      'Classical': [5.0, 2.0, -1.0, 1.0, 6.0],
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.entries.map((e) => ActionChip(
        backgroundColor: Colors.white.withOpacity(0.05),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        label: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 12)),
        onPressed: () {
          final values = e.value;
          for (var i = 0; i < bands.length && i < values.length; i++) {
            bands[i].setGain(values[i]);
          }
        },
      )).toList(),
    );
  }
}
