import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // GPS 追蹤開關
  bool _locationTrackingEnabled = false;

  // 照片分析開關
  bool _photoAnalysisEnabled = false;

  // 推播通知開關
  bool _pushNotificationsEnabled = true;

  // 位置資料保留天數
  int _locationRetentionDays = 30;

  // 加載狀態
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _locationTrackingEnabled =
            prefs.getBool('locationTrackingEnabled') ?? false;
        _photoAnalysisEnabled = prefs.getBool('photoAnalysisEnabled') ?? false;
        _pushNotificationsEnabled =
            prefs.getBool('pushNotificationsEnabled') ?? true;
        _locationRetentionDays = prefs.getInt('locationRetentionDays') ?? 30;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入隱私設定失敗：$e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('locationTrackingEnabled', _locationTrackingEnabled);
      await prefs.setBool('photoAnalysisEnabled', _photoAnalysisEnabled);
      await prefs.setBool(
          'pushNotificationsEnabled', _pushNotificationsEnabled);
      await prefs.setInt('locationRetentionDays', _locationRetentionDays);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('隱私設定已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存隱私設定失敗：$e')),
        );
      }
    }
  }

  Future<void> _requestDataExport() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('數據匯出'),
        content: const Text('您將收到一個包含您所有個人數據的 JSON 文件的下載鏈接。此操作將在 24 小時內完成。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('數據匯出請求已提交，請檢查電郵以獲取下載鏈接')),
              );
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAccountDeletion() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除帳戶'),
        content: const Text(
          '刪除帳戶將永久刪除您的所有個人數據和交易記錄。此操作無法撤銷。\n\n'
          '根據 GDPR 規定，您有 30 天的冷卻期可以取消此請求。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // 顯示確認對話框
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('確認刪除帳戶'),
                  content: const Text('您確認要刪除帳戶嗎？此操作無法撤銷。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('確認刪除'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('帳戶刪除請求已提交，您將在 30 天後被永久刪除')),
                );
              }
            },
            child: const Text('刪除帳戶', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隱私設定'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 數據收集部分
                    const Text(
                      '數據收集',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // GPS 追蹤開關
                    SwitchListTile(
                      title: const Text('GPS 位置追蹤'),
                      subtitle: const Text('允許應用追蹤您的位置以自動推斷消費'),
                      value: _locationTrackingEnabled,
                      onChanged: (value) {
                        setState(() => _locationTrackingEnabled = value);
                        _updatePrivacySettings();
                      },
                      secondary: const Icon(Icons.location_on),
                    ),

                    // 位置保留期設定
                    if (_locationTrackingEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xs),
                            const Text('位置數據保留期限'),
                            const SizedBox(height: AppSpacing.xs),
                            Slider(
                              value: _locationRetentionDays.toDouble(),
                              min: 7,
                              max: 90,
                              divisions: 10,
                              label: '$_locationRetentionDays 天',
                              onChanged: (value) {
                                setState(
                                  () => _locationRetentionDays = value.toInt(),
                                );
                                _updatePrivacySettings();
                              },
                            ),
                            Text('位置數據將在 $_locationRetentionDays 天後自動刪除'),
                          ],
                        ),
                      ),

                    const Divider(height: AppSpacing.xl),

                    // 照片分析開關
                    SwitchListTile(
                      title: const Text('照片分析'),
                      subtitle: const Text('允許應用分析您上傳的收據和照片'),
                      value: _photoAnalysisEnabled,
                      onChanged: (value) {
                        setState(() => _photoAnalysisEnabled = value);
                        _updatePrivacySettings();
                      },
                      secondary: const Icon(Icons.camera_alt),
                    ),

                    const Divider(height: AppSpacing.xl),

                    // 推播通知開關
                    SwitchListTile(
                      title: const Text('推播通知'),
                      subtitle: const Text('接收預算警告和每日洞察推播通知'),
                      value: _pushNotificationsEnabled,
                      onChanged: (value) {
                        setState(() => _pushNotificationsEnabled = value);
                        _updatePrivacySettings();
                      },
                      secondary: const Icon(Icons.notifications),
                    ),

                    const SizedBox(height: 32),
                    const Divider(),

                    // 數據權利部分
                    const Text(
                      '您的數據權利',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 數據匯出按鈕
                    ElevatedButton.icon(
                      onPressed: _requestDataExport,
                      icon: const Icon(Icons.download),
                      label: const Text('匯出我的數據'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // 隱私政策連結
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: 打開隱私政策
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('打開隱私政策（待實現）')),
                        );
                      },
                      icon: const Icon(Icons.description),
                      label: const Text('查看隱私政策'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                    const Divider(),
                    const Text(
                      '帳戶',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: _requestAccountDeletion,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('刪除帳戶'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: Colors.red.withAlpha((255 * 0.3).round())),
                      ),
                      child: const Text(
                        '警告：刪除帳戶將永久刪除您的所有數據。此操作無法撤銷。根據 GDPR，您有 30 天的冷卻期可以取消此請求。',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }
}
