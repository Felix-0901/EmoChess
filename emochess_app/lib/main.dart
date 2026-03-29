import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'providers/game_provider.dart';
import 'providers/emotion_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/game_history_provider.dart';
import 'providers/game_record_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/emotion_checkin_screen.dart';
import 'screens/game_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/analysis_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/ai_error_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFECFEFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const EmoChessApp());
}

/// EmoChess - Emotion-focused Chess Learning App for ASD Children
class EmoChessApp extends StatelessWidget {
  const EmoChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => EmotionProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => GameHistoryProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => GameRecordProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
      ],
      child: const _EmoChessRouter(),
    );
  }
}

/// Separate StatefulWidget to hold the GoRouter as stable state.
/// This prevents GoRouter from being recreated on every Provider change,
/// which would destroy LoginScreen's local state (like _isRegisterMode).
class _EmoChessRouter extends StatefulWidget {
  const _EmoChessRouter();

  @override
  State<_EmoChessRouter> createState() => _EmoChessRouterState();
}

class _EmoChessRouterState extends State<_EmoChessRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final auth = context.read<AuthProvider>();
        final isOnLogin = state.matchedLocation == '/login';

        if (auth.isLoading) return null;
        if (!auth.isLoggedIn && !isOnLogin) return '/login';
        if (auth.isLoggedIn && isOnLogin) return '/';

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
        GoRoute(
          path: '/emotion-checkin',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const EmotionCheckinScreen(),
            transitionsBuilder: _slideTransition,
          ),
        ),
        GoRoute(
          path: '/game',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const GameScreen(),
            transitionsBuilder: _fadeTransition,
          ),
        ),
        GoRoute(
          path: '/analysis',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AnalysisScreen(),
            transitionsBuilder: _slideUpTransition,
          ),
        ),
        GoRoute(
          path: '/analysis/:id',
          pageBuilder: (context, state) {
            final recordId = state.pathParameters['id'] ?? '';
            return CustomTransitionPage(
              key: state.pageKey,
              child: AnalysisDetailScreen(recordId: recordId),
              transitionsBuilder: _slideUpTransition,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsScreen(),
            transitionsBuilder: _slideTransition,
          ),
        ),
        GoRoute(
          path: '/ai-error',
          pageBuilder: (context, state) {
            final errorMsg =
                state.uri.queryParameters['msg'] ?? 'Unknown AI Error';
            return CustomTransitionPage(
              key: state.pageKey,
              child: AiErrorScreen(
                errorMessage: errorMsg,
                onRetry: () => context.go('/game'),
                onExit: () => context.go('/'),
              ),
              transitionsBuilder: _fadeTransition,
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp.router(
          title: 'EmoChess',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          locale: Locale(settings.locale),
          supportedLocales: const [Locale('en'), Locale('zh')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: _router,
        );
      },
    );
  }
}

// ─── Transition Animations ──────────────────────────

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurveTween(curve: Curves.easeOut).animate(animation),
    child: child,
  );
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(animation),
    child: child,
  );
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOut)).animate(animation),
    child: child,
  );
}
