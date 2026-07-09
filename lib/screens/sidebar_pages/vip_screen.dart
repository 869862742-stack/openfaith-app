import 'package:flutter/material.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class VipScreen extends StatefulWidget {
  const VipScreen({super.key});
  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  final _supabase = Supabase.instance.client;
  bool _isVip = false;
  bool _loading = true;
  int _level = 0;
  int _experience = 0;
  Map<String, int> _cards = {};
  String _selectedPlan = 'lifetime';
  bool _processing = false;

  static const _benefitIcons = [
    Icons.visibility, Icons.push_pin, Icons.volume_up, Icons.send,
    Icons.chat_bubble_outline, Icons.workspace_premium, Icons.bolt,
    Icons.headphones, Icons.star, Icons.roundabout_right,
    Icons.person_add, Icons.translate,
  ];
  static const _benefitLabels = [
    '加热卡', '置顶卡', '回响卡', '同行卡', '答疑卡', '专属标识',
    '经验加速', '优先客服', '每日热点翻倍', '无界圆桌主持', '静默同行优先', '藏书无限AI翻译',
  ];
  static const _benefitDescs = [
    '每月1张/可购买', '首页置顶5分钟', '内容二次推荐', '祈祷推送同行',
    '精准推送答疑', '皇冠标识', '获取速度x1.5', '响应快2倍',
    '白录+10热点', '无等级要求', '优先匹配同行', '无限时长翻译',
  ];
  static const _benefitColors = [
    Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD), Color(0xFFFF9F1C),
    Color(0xFF70E000), Color(0xFF9D4EDD), Color(0xFFFF4D6D),
    Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFF70E000),
    Color(0xFF00E5FF), Color(0xFFFFD60A),
  ];  static const _rainbowColors = [


    Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A), Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD)
  ];

  LinearGradient _diagonalGradient(Size size) {
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(0.785398));
  }

  static const _plans = [
    {'id': 'monthly', 'title': '月度会员', 'price': '¥28/月', 'subtitle': '按月续费'},
    {'id': 'quarterly', 'title': '季度会员', 'price': '¥68/季', 'subtitle': '省¥16'},
    {'id': 'yearly', 'title': '年度会员', 'price': '¥198/年', 'subtitle': '省¥138 · 最划算'},
    {'id': 'lifetime', 'title': '终身会员', 'price': '¥299', 'subtitle': '一次付费 · 永久享受'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) { setState(() => _loading = false); return; }
      final res = await _supabase
          .from('profiles')
          .select('is_vip,experience,level,exposure_cards,sticky_cards,echo_cards,companion_cards,qa_cards')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null) {
        setState(() {
          _isVip = res['is_vip'] == true;
          _level = (res['level'] as num?)?.toInt() ?? 0;
          _experience = (res['experience'] as num?)?.toInt() ?? 0;
          _cards = {
            'exposure': (res['exposure_cards'] as num?)?.toInt() ?? 0,
            'sticky': (res['sticky_cards'] as num?)?.toInt() ?? 0,
            'echo': (res['echo_cards'] as num?)?.toInt() ?? 0,
            'companion': (res['companion_cards'] as num?)?.toInt() ?? 0,
            'qa': (res['qa_cards'] as num?)?.toInt() ?? 0,
          };
        });
      }
    } catch (e) {
      debugPrint('VIP load error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPaymentModal() {
    showDialog(
      context: context,
      barrierDismissible: !_processing,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0A0E1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              LayoutBuilder(builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Container(
                width: 56, height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: _diagonalGradient(size)),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0A0E1A)),
                  child: const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
                ),
              );
              }),
              const SizedBox(height: 12),
              const Text('开通 VIP 会员', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('解锁全部 12 项专属权益', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._plans.map((plan) {
                  final isSelected = _selectedPlan == plan['id'];
                  return GestureDetector(
                    onTap: _processing ? null : () => setDialogState(() => _selectedPlan = plan['id'] as String),
                    child: LayoutBuilder(builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isSelected ? _diagonalGradient(size) : null,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: const Color(0xFF050816),
                        ),
                        child: Row(
                          children: [
                            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: isSelected ? const Color(0xFF3A86FF) : Colors.white38, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(plan['title'] as String, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                              Text(plan['subtitle'] as String, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                            ])),
                            Text(plan['price'] as String, style: const TextStyle(color: Color(0xFFFFD60A), fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                    }),
                  );
                }),
                const SizedBox(height: 12),
                if (_selectedPlan == 'lifetime')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('开通即赠：', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 6,
                          children: ['1加热卡', '1置顶卡', '1回响卡', '1同行卡', '1答疑卡', '+500经验'].map((g) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF70E000).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.check, size: 12, color: Color(0xFF70E000)),
                              const SizedBox(width: 4),
                              Text(g, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                            ]),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: _diagonalGradient(size)),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _processing ? null : () {
                        setDialogState(() => _processing = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('支付功能即将上线...'), backgroundColor: AppColors.inputBg, behavior: SnackBarBehavior.floating),
                        );
                        Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(ctx); });
                      },
                      borderRadius: BorderRadius.circular(11),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: _processing
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.workspace_premium, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('即将上线', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ]),
                        ),
                      ),
                    ),
                  ),
                );
                }),
                const SizedBox(height: 8),
                if (_selectedPlan == 'lifetime')
                  Text('一次性付费 · 永久享受', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('订阅会员', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.textSecondary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LayoutBuilder(builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      return Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: _diagonalGradient(size)),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), color: AppColors.background),
                      child: Column(
                        children: [
                          Icon(_isVip ? Icons.workspace_premium : Icons.person_outline, size: 48, color: _isVip ? const Color(0xFFFFD60A) : AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(_isVip ? 'VIP 会员' : '普通用户', style: TextStyle(color: _isVip ? const Color(0xFFFFD60A) : Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Lv.$_level · ${_experience} 经验', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          if (_isVip) ...[
                            const SizedBox(height: 12),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              _cardCount('加热', _cards['exposure'] ?? 0),
                              const SizedBox(width: 16),
                              _cardCount('置顶', _cards['sticky'] ?? 0),
                              const SizedBox(width: 16),
                              _cardCount('回响', _cards['echo'] ?? 0),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  );
                  }),
                  const SizedBox(height: 20),
                  if (!_isVip) ...[
                    ..._plans.asMap().entries.map((entry) {
                      final plan = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () { setState(() => _selectedPlan = plan['id'] as String); _showPaymentModal(); },
                          child: LayoutBuilder(builder: (context, constraints) {
                              final size = Size(constraints.maxWidth, constraints.maxHeight);
                              return Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: _diagonalGradient(size)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: AppColors.background),
                              child: Row(
                                children: [
                                  const Icon(Icons.diamond_outlined, color: Color(0xFFFFD60A), size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(plan['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                    Text(plan['subtitle'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ])),
                                  Text(plan['price'] as String, style: const TextStyle(color: Color(0xFFFFD60A), fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                          }),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                  const Align(alignment: Alignment.centerLeft, child: Text('会员权益', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                  const SizedBox(height: 12),
                  ...List.generate(_benefitLabels.length, (i) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _benefitColors[i].withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(_benefitIcons[i], color: _benefitColors[i], size: 20)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_benefitLabels[i], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                              Text(_benefitDescs[i], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ])),
                            Icon(Icons.check_circle, color: _benefitColors[i].withOpacity(0.4), size: 20),
                          ],
                        ),
                      )),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _cardCount(String label, int count) {
    return Column(children: [
      Text('$count', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ]);
  }
}
