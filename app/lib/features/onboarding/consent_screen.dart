import 'package:flutter/material.dart';

/// 用戶同意畫面
/// 在首次使用應用時，用戶必須同意隱私政策和數據收集條款
class ConsentScreen extends StatefulWidget {
  final VoidCallback onConsentAccepted;

  const ConsentScreen({Key? key, required this.onConsentAccepted})
    : super(key: key);

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  // 同意狀態
  bool _agreedToPrivacyPolicy = false;
  bool _agreedToTermsOfService = false;
  bool _agreedToDataProcessing = false;
  bool _agreedToLocationTracking = false;
  bool _agreedToPhotoAnalysis = false;

  // 所有同意都同意時啟用確認按鈕
  bool get _allRequiredConsentsGiven =>
      _agreedToPrivacyPolicy &&
      _agreedToTermsOfService &&
      _agreedToDataProcessing;

  Future<void> _submitConsent() async {
    try {
      // TODO: 實現保存同意到 Supabase
      // await _privacyService.submitConsent(
      //   termsOfServiceAgreed: _agreedToTermsOfService,
      //   privacyPolicyAgreed: _agreedToPrivacyPolicy,
      //   dataProcessingAgreed: _agreedToDataProcessing,
      //   locationTrackingAgreed: _agreedToLocationTracking,
      //   photoAnalysisAgreed: _agreedToPhotoAnalysis,
      // );

      widget.onConsentAccepted();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('提交同意時出錯：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隱私和條款'),
        elevation: 0,
        automaticallyImplyLeading: false, // 禁用返回按鈕
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題
              const Text(
                '歡迎使用語記',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '在開始使用前，請閱讀並同意以下條款和隱私政策',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // 必需的同意項目
              const Text(
                '必需的同意',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 服務條款同意
              CheckboxListTile(
                value: _agreedToTermsOfService,
                onChanged: (value) {
                  setState(() => _agreedToTermsOfService = value ?? false);
                },
                title: const Text('我同意服務條款'),
                subtitle: const Text('了解使用語記的規則和限制'),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    _showLegalDocument(
                      context,
                      '服務條款',
                      '這是一份示範性的服務條款。\n\n'
                          '通過使用語記，您同意：\n'
                          '• 為個人、非商業用途使用應用\n'
                          '• 不進行任何非法活動\n'
                          '• 遵守所有適用的法律和法規\n\n'
                          '有關完整的服務條款，請參閱應用內的法律文件。',
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 隱私政策同意
              CheckboxListTile(
                value: _agreedToPrivacyPolicy,
                onChanged: (value) {
                  setState(() => _agreedToPrivacyPolicy = value ?? false);
                },
                title: const Text('我同意隱私政策'),
                subtitle: const Text('了解我們如何收集和使用您的數據'),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    _showLegalDocument(
                      context,
                      '隱私政策',
                      '隱私政策概述：\n\n'
                          '• 我們收集：姓名、電郵、交易信息\n'
                          '• 我們使用您的數據來改進服務\n'
                          '• 您有權訪問和刪除您的數據\n'
                          '• 我們不會出售您的數據\n\n'
                          '有關完整的隱私政策，請參閱應用內的法律文件。',
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // 數據處理同意
              CheckboxListTile(
                value: _agreedToDataProcessing,
                onChanged: (value) {
                  setState(() => _agreedToDataProcessing = value ?? false);
                },
                title: const Text('我同意數據處理'),
                subtitle: const Text('允許應用處理您的財務數據以提供服務'),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 24),

              // 可選的同意項目
              const Text(
                '可選的功能',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '您可以隨時在設定中更改這些選項',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // 位置追蹤同意
              CheckboxListTile(
                value: _agreedToLocationTracking,
                onChanged: (value) {
                  setState(() => _agreedToLocationTracking = value ?? false);
                },
                title: const Text('允許 GPS 位置追蹤'),
                subtitle: const Text('用於自動推斷消費和生成位置分析'),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: Icon(
                  Icons.location_on,
                  color: _agreedToLocationTracking ? Colors.blue : Colors.grey,
                ),
              ),

              const SizedBox(height: 8),

              // 照片分析同意
              CheckboxListTile(
                value: _agreedToPhotoAnalysis,
                onChanged: (value) {
                  setState(() => _agreedToPhotoAnalysis = value ?? false);
                },
                title: const Text('允許照片分析'),
                subtitle: const Text('從上傳的收據和照片中提取信息'),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: Icon(
                  Icons.camera_alt,
                  color: _agreedToPhotoAnalysis ? Colors.blue : Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              // 信息提示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  '💡 提示：為了獲得最佳體驗，我們建議啟用位置追蹤和照片分析。但這些是可選的，您可以隨時禁用它們。',
                  style: TextStyle(fontSize: 12),
                ),
              ),

              const SizedBox(height: 24),

              // 提交按鈕
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _allRequiredConsentsGiven ? _submitConsent : null,
                  child: const Text('繼續使用應用'),
                ),
              ),

              const SizedBox(height: 12),

              // 拒絕按鈕
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('無法使用應用'),
                        content: const Text(
                          '您必須同意所有必需的條款才能使用語記。如果您不同意，請卸載此應用。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('返回'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('拒絕'),
                ),
              ),

              const SizedBox(height: 16),

              // 底部信息
              Center(
                child: Text(
                  '版本 1.0 | 最後更新：2026 年 3 月',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 顯示法律文件對話框
  void _showLegalDocument(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }
}
