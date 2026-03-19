import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// 使用條款頁面
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('使用條款')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '語記 使用條款',
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
            _buildSection(context, '1. 服務說明', '''
語記是一款 AI 輔助的情侶日記應用程式，提供語音日記、情緒分析、寵物養成等功能。'''),
            _buildSection(context, '2. 使用者責任', '''
• 您需確保帳戶資訊的準確性
• 您對帳戶的所有活動負責
• 禁止將本服務用於非法活動
• 禁止嘗試破壞或干擾服務運作'''),
            _buildSection(context, '3. 智慧財產權', '''
本應用程式及其內容受著作權法保護。您不得複製、修改、分發本應用程式的任何部分。'''),
            _buildSection(context, '4. 免責聲明', '''
• 本應用程式提供的分析僅供參考，不構成專業意見
• 我們不保證 AI 分析的 100% 準確性
• 語音辨識結果可能因環境因素而有所差異
• 我們不對因使用本服務造成的資料損失負責'''),
            _buildSection(context, '5. 訂閱與付費', '''
• 免費版提供基本功能
• 付費版提供進階功能，依訂閱方案收費
• 訂閱可隨時取消，當期結束後不再續費
• 退款依照 Apple App Store / Google Play 政策處理'''),
            _buildSection(context, '6. 服務變更與終止', '''
我們保留修改、暫停或終止服務的權利。重大變更將提前通知使用者。'''),
            _buildSection(context, '7. 適用法律', '''
本條款適用中華民國法律。任何爭議應提交台北地方法院管轄。'''),
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
