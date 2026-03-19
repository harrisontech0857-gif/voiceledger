import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// 隱私政策頁面
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('隱私政策')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '語記 隱私政策',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '最後更新日期：2026 年 3 月 18 日',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(context, '1. 資料收集', '''
我們收集以下資料以提供服務：
• 帳戶資訊（電子郵件、顯示名稱）
• 日記紀錄（內容、時間戳記）
• 語音輸入（僅在您主動使用語音日記時）
• 位置資訊（僅在您開啟位置功能時）

我們不會收集不必要的個人資料。'''),
            _buildSection(context, '2. 資料使用', '''
您的資料僅用於：
• 提供日記與情緒分析服務
• AI 輔助情緒分析與建議
• 改善服務品質
• 發送您訂閱的通知

我們不會出售您的個人資料給第三方。'''),
            _buildSection(context, '3. 資料儲存與安全', '''
• 資料儲存於 Supabase 雲端服務（AWS 基礎設施）
• 所有資料傳輸使用 TLS 加密
• 資料庫啟用行級安全性（RLS）
• 定期安全審查與漏洞掃描'''),
            _buildSection(context, '4. 資料保留', '''
• 帳戶資料：帳戶存續期間保留
• 日記紀錄：帳戶存續期間保留
• 語音資料：處理完成後立即刪除
• 位置資料：依您設定的保留天數自動清除'''),
            _buildSection(context, '5. 您的權利', '''
根據 GDPR 和相關法規，您有權：
• 存取您的個人資料
• 要求修正不準確的資料
• 要求刪除您的資料
• 匯出您的資料
• 撤回同意

請透過設定頁面的「隱私設定」執行上述操作。'''),
            _buildSection(context, '6. 聯絡我們', '''
如有任何隱私相關問題，請聯絡：
voiceledger@privacy.com'''),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(content.trim(), style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
