import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart' show kMockMode, kGeminiApiKey;
import '../../core/theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _isDarkMode;
  late bool _notificationsEnabled;
  late bool _locationTrackingEnabled;

  @override
  void initState() {
    super.initState();
    _isDarkMode = false;
    _notificationsEnabled = true;
    _locationTrackingEnabled = true;
  }

  void _logout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('登出'),
            content: const Text('確定要登出嗎？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  if (!kMockMode) {
                    await Supabase.instance.client.auth.signOut();
                  }
                  if (!mounted) return;
                  context.go('/auth');
                },
                child: Text(
                  '登出',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('更改密碼'),
            content: TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '請輸入您的郵箱',
                hintText: '將寄送密碼重設信到此郵箱',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  if (emailController.text.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('請輸入郵箱')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await Supabase.instance.client.auth.resetPasswordForEmail(
                      emailController.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('密碼重設信已寄出，請查看收件匣'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('發送失敗: $e')));
                    }
                  }
                },
                child: const Text('發送重設信'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('設定'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            // 用戶資料卡片
            _ProfileCard(colorScheme: cs),
            const SizedBox(height: AppSpacing.lg),

            // 顯示設定
            _SettingsGroup(
              title: '顯示',
              children: [
                _SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: Colors.indigo,
                  title: '深色模式',
                  trailing: Switch.adaptive(
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() => _isDarkMode = value);
                      ref.read(themeModeProvider.notifier).state =
                          value ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 通知與追蹤
            _SettingsGroup(
              title: '通知與追蹤',
              children: [
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  iconColor: Colors.orange,
                  title: '啟用通知',
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 以下為付費功能（預算、位置追蹤、AI 模型設定）
            // MVP 免費版隱藏，未來 Premium 版開放

            // 訂閱
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _PremiumCard(
                colorScheme: cs,
                onTap: () => context.push('/paywall'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 帳戶
            _SettingsGroup(
              title: '帳戶與隱私',
              children: [
                _SettingsTile(
                  icon: Icons.security_rounded,
                  iconColor: Colors.red,
                  title: '更改密碼',
                  showArrow: true,
                  onTap: _showChangePasswordDialog,
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: Colors.blueGrey,
                  title: '隱私政策',
                  showArrow: true,
                  onTap: () => context.push('/privacy-policy'),
                ),
                _SettingsTile(
                  icon: Icons.description_rounded,
                  iconColor: Colors.brown,
                  title: '服務條款',
                  showArrow: true,
                  onTap: () => context.push('/terms'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 關於
            _SettingsGroup(
              title: '關於',
              children: [
                _SettingsTile(
                  icon: Icons.info_rounded,
                  iconColor: Colors.cyan,
                  title: '應用版本',
                  subtitle: '1.0.0',
                ),
                _SettingsTile(
                  icon: Icons.mail_rounded,
                  iconColor: Colors.deepOrange,
                  title: '回報問題',
                  showArrow: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('請聯絡: harrison.tech.0857@gmail.com'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 登出
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('登出'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withAlpha(80)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _logout,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// 用戶資料卡片
class _ProfileCard extends StatelessWidget {
  final ColorScheme colorScheme;
  const _ProfileCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    // 從 Supabase Auth 取得真實使用者資訊
    final user = kMockMode ? null : Supabase.instance.client.auth.currentUser;
    final displayName =
        user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        '語記用戶';
    final email = user?.email ?? (kMockMode ? 'mock-user@demo.app' : '未登入');
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;
    final initial = displayName.isNotEmpty ? displayName[0] : '語';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child:
                avatarUrl == null
                    ? Text(
                      initial,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium 訂閱卡片
class _PremiumCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _PremiumCard({required this.colorScheme, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primary, colorScheme.tertiary],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'VoiceLedger Premium',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '解鎖無限制 AI 分析、進階報告和優先支援',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withAlpha(200),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: colorScheme.primary,
                ),
                onPressed: onTap,
                child: const Text('升級到 Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS 風格的設定群組
class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withAlpha(100),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 設定項目
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showArrow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (showArrow)
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
