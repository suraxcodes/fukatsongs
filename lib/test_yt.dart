import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: YTTestScreen(),
  ));
}

class YTTestScreen extends StatefulWidget {
  const YTTestScreen({super.key});

  @override
  State<YTTestScreen> createState() => _YTTestScreenState();
}

class _YTTestScreenState extends State<YTTestScreen> {
  final player = AudioPlayer();
  final dio = Dio();
  String status = 'Ready to test';
  bool isLoading = false;

  final List<String> diamondKeys = [
    'https://inv.vern.cc',
    'https://invidious.sethforprivacy.com',
    'https://invidious.projectsegfau.lt',
    'https://yewtu.be',
    'https://inv.nadeko.net',
  ];

  Future<void> startTest() async {
    setState(() {
      isLoading = true;
      status = 'Opening the Diamond Key Tunnel (Invidious)...';
    });

    const videoId = '7wtfhZwyrcc'; // Believer

    for (var instance in diamondKeys) {
      try {
        setState(() => status = 'Trying Diamond Key: $instance');
        print('--- Testing Diamond Key: $instance');
        
        final response = await dio.get('$instance/api/v1/videos/$videoId');
        
        if (response.statusCode == 200) {
          final formats = response.data['adaptiveFormats'] as List;
          // Look for audio-only streams
          final audioStream = formats.firstWhere(
            (f) => f['type'].toString().contains('audio'),
            orElse: () => formats.first,
          );
          
          final streamUrl = audioStream['url'];
          
          setState(() => status = 'SUCCESS! Diamond Key Active.\nPlaying from: $instance');
          
          await player.setUrl(streamUrl);
          player.play();
          
          setState(() {
            status = 'PLAYING! 🔊\nListening via Invidious ($instance)';
            isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('--- Diamond Key $instance failed: $e');
        continue;
      }
    }

    setState(() {
      status = 'ALL TUNNELS FAILED. ❌\nThis usually means your internet is blocking these proxy servers.';
      isLoading = false;
    });
  }

  Future<void> startSaavnTest() async {
    setState(() {
      isLoading = true;
      status = 'Testing Saavn Lifeboat...';
    });

    try {
      // Search for "Believer" on Saavn
      final response = await dio.get('https://saavn.me/api/search/songs', queryParameters: {'query': 'Believer'});
      
      if (response.data['status'] == 'SUCCESS') {
        final song = response.data['data'][0];
        final streamUrl = song['downloadUrl'].last['link'];
        
        setState(() => status = 'SUCCESS! Saavn is working.\nPlaying: ${song['name']}');
        
        await player.setUrl(streamUrl);
        player.play();
        
        setState(() {
          status = 'PLAYING! 🔊\nListening via Saavn Lifeboat';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        status = 'SAAVN ALSO FAILED. ❌\nThis means your Emulator has a general internet problem.';
        isLoading = false;
      });
      print('Saavn Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1F),
      appBar: AppBar(
        title: const Text('Playback Diagnostic'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLoading ? Icons.search : Icons.music_note_rounded,
                size: 80,
                color: Colors.purpleAccent,
              ),
              const SizedBox(height: 30),
              Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 40),
              if (!isLoading) ...[
                ElevatedButton(
                  onPressed: startTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(250, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Test YouTube (Red Key)', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: startSaavnTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(250, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Test Saavn (Lifeboat)', style: TextStyle(color: Colors.white)),
                ),
              ] else
                const CircularProgressIndicator(color: Colors.purpleAccent),
            ],
          ),
        ),
      ),
    );
  }
}
