import 'package:fukatsongs/blocs/media_player/bloomee_player_cubit.dart';
import 'package:fukatsongs/core/di/service_locator.dart';
import 'package:fukatsongs/core/theme/app_theme.dart';
import 'package:fukatsongs/screens/screen/home_views/setting_views/setting_shared_widgets.dart';
import 'package:fukatsongs/screens/widgets/voice_model_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

/// Settings → Voice Commands.
///
/// Everything hands-free lives here:
///  - ON/OFF switch (downloads the ~39 MB model the first time),
///  - live state (listening / idle / needs download),
///  - the full phrase reference, grouped, read straight from the Vosk
///    `_grammar` via [VoiceCommandService.commandGroups],
///  - what was recognised last,
///  - a manual "listen now" trigger.
class VoiceCommandSettings extends StatefulWidget {
  const VoiceCommandSettings({super.key});

  @override
  State<VoiceCommandSettings> createState() => _VoiceCommandSettingsState();
}

class _VoiceCommandSettingsState extends State<VoiceCommandSettings> {
  /// Mirrors `voiceCommandService.isModelReady()` so the "Voice model" row can
  /// say "Downloaded" / "Not downloaded" without blocking the build.
  bool? _modelReady;

  @override
  void initState() {
    super.initState();
    _refreshModelState();
  }

  Future<void> _refreshModelState() async {
    final ready =
        await ServiceLocator.voiceCommandService.isModelReady();
    if (mounted) setState(() => _modelReady = ready);
  }

  @override
  Widget build(BuildContext context) {
    final service = ServiceLocator.voiceCommandService;
    final groups = service.commandGroups;

    return Scaffold(
      backgroundColor: Default_Theme.themeColor,
      appBar: AppBar(
        backgroundColor: Default_Theme.themeColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Center(
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Default_Theme.primaryColor1,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Voice Commands',
          style: TextStyle(
            color: Default_Theme.primaryColor1,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ── Battery tip (same text as the download box) ───────────────
          const _BatteryTipCard(),
          const SizedBox(height: 20),

          // ── Hands-free master switch ──────────────────────────────────
          const SettingSectionHeader(label: 'Hands-free'),
          SettingCard(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: service.isEnabled,
                builder: (context, enabled, _) => SettingToggleTile(
                  icon: MingCute.mic_fill,
                  title: 'Hands-free riding mode',
                  subtitle: enabled
                      ? 'ON — listening in the background'
                      : 'Off — tap to enable',
                  value: enabled,
                  onChanged: (value) => _toggle(context, value),
                ),
              ),
              const SettingDivider(),
              ValueListenableBuilder<String>(
                valueListenable: service.lastCommand,
                builder: (context, last, _) => SettingInfoText(
                  text: last.isEmpty
                      ? 'Nothing recognised yet.'
                      : 'Last recognised: "$last"',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Model status ──────────────────────────────────────────────
          const SettingSectionHeader(label: 'Offline model'),
          SettingCard(
            children: [
              SettingNavTile(
                icon: MingCute.download_2_line,
                title: 'Voice model',
                subtitle: _modelReady == null
                    ? 'Checking…'
                    : _modelReady!
                        ? 'Downloaded · ~39 MB offline model ready'
                        : 'Not downloaded · tap to download (~39 MB)',
                onTap: () async {
                  await showVoiceModelDownloadDialog(context);
                  await _refreshModelState();
                },
              ),
              const SettingDivider(),
              SettingNavTile(
                icon: MingCute.list_check_3_line,
                title: '${service.commandCount} voice commands',
                subtitle: 'See every phrase the app understands.',
                onTap: () => showVoiceCommandsDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Full phrase reference ─────────────────────────────────────
          const SettingSectionHeader(label: 'What you can say'),
          SettingCard(
            children: [
              for (final entry in groups.entries) ...[
                _CommandGroupTile(
                  label: entry.key,
                  phrases: entry.value,
                ),
                if (entry.key != groups.keys.last) const SettingDivider(),
              ],
            ],
          ),

          const SizedBox(height: 20),
          SettingInfoText(
            text: 'Speak one phrase at a time and pause between them — '
                'commands need a short silence to be confirmed. '
                'Say "stop listening" to turn hands-free off by voice.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _toggle(BuildContext context, bool value) async {
    final cubit = context.read<BloomeePlayerCubit>();

    // Turning ON for the first time needs the model on disk. Show the
    // download/progress box; it returns true if the model was already there.
    if (value) {
      final ready = await showVoiceModelDownloadDialog(context);
      if (!ready) return;
      if (!context.mounted) return;
      await _refreshModelState();
    }

    await ServiceLocator.voiceCommandService.toggle(
      on: value,
      cubit: cubit,
      context: context,
    );

    // The service owns the real ON/OFF state via isEnabled; nothing to
    // setState() here, but refresh the model row in case we just downloaded.
    await _refreshModelState();
  }
}

/// One row: category label + its phrases as chips.
class _CommandGroupTile extends StatelessWidget {
  const _CommandGroupTile({required this.label, required this.phrases});

  final String label;
  final List<String> phrases;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SettingIconBox(icon: MingCute.mic_line),
              const SizedBox(width: 14),
              Text(
                label,
                style: Default_Theme.secondoryTextStyleMedium.copyWith(
                  color: Default_Theme.primaryColor2,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${phrases.length}',
                style: Default_Theme.secondoryTextStyle.copyWith(
                  color: Default_Theme.primaryColor2.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            // Align chips under the text, not under the icon.
            padding: const EdgeInsets.only(left: 54),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: phrases
                  .map(
                    (phrase) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Default_Theme.primaryColor2
                            .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Default_Theme.primaryColor2
                              .withValues(alpha: 0.07),
                        ),
                      ),
                      child: Text(
                        '"$phrase"',
                        style: Default_Theme.secondoryTextStyle.copyWith(
                          color: Default_Theme.primaryColor2
                              .withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static hint: without switching battery optimisation off, Android (and
/// especially MIUI / HyperOS) suspends the hands-free mic service.
///
/// Text-only on purpose — no permission request, no plugin call.
class _BatteryTipCard extends StatelessWidget {
  const _BatteryTipCard();

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFFFB74D);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: amber.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.battery_alert_rounded, size: 17, color: amber),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep hands-free alive',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: amber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Long-press the app icon → App info → Battery → '
                  'set No restrictions. Otherwise Android stops listening '
                  'after a while.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: Default_Theme.primaryColor1.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}