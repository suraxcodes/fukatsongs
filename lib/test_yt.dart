import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

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
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

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
      status = 'Searching for a "Crack" in the Block...';
    });

    const videoId = '7wtfhZwyrcc'; // Believer

    for (var instance in diamondKeys) {
      try {
        setState(() => status = 'Probing Tunnel: $instance');
        print('--- PROBING: $instance');
        
        final response = await dio.get('$instance/api/v1/videos/$videoId');
        
        // Deep Logging
        print('--- STATUS: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          var data = response.data;
          if (data is String) {
            data = jsonDecode(data);
          }
          
          if (data['adaptiveFormats'] == null) {
            print('--- FAIL: No adaptive formats found on $instance');
            continue;
          }

          final formats = data['adaptiveFormats'] as List;
          final audioStream = formats.firstWhere(
            (f) => f['type'].toString().contains('audio'),
            orElse: () => null,
          );
          
          if (audioStream == null) {
            print('--- FAIL: No audio-only stream found on $instance');
            continue;
          }
          
          final streamUrl = audioStream['url'];
          print('--- WINNER! Stream URL: $streamUrl');
          
          setState(() => status = 'SUCCESS! Tunnel Cracked.\nLoading Sound...');
          
          await player.setUrl(streamUrl);
          player.play();
          
          setState(() {
            status = 'PLAYING! 🔊\nListening via $instance';
            isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('--- PROBE FAILED: $instance | Error: $e');
        continue;
      }
    }

    // 3. THE MAGIC SWITCH (Saavn Matching)
    setState(() => status = 'YouTube blocked. Activating Magic Switch...');
    try {
      print('--- MAGIC SWITCH: Searching Saavn for match...');
      // Use the verified working Saavn API from your main app
      final saavnResponse = await dio.get('https://jiosaavn-api-sigma-sandy.vercel.app/search/songs', queryParameters: {'query': 'Believer'});
      
      var data = saavnResponse.data;
      if (data is String) {
        data = jsonDecode(data);
      }
      
      if (data['status'] == 'SUCCESS') {
        final List songList = data['data'] is List ? data['data'] : (data['data']['results'] ?? []);
        final song = songList[0];
        final List downloadUrls = song['downloadUrl'];
        final streamUrl = downloadUrls.last['link'];
        
        setState(() => status = 'MAGIC SWITCH ACTIVE! 🪄\nFound match on Saavn. Loading...');
        
        await player.setUrl(streamUrl);
        player.play();
        
        setState(() {
          status = 'PLAYING! 🔊\nListening via Magic Switch (Saavn Engine)';
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('--- MAGIC SWITCH FAILED: $e');
    }

    setState(() {
      status = 'TOTAL BLOCK. ❌\nAll YouTube tunnels and the Saavn Switch failed.';
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
