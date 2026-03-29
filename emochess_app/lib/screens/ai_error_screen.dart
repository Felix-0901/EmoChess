import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AiErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final String? errorMessage;

  const AiErrorScreen({
    super.key,
    required this.onRetry,
    required this.onExit,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Add localized strings for error screen if not present.
    // For now using hardcoded Chinese/English fallback or generic keys.
    // Ideally, add keys to AppLocalizations and regen.
    // Assuming we want to move fast, I'll use hardcoded for now or simple "Error"

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 24),
              Text(
                'AI 連線中斷\n(AI Connection Lost)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage ??
                    '無法連接到 AI 服務，請檢查網路或是稍後再試。\n(Unable to connect to AI service. Please check your internet or try again later.)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              // Only one action: return home
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onExit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('回主選單 (Menu)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
