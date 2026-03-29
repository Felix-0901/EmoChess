import 'package:flutter_test/flutter_test.dart';
import 'package:emochess_app/main.dart';

void main() {
  testWidgets('EmoChess app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EmoChessApp());

    // Verify the app title is displayed
    expect(find.text('EmoChess'), findsWidgets);
  });
}
