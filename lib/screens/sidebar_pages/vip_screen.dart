import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rainbow_border.dart';

/// VIP 订阅会员页 - 对齐网页版 VIP.tsx
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
  bool _processing = false;

  // 权益数据 - 对齐网页版 benefitCards
  static const _benefitItems = <Map<String, dynamic>>[
    {
      'icon': Icons.visibility,
      'label': '加热卡',
      'desc': '每月1张+可购买',
      'color': AppColors.auroraCyan,
    },
    {
      'icon': Icons.push_pin,
      'label': '置顶卡',
      'desc': '首页置顶5分钟',
      'color': AppColors.auroraBlue,
    },
    {
      'icon': Icons.volume_up,
      'label': '回响卡',
      'desc': '内容二次推荐',
      'color': AppColors.auroraPurple,
    },
    {
      'icon': Icons.send,
      'label': '同行卡',
      'desc': '祈祷推送同行',
      'color': AppColors.auroraOrange,
    },
    {
      'icon': Icons.chat_bubble_outline,
      'label': '答疑卡',
      'desc': '精准推送答疑',
      'color': AppColors.auroraGreen,
    },
    {
      'icon': Icons.workspace_premium,
      'label': '专属标识',
      'desc': '皇冠标识',
      'color': AppColors.auroraPurple,
    },
    {
      'icon': Icons.bolt,
      'label': '经验加速',
      'desc': '获取速度x1.5',
      'color': AppColors.auroraRed,
    },
    {
      'icon': Icons.headphones,
      'label': '优先客服',
      'desc': '响应快1倍',
      'color': AppColors.auroraRed,
    },
    {
      'icon': Icons.star,
      'label': '每日热点翻倍',
      'desc': '登录+10热点',
      'color': AppColors.auroraOrange,
    },
    {
      'icon': Icons.roundabout_right,
      'label': '无界圆桌主持',
      'desc': '无等级要求',
      'color': AppColors.auroraGreen,
    },
    {
      'icon': Icons.person_add,
      'label': '静默同行优先',
      'desc': '优先匹配同行',
      'color': AppColors.auroraCyan,
    },
    {
      'icon': Icons.translate,
      'label': '藏书无限AI翻译',
      'desc': '无限时长翻译',
      'color': AppColors.auroraYellow,
    },
  ];

  // 开通即享礼物列表
  static const _giftItems = [
    '1张加热卡',
    '1张置顶卡',
    '1张回响卡',
    '1张同行卡',
    '1张答疑卡',
    '+500经验',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }
      final res = await _supabase
          .from('profiles')
          .select(
            'is_vip,experience,level,exposure_cards,sticky_cards,echo_cards,companion_cards,qa_cards',
          )
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null) {
        if (!mounted) return;
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.overlayBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderActive,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Crown icon with rainbow border
              RainbowBorder(
                borderRadius: 40,
                borderWidth: 1,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.overlayBg,
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: AppColors.textPrimary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '开通 VIP 会员',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '解锁全部 12 项专属权益',
                style: TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // Price card
              RainbowBorder(
                borderRadius: 10,
                borderWidth: 0.5,
                opacity: 0.5,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'VIP 会员（终身）',
                            style: TextStyle(
                              color: AppColors.textWeak,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            '¥99',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '🎁 开通即送：1加热卡 + 1置顶卡 + 1回响卡 + 1同行卡 + 1答疑卡',
                        style: TextStyle(
                          color: AppColors.textPlaceholder,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Purchase button
              GestureDetector(
                onTap: _processing
                    ? null
                    : () {
                        setState(() => _processing = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('💳 VIP支付功能即将上线，敬请期待！'),
                            backgroundColor: AppColors.overlayBg,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            Navigator.pop(ctx);
                            setState(() => _processing = false);
                          }
                        });
                      },
                child: RainbowBorder(
                  borderRadius: 12,
                  borderWidth: 1.5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: _processing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium,
                                color: AppColors.textPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '即将上线',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Cancel button
              GestureDetector(
                onTap: _processing ? null : () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.hoverBgLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: AppColors.textWeak,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              children: [
                // ── 毛玻璃 Header ──
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.headerBg,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.borderDefault,
                            width: 0.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: AppColors.textPrimary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '订阅会员',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 内容 ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 112,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // ── Hero: Crown ──
                        _buildHeroSection(),
                        const SizedBox(height: 32),

                        // ── VIP 我的特权卡片 ──
                        if (_isVip) ...[
                          _buildMyCardsSection(),
                          const SizedBox(height: 32),
                        ],

                        // ── VIP 专属权益 ──
                        _buildBenefitsSection(),
                        const SizedBox(height: 32),

                        // ── 开通即享 (non-VIP) ──
                        if (!_isVip) ...[
                          _buildGiftSection(),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── 底部 CTA (non-VIP) ──
                if (!_isVip) _buildBottomCTA(),
              ],
            ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        // Crown icon with glow + rainbow border
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.auroraRed.withOpacity(0.15),
                AppColors.auroraCyan.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: RainbowBorder(
              borderRadius: 48,
              borderWidth: 1,
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgColor,
                ),
                child: Icon(
                  _isVip
                      ? Icons.workspace_premium
                      : Icons.person_outline,
                  color: AppColors.textPrimary,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isVip ? 'VIP 会员' : '解锁专属权益',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isVip ? '您已是终身会员' : '升级VIP，畅享信仰之旅',
          style: TextStyle(
            color: AppColors.textWeak,
            fontSize: 14,
          ),
        ),
        if (_isVip) ...[
          const SizedBox(height: 12),
          RainbowBorder(
            borderRadius: 20,
            borderWidth: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: AppColors.textPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '终身会员',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMyCardsSection() {
    final cardData = [
      {'icon': Icons.visibility, 'label': '加热卡', 'count': _cards['exposure'] ?? 0},
      {'icon': Icons.push_pin, 'label': '置顶卡', 'count': _cards['sticky'] ?? 0},
      {'icon': Icons.volume_up, 'label': '回响卡', 'count': _cards['echo'] ?? 0},
      {'icon': Icons.send, 'label': '同行卡', 'count': _cards['companion'] ?? 0},
      {'icon': Icons.chat_bubble_outline, 'label': '答疑卡', 'count': _cards['qa'] ?? 0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '我的特权卡片',
          style: TextStyle(
            color: AppColors.textWeak,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(cardData.length, (i) {
            final card = cardData[i];
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  left: i > 0 ? 4 : 0,
                  right: i < cardData.length - 1 ? 4 : 0,
                ),
                child: RainbowBorder(
                  borderRadius: 12,
                  borderWidth: 0.5,
                  opacity: 0.5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Icon(
                          card['icon'] as IconData,
                          color: AppColors.textPrimary,
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${card['count']}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card['label'] as String,
                          style: TextStyle(
                            color: AppColors.textWeak,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '每月赠送1张，超月未用自动过期',
          style: TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VIP 专属权益',
          style: TextStyle(
            color: AppColors.textWeak,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: List.generate(_benefitItems.length, (i) {
            final item = _benefitItems[i];
            final icon = item['icon'] as IconData;
            final label = item['label'] as String;
            final desc = item['desc'] as String;
            final color = item['color'] as Color;

            return RainbowBorder(
              borderRadius: 12,
              borderWidth: 0.5,
              opacity: 0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildGiftSection() {
    return RainbowBorder(
      borderRadius: 16,
      borderWidth: 0.5,
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '开通即享',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _giftItems.map((gift) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.hoverBgLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        color: AppColors.auroraGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        gift,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.background,
            AppColors.background.withOpacity(0.7),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            GestureDetector(
              onTap: _showPaymentModal,
              child: RainbowBorder(
                borderRadius: 16,
                borderWidth: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '开通 VIP 会员',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '¥99',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '一次性付费 · 永久享受',
              style: TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
