import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../logic/settings_notifier.dart';
import '../../player/presentation/widgets/equalizer_sheet.dart';

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
          const Divider(color: Colors.white10),
          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Force dark theme'),
            value: settings.isDarkMode,
            onChanged: (val) => ref.read(settingsNotifierProvider.notifier).toggleDarkMode(val),
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
