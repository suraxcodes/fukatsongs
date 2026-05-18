import 'dart:async';
import 'dart:isolate';

class AudioDecipherIsolate {
  /// Offloads the YouTube signature decryption array manipulations to a background Isolate
  /// to ensure the main Flutter UI thread is never blocked, keeping scrolling at 120Hz.
  static Future<String> decipherSignature({
    required String encryptedUrl,
    required List<dynamic> transformations,
  }) async {
    // Isolate.run spawns a separate worker thread, executes the closure, and returns the result
    return Isolate.run<String>(() {
      final uri = Uri.parse(encryptedUrl);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      
      // Obtain the original signature parameter from the URL query
      String sig = queryParams['sig'] ?? queryParams['s'] ?? '';
      
      // Perform rolling signature decipher steps (reverses, slices, index swaps)
      for (final step in transformations) {
        if (step is! Map) continue;
        final String action = step['action']?.toString() ?? '';
        final int param = step['param'] as int? ?? 0;
        
        if (action == 'reverse') {
          sig = sig.split('').reversed.join();
        } else if (action == 'slice') {
          if (param >= 0 && param <= sig.length) {
            sig = sig.substring(param);
          }
        } else if (action == 'swap') {
          final list = sig.split('');
          if (list.isNotEmpty) {
            final int index = param % list.length;
            final temp = list[0];
            list[0] = list[index];
            list[index] = temp;
            sig = list.join();
          }
        }
      }

      // Re-attach the decrypted signature as the query signature parameter
      queryParams['sig'] = sig;
      
      // Rebuild the final clean direct stream URL
      return uri.replace(queryParameters: queryParams).toString();
    });
  }
}
