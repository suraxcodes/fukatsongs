import 'package:flutter/material.dart';
import 'package:fukatsongs/core/models/exported.dart' hide MediaItem;
import 'package:fukatsongs/services/meta_resolver/cross_plugin_resolver.dart';
import 'package:fukatsongs/services/plugin/plugin_service.dart';
import 'package:fukatsongs/main.dart'; // To access bloomeePlayerCubit
import 'package:fukatsongs/core/di/service_locator.dart';

class ProviderTestScreen extends StatefulWidget {
  const ProviderTestScreen({Key? key}) : super(key: key);

  @override
  State<ProviderTestScreen> createState() => _ProviderTestScreenState();
}

class _ProviderTestScreenState extends State<ProviderTestScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  List<Track> _searchResults = [];
  bool _isLoading = false;

  Future<void> _testSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pluginService = sl<PluginService>();
      final resolver = CrossPluginResolver(pluginService: pluginService);
      
      // We test searching on available plugins
      final results = await resolver.searchTracks(query);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _testPlay(Track track) {
    // Convert Track to MediaItem and play
    bloomeePlayerCubit.bloomeePlayer.playTrack(track);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Attempting to play: ${track.title}")));
  }

  void _testRawUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Create a dummy track with the raw URL to force the player to play it
    final dummyTrack = Track(
      id: 'test_url_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Raw URL Test',
      artists: [ArtistSummary(id: 'dev', name: 'Developer Test')],
      thumbnail: const Artwork(url: '', layout: ImageLayout.square),
      isExplicit: false,
    );

    // This tells the player engine to play the URL directly
    bloomeePlayerCubit.bloomeePlayer.playTrack(dummyTrack);
    
    // We force the underlying engine to load the raw URL because the track id won't resolve
    bloomeePlayerCubit.bloomeePlayer.engine.play(MediaSource.network(url));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Playing RAW stream URL...")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Plugin Test")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: "Enter Song Name",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _testSearch,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _testSearch(_searchController.text),
                )
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: "Enter Raw Audio URL (e.g. .mp3, .m4a)",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _testRawUrl(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Play URL"),
                  onPressed: _testRawUrl,
                )
              ],
            ),
          ),
          const Divider(),
          if (_isLoading) const CircularProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final track = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.music_note),
                  title: Text(track.title),
                  subtitle: Text(track.artists.map((e) => e.name).join(", ")),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _testPlay(track),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
