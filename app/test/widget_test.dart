import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:emochess_app/main.dart';
import 'package:emochess_app/screens/login_screen.dart';
import 'package:emochess_app/screens/splash_screen.dart';

void main() {
  testWidgets('EmoChess app smoke test', (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const EmoChessApp());
    await tester.pump();

    // Verify startup waits on auth restoration before showing login.
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
