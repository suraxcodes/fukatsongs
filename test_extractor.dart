import 'dart:convert';
import 'dart:io';

void main() {
  final jsonStr = File('yt_initial_data.json').readAsStringSync();
  final data = jsonDecode(jsonStr);

  List<Map<String, dynamic>> extractVideos(dynamic node) {
    List<Map<String, dynamic>> results = [];
    if (node is Map) {
      if (node.containsKey('playlistVideoRenderer')) {
        final renderer = node['playlistVideoRenderer'];
        final videoId = renderer['videoId'] as String?;
        final titleObj = renderer['title'];
        final vTitle = titleObj?['simpleText'] ?? titleObj?['runs']?[0]?['text'];
        if (videoId != null && vTitle != null) {
          results.add({'videoId': videoId, 'title': vTitle, 'author': ''});
        }
      } else if (node.containsKey('lockupViewModel')) {
        final lockup = node['lockupViewModel'];
        final videoId = lockup['contentId'] as String?;
        final meta = lockup['metadata']?['lockupMetadataViewModel'];
        final vTitle = meta?['title']?['content'] as String?;
        if (videoId != null && vTitle != null) {
          results.add({'videoId': videoId, 'title': vTitle, 'author': ''});
        }
      } else if (node.containsKey('musicResponsiveListItemRenderer')) {
        final renderer = node['musicResponsiveListItemRenderer'];
        final titleObj = renderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0];
        final vTitle = titleObj?['text'] as String?;
        final videoId = renderer['playlistItemData']?['videoId'] as String?;
        if (videoId != null && vTitle != null) {
          results.add({'videoId': videoId, 'title': vTitle, 'author': ''});
        }
      }
      for (var value in node.values) {
        results.addAll(extractVideos(value));
      }
    } else if (node is List) {
      for (var item in node) {
        results.addAll(extractVideos(item));
      }
    }
    return results;
  }

  final allExtracted = extractVideos(data);
  print('Found ${allExtracted.length} videos!');
}
