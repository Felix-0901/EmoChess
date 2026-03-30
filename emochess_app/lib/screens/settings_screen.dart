import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/title_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// 設定頁面（含個人資料卡片）
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TitleService _titleService = TitleService();

  @override
  void initState() {
    super.initState();
    // 進入頁面時抓取最新資料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
              return;
            }
            context.go('/');
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── 個人資料卡片 ──────────────────
            _ProfileCard(l10n: l10n),

            const SizedBox(height: 24),

            // ─── 設定區塊 ────────────────────
            _SectionTitle(title: l10n.settings),

            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return Column(
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        if (!auth.isLoggedIn) return const SizedBox.shrink();
                        final isZh =
                            context.watch<SettingsProvider>().isChinese;
                        final titlesLabel = isZh ? '稱號' : 'Titles';
                        final equipped = auth.equippedTitle;
                        final equippedText =
                            (equipped == null)
                                ? ''
                                : (isZh
                                    ? (equipped['nameZh'] as String? ?? '')
                                    : (equipped['nameEn'] as String? ?? ''));

                        return _SettingsTile(
                          icon: Icons.emoji_events_rounded,
                          title: titlesLabel,
                          subtitle:
                              equippedText.trim().isNotEmpty
                                  ? equippedText.trim()
                                  : l10n.get('noTitlesYet'),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          onTap: () => _showTitlesSheet(context, l10n),
                        );
                      },
                    ),

                    // 語言切換
                    _SettingsTile(
                      icon: Icons.language,
                      title: l10n.language,
                      subtitle:
                          settings.isEnglish
                              ? l10n.get('english')
                              : l10n.get('traditionalChinese'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          settings.isEnglish
                              ? l10n.get('langShortEn')
                              : l10n.get('langShortZh'),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => settings.toggleLanguage(),
                    ),

                    // 走棋提示
                    _SettingsTile(
                      icon: Icons.lightbulb_outline,
                      title: l10n.showMoveHints,
                      subtitle: l10n.showMoveHintsDesc,
                      trailing: Switch(
                        value: settings.showMoveHints,
                        onChanged: (_) => settings.toggleMoveHints(),
                        activeTrackColor: AppColors.primary,
                      ),
                      onTap: () => settings.toggleMoveHints(),
                    ),

                    // 教學導覽
                    _SettingsTile(
                      icon: Icons.help_outline,
                      title: l10n.tutorial,
                      subtitle: l10n.tutorialDesc,
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                      onTap: () => _showTutorialDialog(context, l10n),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ─── 登出按鈕 ────────────────────
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isLoggedIn) return const SizedBox.shrink();
                return _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: l10n.get('logout'),
                  subtitle: '',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.error,
                    size: 16,
                  ),
                  onTap: () => _showLogoutDialog(context, auth, l10n),
                );
              },
            ),

            const SizedBox(height: 32),

            // ─── 關於 ──────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.clayDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: 16,
              ),
              child: Column(
                children: [
                  const Text('♟️', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    l10n.appName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '${l10n.version} 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider auth,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.get('logout'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Text(
          l10n.get('logoutConfirm'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(l10n.get('logout')),
          ),
        ],
      ),
    );
  }

  void _showTutorialDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.school, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(
              l10n.tutorial,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TutorialStep(text: l10n.tutorialStep1, icon: Icons.emoji_emotions),
            const SizedBox(height: 12),
            _TutorialStep(text: l10n.tutorialStep2, icon: Icons.extension),
            const SizedBox(height: 12),
            _TutorialStep(text: l10n.tutorialStep3, icon: Icons.smart_toy),
            const SizedBox(height: 12),
            _TutorialStep(text: l10n.tutorialStep4, icon: Icons.bar_chart_rounded),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
  }

  Future<void> _showTitlesSheet(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isZh = context.watch<SettingsProvider>().isChinese;
        final titlesLabel = isZh ? '稱號' : 'Titles';
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titlesLabel,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.get('close')),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _titleService.fetchTitles(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = snapshot.data;
                      final titles =
                          (data?['titles'] as List?)
                              ?.whereType<Map>()
                              .map((e) => e.cast<String, dynamic>())
                              .toList() ??
                          const [];

                      if (titles.isEmpty) {
                        return Center(child: Text(l10n.get('noTitlesYet')));
                      }

                      return ListView.builder(
                        itemCount: titles.length,
                        itemBuilder: (context, index) {
                          final t = titles[index];
                          final key = (t['key'] as String?)?.trim() ?? '';
                          final name =
                              isZh
                                  ? (t['nameZh'] as String? ?? '')
                                  : (t['nameEn'] as String? ?? '');
                          final desc =
                              isZh
                                  ? (t['descriptionZh'] as String? ?? '')
                                  : (t['descriptionEn'] as String? ?? '');
                          final equipped = t['equipped'] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: AppTheme.clayDecoration(
                              color: AppColors.surface,
                              borderRadius: 16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.baloo2(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (desc.trim().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          desc,
                                          style: GoogleFonts.comicNeue(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (equipped)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.get('equipped'),
                                      style: GoogleFonts.comicNeue(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                else
                                  TextButton(
                                    onPressed: () async {
                                      if (key.isEmpty) return;
                                      await _titleService.equipTitle(key);
                                      if (!context.mounted) return;
                                      await context
                                          .read<AuthProvider>()
                                          .fetchProfile();
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    },
                                    child: Text(l10n.get('equip')),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── 個人資料卡片 ──────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _ProfileCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.clayDecoration(
            color: AppColors.surface,
            borderRadius: 24,
          ),
          child: Column(
            children: [
              // ─── 頭像 + 名稱 ─────────────
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        auth.displayName.isNotEmpty
                            ? auth.displayName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.baloo2(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final isZh =
                                context.watch<SettingsProvider>().isChinese;
                            final equipped = auth.equippedTitle;
                            final titleText =
                                (equipped == null)
                                    ? ''
                                    : (isZh
                                        ? (equipped['nameZh'] as String? ?? '')
                                        : (equipped['nameEn'] as String? ?? ''));
                            final hasTitle = titleText.trim().isNotEmpty;

                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    auth.displayName,
                                    style: GoogleFonts.baloo2(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasTitle) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      titleText.trim(),
                                      style: GoogleFonts.comicNeue(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        Text(
                          auth.email,
                          style: GoogleFonts.comicNeue(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ─── 等級 + 經驗條 ────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lv.${auth.level}',
                      style: GoogleFonts.baloo2(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${auth.xpInCurrentLevel} / ${auth.xpNeededForNextLevel} XP',
                          style: GoogleFonts.comicNeue(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: auth.xpProgress.clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ─── 戰績統計 ─────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.sports_esports_rounded,
                      value: '${auth.gamesPlayed}',
                      label: l10n.get('gamesPlayed'),
                    ),
                    Container(width: 1, height: 32, color: AppColors.border),
                    _StatItem(
                      icon: Icons.emoji_events_rounded,
                      value: '${auth.gamesWon}',
                      label: l10n.get('wins'),
                    ),
                    Container(width: 1, height: 32, color: AppColors.border),
                    _StatItem(
                      icon: Icons.percent_rounded,
                      value: '${auth.winRate}%',
                      label: l10n.get('winRate'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.baloo2(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.comicNeue(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── 共用元件 ──────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _TutorialStep extends StatelessWidget {
  final String text;
  final IconData icon;

  const _TutorialStep({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
