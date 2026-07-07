import 'package:flutter/material.dart';

class ImportProgressWidget extends StatelessWidget {
  final int imported;
  final int total;
  final int skipped;

  const ImportProgressWidget(
      {super.key,
      required this.imported,
      required this.total,
      required this.skipped});

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (imported / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: percent),
        const SizedBox(height: 8),
        Text('Importing $imported / $total'),
        if (skipped > 0) Text('Skipped duplicates: $skipped'),
      ],
    );
  }
}
