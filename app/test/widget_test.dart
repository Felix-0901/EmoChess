import 'package:flutter_test/flutter_test.dart';
import 'package:emochess_app/main.dart';
import 'package:emochess_app/screens/login_screen.dart';

void main() {
  testWidgets('EmoChess app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EmoChessApp());
    await tester.pump(const Duration(milliseconds: 200));

    // Verify initial screen renders
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
