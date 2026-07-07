import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  final url = 'https://www.youtube.com/playlist?list=PLaOVMhTScd6KnBQPRabkHui4iWzzXZQYC';
  final dio = Dio();
  
  final response = await dio.get(
    url,
    options: Options(
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    ),
  );
  
  final html = response.data as String;
  
  final ytcfgStart = html.indexOf('ytcfg.set({');
  if (ytcfgStart != -1) {
    final jsonStart = ytcfgStart + 'ytcfg.set('.length;
    // Find the matching closing parenthesis for ytcfg.set(...)
    int openBraces = 0;
    int jsonEnd = -1;
    for (int i = jsonStart; i < html.length; i++) {
      if (html[i] == '{') openBraces++;
      else if (html[i] == '}') {
        openBraces--;
        if (openBraces == 0) {
          jsonEnd = i + 1;
          break;
        }
      }
    }
    
    if (jsonEnd != -1) {
      final ytcfgJsonStr = html.substring(jsonStart, jsonEnd);
      final ytcfg = jsonDecode(ytcfgJsonStr);
      final contextJson = ytcfg['INNERTUBE_CONTEXT'];
      final apiKey = ytcfg['INNERTUBE_API_KEY'];
      
      print('API Key: $apiKey');
      print('Context length: ${jsonEncode(contextJson).length}');
    }
  }
}
