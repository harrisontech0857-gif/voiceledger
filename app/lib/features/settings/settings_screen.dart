import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../core/theme.dart';
import '../../core/app_router.dart';

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
      builder: (context) => AlertDialog(
        title: const Text('登出'),
        content: const Text('確定要登出嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                context.go('/auth');
              }
            },
            child: const Text('登出'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Profile Section
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '使用者名稱',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'user@example.com',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),

            // Display Settings
            _SettingSection(
              title: '顯示',
              children: [
                _SettingTile(
                  icon: Icons.dark_mode_rounded,
                  title: '深色模式',
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() => _isDarkMode = value);
                      ref.read(themeModeProvider.notifier).state =
                          value ? ThemeMode.dark : ThemeMode.light;
                    },
                  ),
                ),
                _SettingTile(
                  icon: Icons.language_rounded,
                  title: '語言',
                  subtitle: '繁體中文',
                  onTap: () {},
                ),
              ],
            ),

            // Notification Settings
            _SettingSection(
              title: '通知與追蹤',
              children: [
                _SettingTile(
                  icon: Icons.notifications_rounded,
                  title: '啟用通知',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                ),
                _SettingTile(
                  icon: Icons.location_on_rounded,
                  title: '位置追蹤',
                  subtitle: '自動檢測和記錄消費地點',
                  trailing: Switch(
                    value: _locationTrackingEnabled,
                    onChanged: (value) {
                      setState(() => _locationTrackingEnabled = value);
                    },
                  ),
                ),
              ],
            ),

            // Budget Settings
            _SettingSection(
              title: '預算設定',
              children: [
                _SettingTile(
                  icon: Icons.wallet_rounded,
                  title: '每日預算',
                  subtitle: 'NT\$ 300',
                  onTap: () => _showBudgetDialog(context),
                ),
                _SettingTile(
                  icon: Icons.calendar_today_rounded,
                  title: '月度預算',
                  subtitle: 'NT\$ 9,000',
                  onTap: () => _showBudgetDialog(context),
                ),
              ],
            ),

            // Account Settings
            _SettingSection(
              title: '帳戶',
              children: [
                _SettingTile(
                  icon: Icons.security_rounded,
                  title: '更改密碼',
                  onTap: () {},
                ),
                _SettingTile(
                  icon: Icons.privacy_tip_rounded,
                  title: '隱私政策',
                  onTap: () {},
                ),
                _SettingTile(
                  icon: Icons.description_rounded,
                  title: '服務條款',
                  onTap: () {},
                ),
              ],
            ),

            // Premium
            _SettingSection(
              title: '訂閱',
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer
                    ]),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VoiceLedger Premium',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '解鎖所有高級功能，包括無限制的 AI 分析、高級報告和優先支援',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Colors.white.withAlpha((255 * 0.9).round()),
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {},
                        child: const Text('升級到 Premium'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // About
            _SettingSection(
              title: '關於',
              children: [
                _SettingTile(
                  icon: Icons.info_rounded,
                  title: '應用版本',
                  subtitle: '1.0.0',
                ),
                _SettingTile(
                  icon: Icons.mail_rounded,
                  title: '回報問題',
                  onTap: () {},
                ),
              ],
            ),

            // Logout
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('登出'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withAlpha((255 * 0.1).round()),
                    foregroundColor: Colors.red,
                  ),
                  onPressed: _logout,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定預算'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '金額',
            prefixText: 'NT\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('預算已更新')));
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerLow
              .withAlpha((255 * 0.5).round()),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon,
                  color: Theme.of(context).colorScheme.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
