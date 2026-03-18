import 'package:flutter/material.dart';

/// 付費牆 UI
/// 展示不同的訂閱方案，用戶可以選擇升級
class PaywallScreen extends StatefulWidget {
  final String? currentTier;
  final VoidCallback? onPremiumSelected;

  const PaywallScreen({Key? key, this.currentTier, this.onPremiumSelected})
      : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;
  String? _selectedBillingCycle = 'monthly'; // 'monthly' 或 'yearly'

  /// 訂閱方案定義
  final _plans = [
    {
      'name': 'Free',
      'tier': 'free',
      'description': '基礎功能',
      'monthlyPrice': 0,
      'yearlyPrice': 0,
      'features': ['語音輸入（50 次/月）', '手動記帳', '基礎分析', '每月最多 100 筆交易'],
      'recommended': false,
    },
    {
      'name': 'Premium',
      'tier': 'premium',
      'description': '增強功能',
      'monthlyPrice': 99,
      'yearlyPrice': 999,
      'features': ['無限語音輸入', '手動記帳', 'AI 分類', '高級分析', '被動追蹤', '每月最多 1000 筆交易'],
      'recommended': true,
    },
    {
      'name': 'Pro',
      'tier': 'pro',
      'description': '完整功能',
      'monthlyPrice': 199,
      'yearlyPrice': 1999,
      'features': ['所有 Premium 功能', '照片分析', 'API 訪問', '無限交易', '優先支持'],
      'recommended': false,
    },
    {
      'name': 'Family',
      'tier': 'family',
      'description': '家庭版',
      'monthlyPrice': 299,
      'yearlyPrice': 2999,
      'features': ['所有 Pro 功能', '家庭共享（最多 6 人）', '分離的預算', '協作管理', '優先支持'],
      'recommended': false,
    },
  ];

  Future<void> _selectPlan(String tier) async {
    setState(() => _isLoading = true);

    try {
      // TODO: 實現訂閱邏輯
      // 如果啟用 ENABLE_REVENUECAT=true，使用 RevenueCat SDK
      // 否則使用 mock 實現

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('選擇升級到 $tier（待實現）')));

      widget.onPremiumSelected?.call();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('訂閱失敗：$e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getPrice(Map<String, dynamic> plan) {
    final price = _selectedBillingCycle == 'monthly'
        ? plan['monthlyPrice'] as int?
        : plan['yearlyPrice'] as int?;
    return price == 0 ? '免費' : 'NT\$$price';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('升級訂閱'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 標題
                    const Text(
                      '選擇適合您的方案',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '立即升級以解鎖更多功能',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // 計費周期選擇
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'monthly',
                                label: Text('月度'),
                              ),
                              ButtonSegment(
                                value: 'yearly',
                                label: Text('年度 (省 17%)'),
                              ),
                            ],
                            selected: {_selectedBillingCycle!},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedBillingCycle = newSelection.first;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 訂閱方案卡片
                    ..._plans.map((plan) {
                      final isRecommended = plan['recommended'] as bool;
                      final isCurrent = plan['tier'] == widget.currentTier;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Stack(
                          children: [
                            Card(
                              elevation: isRecommended ? 4 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isRecommended
                                      ? Colors.blue
                                      : Colors.grey.shade200,
                                  width: isRecommended ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 計劃名稱和描述
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plan['name'] as String,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              plan['description'] as String,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isCurrent)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '當前',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // 價格
                                    Text(
                                      _getPrice(plan),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_selectedBillingCycle == 'yearly')
                                      Text(
                                        '${((plan['yearlyPrice'] as int) / 12).toStringAsFixed(2)}/月',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),

                                    const SizedBox(height: 16),

                                    // 功能列表
                                    ...(plan['features'] as List<String>).map((
                                      feature,
                                    ) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              feature,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                    const SizedBox(height: 16),

                                    // 按鈕
                                    SizedBox(
                                      width: double.infinity,
                                      child: isCurrent
                                          ? OutlinedButton(
                                              onPressed: null,
                                              child: const Text('當前方案'),
                                            )
                                          : ElevatedButton(
                                              onPressed: () => _selectPlan(
                                                plan['tier'] as String,
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isRecommended
                                                    ? Colors.blue
                                                    : Colors.grey.shade300,
                                                foregroundColor: isRecommended
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                              child: const Text('選擇此方案'),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isRecommended)
                              Positioned(
                                top: -8,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '推薦',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 24),

                    // 常見問題
                    const Text(
                      '常見問題',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildFAQItem(
                      '我可以隨時取消訂閱嗎？',
                      '是的，您可以隨時在應用設定中取消訂閱。取消後，您將在當前計費周期結束時失去高級功能。',
                    ),

                    _buildFAQItem(
                      '支持哪些付款方式？',
                      '我們支持所有主要的信用卡（Visa、Mastercard）和本地支付方式。具體取決於您所在的地區。',
                    ),

                    _buildFAQItem(
                      '年度訂閱有什麼優處？',
                      '年度訂閱可以節省高達 17% 的費用。例如，Premium 方案年度訂閱是 999 元，相當於每月 83 元。',
                    ),

                    _buildFAQItem(
                      '有退款保證嗎？',
                      '根據應用市場的政策，應用內購買通常是不可退款的。但是，您可以根據您所在區域的應用市場政策申請退款。',
                    ),

                    const SizedBox(height: 24),

                    // 隱私政策連結
                    Center(
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('打開隱私政策')),
                              );
                            },
                            child: const Text('隱私政策'),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('打開服務條款')),
                              );
                            },
                            child: const Text('服務條款'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(answer, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
