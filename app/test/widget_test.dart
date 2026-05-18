import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:emochess_app/main.dart';
import 'package:emochess_app/l10n/app_localizations.dart';
import 'package:emochess_app/providers/emotion_provider.dart';
import 'package:emochess_app/providers/game_provider.dart';
import 'package:emochess_app/providers/settings_provider.dart';
import 'package:emochess_app/screens/game_screen.dart';
import 'package:emochess_app/screens/login_screen.dart';
import 'package:emochess_app/screens/splash_screen.dart';
import 'package:emochess_app/widgets/chat_area.dart';

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

  testWidgets('Game screen can disable AI companion chat', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GameProvider()),
          ChangeNotifierProvider(create: (_) => EmotionProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('zh')],
          home: GameScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Play with AI buddy'), findsOneWidget);
    expect(find.byType(ChatArea), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(find.byType(ChatArea), findsNothing);
  });
}
