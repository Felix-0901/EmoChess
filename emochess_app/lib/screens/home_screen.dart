import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Home screen with friendly welcome message
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo / Mascot
              Container(
                width: 160,
                height: 160,
                decoration: AppTheme.clayDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: 80,
                ),
                child: Center(
                  child: Icon(
                    Icons.castle_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n.appName,
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                l10n.appTagline,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  l10n.appDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

              const Spacer(),

              // Play button
              _MenuButton(
                label: l10n.playChess,
                icon: Icons.play_arrow_rounded,
                color: AppColors.primary,
                onTap: () => context.go('/emotion-checkin'),
              ),

              const SizedBox(height: 16),

              // Emotion analysis button
              _MenuButton(
                label: l10n.get('emotionAnalysis'),
                icon: Icons.analytics_outlined,
                color: AppColors.success,
                onTap: () => context.go('/analysis'),
              ),

              const SizedBox(height: 16),

              // Settings button
              _MenuButton(
                label: l10n.settings,
                icon: Icons.settings_outlined,
                color: AppColors.textSecondary,
                isOutlined: true,
                onTap: () => context.go('/settings'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isOutlined;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    this.isOutlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: isOutlined
            ? BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color, width: 3),
              )
            : AppTheme.clayDecoration(color: color, borderRadius: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isOutlined ? color : Colors.white, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isOutlined ? color : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
