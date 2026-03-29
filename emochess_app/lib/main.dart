import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'config/app_config.dart';
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

  await AppConfig.init();

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
          pageBuilder: (context, state) => _pageWithDefaultTransition(
            key: state.pageKey,
            child: const LoginScreen(),
          ),
        ),
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => _pageWithDefaultTransition(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/emotion-checkin',
          pageBuilder: (context, state) => _pageWithDefaultTransition(
            key: state.pageKey,
            child: const EmotionCheckinScreen(),
          ),
        ),
        GoRoute(
          path: '/game',
          pageBuilder: (context, state) => _pageWithDefaultTransition(
            key: state.pageKey,
            child: const GameScreen(),
          ),
        ),
        GoRoute(
          path: '/analysis',
          pageBuilder: (context, state) => _pageWithDefaultTransition(
            key: state.pageKey,
            child: const AnalysisScreen(),
          ),
        ),
        GoRoute(
          path: '/analysis/:id',
          pageBuilder: (context, state) {
            final recordId = state.pathParameters['id'] ?? '';
            return _pageWithDefaultTransition(
              key: state.pageKey,
              child: AnalysisDetailScreen(recordId: recordId),
            );
          },
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _pageWithDefaultTransition(
            key: state.pageKey,
            child: const SettingsScreen(),
          ),
        ),
        GoRoute(
          path: '/ai-error',
          pageBuilder: (context, state) {
            final errorMsg =
                state.uri.queryParameters['msg'] ?? 'Unknown AI Error';
            return _pageWithDefaultTransition(
              key: state.pageKey,
              child: AiErrorScreen(
                errorMessage: errorMsg,
                onRetry: () => context.go('/game'),
                onExit: () => context.go('/'),
              ),
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

CustomTransitionPage<void> _pageWithDefaultTransition({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: _defaultTransition,
  );
}

Widget _defaultTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  if (disableAnimations) return child;

  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.06, 0.0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
