import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../logic/settings_notifier.dart';
import '../../player/logic/sleep_timer_notifier.dart';

import '../../player/presentation/widgets/equalizer_sheet.dart';
import '../../player/presentation/widgets/sleep_timer_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Audio Quality'),
          _buildQualityTile(
            context,
            ref,
            title: 'Streaming Quality',
            subtitle: 'Choose your streaming bitrate',
            value: settings.streamingQuality,
            onChanged: (val) => ref.read(settingsNotifierProvider.notifier).updateStreamingQuality(val!),
          ),
          _buildQualityTile(
            context,
            ref,
            title: 'Download Quality',
            subtitle: 'Choose your download bitrate',
            value: settings.downloadQuality,
            onChanged: (val) => ref.read(settingsNotifierProvider.notifier).updateDownloadQuality(val!),
          ),
          const Divider(color: Colors.white10),
          _buildSectionHeader(context, 'Sound'),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Equalizer'),
            subtitle: const Text('Adjust audio frequencies and presets'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const EqualizerSheet(),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final sleepTimer = ref.watch(sleepTimerProvider);
              return ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Sleep Timer'),
                subtitle: Text(
                  sleepTimer.isActive 
                      ? 'Ends in ${sleepTimer.minutesLeft} minutes' 
                      : 'Automatically stop playback',
                ),
                trailing: sleepTimer.isActive 
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                        onPressed: () => ref.read(sleepTimerProvider.notifier).cancelTimer(),
                      )
                    : const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const SleepTimerSheet(),
                  );
                },
              );
            },
          ),
          const Divider(color: Colors.white10),
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Force dark theme'),
            value: settings.isDarkMode,
            onChanged: (val) => ref.read(settingsNotifierProvider.notifier).toggleDarkMode(val),
          ),
          const Divider(color: Colors.white10),
          _buildSectionHeader(context, 'Playback'),
          SwitchListTile(
            title: const Text('Autoplay'),
            subtitle: const Text('Keep the music going with similar songs'),
            value: settings.isAutoplayEnabled,
            onChanged: (val) => ref.read(settingsNotifierProvider.notifier).toggleAutoplay(val),
          ),
          SwitchListTile(
            title: const Text('Gapless Playback'),
            subtitle: const Text('Remove silences between songs'),
            value: settings.isGaplessPlayback,
            onChanged: (val) => ref.read(settingsNotifierProvider.notifier).toggleGapless(val),
          ),
          const Divider(color: Colors.white10),
          _buildSectionHeader(context, 'Storage'),
          ListTile(
            leading: const Icon(Icons.cleaning_services_rounded),
            title: const Text('Clear Cache'),
            subtitle: const Text('Clear search history and image thumbnails'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF16142E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Clear Cache?'),
                  content: const Text('This will remove your search history and cached images. Downloads will not be affected.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await DefaultCacheManager().emptyCache();
                await Hive.box<String>('search_cache').clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared successfully!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFFBB86FC),
                    ),
                  );
                }
              }
            },
          ),
          const Divider(color: Colors.white10),
          _buildSectionHeader(context, 'About'),
          const ListTile(
            title: Text('Version'),
            trailing: Text('1.0.0 (v2.0 Beta)', style: TextStyle(color: Colors.white54)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Developer'),
            subtitle: const Text('Suraj Gawas'),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Contact'),
            subtitle: const Text('gawassuraj090@gmail.com'),
            onTap: () => launchUrl(Uri.parse('mailto:gawassuraj090@gmail.com')),
          ),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('GitHub'),
            subtitle: const Text('https://github.com/suraxcodes'),
            onTap: () => launchUrl(Uri.parse('https://github.com/suraxcodes'), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildQualityTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF16142E),
        underline: const SizedBox(),
        onChanged: onChanged,
        items: const [
          DropdownMenuItem(value: '96', child: Text('Low (96kbps)')),
          DropdownMenuItem(value: '160', child: Text('Medium (160kbps)')),
          DropdownMenuItem(value: '320', child: Text('High (320kbps)')),
        ],
      ),
    );
  }
}
