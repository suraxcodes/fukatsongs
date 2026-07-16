import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  const url = 'https://www.youtube.com/playlist?list=PLaOVMhTScd6KnBQPRabkHui4iWzzXZQYC';
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
  if (ytcfgStart == -1) {
    print('Failed to find ytcfg');
    return;
  }
  final jsonStart = ytcfgStart + 'ytcfg.set('.length;
  int openBraces = 0;
  int jsonEnd = -1;
  for (int i = jsonStart; i < html.length; i++) {
    if (html[i] == '{') {
      openBraces++;
    } else if (html[i] == '}') {
      openBraces--;
      if (openBraces == 0) {
        jsonEnd = i + 1;
        break;
      }
    }
  }
  
  final ytcfgJsonStr = html.substring(jsonStart, jsonEnd);
  final ytcfg = jsonDecode(ytcfgJsonStr);
  final contextJson = ytcfg['INNERTUBE_CONTEXT'];
  final apiKey = ytcfg['INNERTUBE_API_KEY'];
  
  final initDataStart = html.indexOf('var ytInitialData = ');
  final initJsonStart = initDataStart + 'var ytInitialData = '.length;
  final initJsonEnd = html.indexOf(';</script>', initJsonStart);
  final data = jsonDecode(html.substring(initJsonStart, initJsonEnd));

  String? findContinuation(dynamic node) {
    if (node is Map) {
      if (node.containsKey('continuationItemRenderer')) {
        final token = node['continuationItemRenderer']?['continuationEndpoint']?['continuationCommand']?['token'];
        if (token != null) return token as String;
      } else if (node.containsKey('continuationItemViewModel')) {
        final token = node['continuationItemViewModel']?['continuationCommand']?['innertubeCommand']?['continuationCommand']?['token'];
        if (token != null) return token as String;
      }
      for (var value in node.values) {
        final token = findContinuation(value);
        if (token != null) return token;
      }
    } else if (node is List) {
      for (var item in node) {
        final token = findContinuation(item);
        if (token != null) return token;
      }
    }
    return null;
  }
  
  String? currentContinuation = findContinuation(data);
  
  if (currentContinuation != null && apiKey != null && contextJson != null) {
    print('Paginating with token $currentContinuation ...');
    final postData = {
      'context': contextJson,
      'continuation': currentContinuation,
    };
    
    try {
      final nextRes = await dio.post(
        'https://www.youtube.com/youtubei/v1/browse?key=$apiKey',
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: jsonEncode(postData),
      );
      final nextData = (nextRes.data is String) ? jsonDecode(nextRes.data) : nextRes.data;
      final nextToken = findContinuation(nextData);
      print('Pagination Success! Next token: $nextToken');
    } catch (e) {
      print('Pagination failed: $e');
    }
  }
}
