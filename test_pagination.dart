import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  const url = 'https://www.youtube.com/playlist?list=PLaOVMhTScd6KnBQPRabkHui4iWzzXZQYC';
  final dio = Dio();
  
  print('Fetching HTML...');
  final response = await dio.get(
    url,
    options: Options(
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    ),
  );
  
  final html = response.data as String;
  
  final keyRegex = RegExp(r'"INNERTUBE_API_KEY"\s*:\s*"([^"]+)"');
  final keyMatch = keyRegex.firstMatch(html);
  final apiKey = keyMatch?.group(1);
  
  final clientRegex = RegExp(r'"INNERTUBE_CONTEXT"\s*:\s*(\{.*?\})');
  final clientMatch = clientRegex.firstMatch(html);
  final clientContext = clientMatch?.group(1);
  
  final nextDataStart = html.indexOf('var ytInitialData = ');
  final jsonStart = nextDataStart + 'var ytInitialData = '.length;
  final jsonEnd = html.indexOf(';</script>', jsonStart);
  final jsonStr = html.substring(jsonStart, jsonEnd);
  
  final data = jsonDecode(jsonStr);
  
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
  print('API Key: $apiKey');
  print('Continuation: $currentContinuation');
  
  if (currentContinuation != null && apiKey != null && clientContext != null) {
    print('Paginating...');
    final contextJson = jsonDecode(clientContext);
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
      print('Pagination Success! Payload size: ${nextRes.data.toString().length}');
    } catch (e) {
      print('Pagination failed: $e');
    }
  } else {
    print('Could not paginate: missing key, context, or continuation token.');
  }
}
