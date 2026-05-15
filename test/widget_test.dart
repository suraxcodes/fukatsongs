import 'package:flutter_test/flutter_test.dart';
import 'package:fukat_songs/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FukatSongsApp());
    
    // Verify foundation is ready
    expect(find.text('Search songs, artists...'), findsOneWidget);
  });
}
