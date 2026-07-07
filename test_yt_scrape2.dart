import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://www.youtube.com/playlist?list=PLaOVMhTScd6KnBQPRabkHui4iWzzXZQYC';
  final response = await http.get(
    Uri.parse(url),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  );
  final html = response.body;
  final nextDataStart = html.indexOf('var ytInitialData = ');
  final jsonStart = nextDataStart + 'var ytInitialData = '.length;
  final jsonEnd = html.indexOf(';</script>', jsonStart);
  final jsonStr = html.substring(jsonStart, jsonEnd);
  
  File('yt_initial_data.json').writeAsStringSync(jsonStr);
  print('Saved to yt_initial_data.json');
}
