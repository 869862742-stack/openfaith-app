import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  bool _isEnglish = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              isEnglish: _isEnglish,
              onToggleLang: () => setState(() => _isEnglish = !_isEnglish),
              onBack: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: _isEnglish ? _buildEnglishContent() : _buildChineseContent(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildChineseContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('最后更新：2026年6月7日', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12)),
        const SizedBox(height: 24),

        _buildH2('1. 接受条款'),
        const Text('欢迎使用 OpenFaith！使用本应用及网站（openfaithhub.com）即表示您同意遵守本服务条款。如果您不同意这些条款，请勿使用我们的服务。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('2. 服务描述'),
        const Text('OpenFaith 是一个宗教经典阅读与信仰交流平台，提供以下核心服务：', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        _buildList([
          '多宗教经典书籍的在线阅读',
          '信仰社区互动（笔记、评论、问答）',
          '静默陪伴与共境功能',
          'VIP会员增值服务',
        ]),

        _buildH2('3. 用户资格'),
        _buildList([
          '您必须年满13周岁方可使用本服务',
          '您提供的注册信息必须真实、准确',
          '每人仅限注册一个账号',
          '不得使用他人身份注册或使用服务',
        ]),

        _buildH2('4. 用户行为规范'),
        const Text('您在使用本服务时，不得：', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        _buildList([
          '发布违法、淫秽、诽谤、仇恨、暴力或歧视性内容',
          '冒充他人或虚构身份',
          '骚扰、威胁或恐吓其他用户',
          '传播垃圾信息或恶意软件',
          '侵犯他人知识产权或其他权利',
          '试图未经授权访问系统或其他用户账号',
          '利用系统漏洞获取不当利益',
          '破坏或干扰服务的正常运行',
        ]),

        _buildH2('5. 用户生成内容'),
        const Text('您对您发布的内容承担全部责任。发布内容即表示您授予 OpenFaith 非独占的、全球性的、免费的许可，以展示和分发您的内容。我们保留移除违反本条款内容的权利，但无义务监控所有内容。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('6. VIP会员服务'),
        _buildList([
          'VIP会员为付费增值服务，具体权益以应用内展示为准',
          '支付完成后，VIP权益即时生效',
          'VIP会员按购买周期计费，到期后自动失效',
          '虚拟道具（卡片等）一经发放使用，不予退款',
        ]),

        _buildH2('7. 知识产权'),
        const Text('OpenFaith 平台的设计、代码、商标等归 OpenFaith 所有。平台收录的宗教经典文本属于公有领域或已获授权。未经许可，不得复制、修改或分发平台内容。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('8. 免责声明'),
        _buildList([
          '服务按"现状"提供，不作任何明示或暗示的保证',
          '我们不保证服务的不间断或无错误',
          '用户生成内容不代表 OpenFaith 的观点',
          '我们对第三方链接或服务不承担责任',
        ]),

        _buildH2('9. 责任限制'),
        const Text('在法律允许的最大范围内，OpenFaith 对因使用或无法使用本服务而产生的任何间接、附带、特殊或后果性损害不承担责任。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('10. 账号终止'),
        const Text('违反本条款可能导致账号被暂停或终止。您可随时申请注销账号，注销后您的数据将在冷静期后被永久删除。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('11. 争议解决'),
        const Text('本条款受中华人民共和国法律管辖。因本条款产生的争议，双方应友好协商解决；协商不成的，提交有管辖权的人民法院诉讼解决。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('12. 条款修改'),
        const Text('我们保留随时修改本条款的权利。重大变更将通过应用内通知告知。继续使用服务即视为接受修改后的条款。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('13. 联系我们'),
        const Text('如有关于本服务条款的疑问，请联系：', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 4),
        const Text('邮箱：hello@openfaithhub.com', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
      ],
    );
  }

  Widget _buildEnglishContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Last Updated: June 7, 2026', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 12)),
        const SizedBox(height: 24),

        _buildH2('1. Acceptance of Terms'),
        const Text('Welcome to OpenFaith! By using our application and website (openfaithhub.com), you agree to be bound by these Terms of Service. If you do not agree, please do not use our services.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('2. Service Description'),
        const Text('OpenFaith is a religious scripture reading and faith community platform providing:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        _buildList([
          'Online reading of multi-religion scripture books',
          'Faith community interaction (notes, comments, Q&A)',
          'Silent companionship and shared meditation features',
          'VIP membership premium services',
        ]),

        _buildH2('3. User Eligibility'),
        _buildList([
          'You must be at least 13 years old to use this service',
          'Registration information must be true and accurate',
          'One account per person only',
          "You may not use another person's identity",
        ]),

        _buildH2('4. User Conduct'),
        const Text('You must not:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        _buildList([
          'Post illegal, obscene, defamatory, hateful, violent, or discriminatory content',
          'Impersonate others or create fake identities',
          'Harass, threaten, or intimidate other users',
          'Transmit spam or malicious software',
          "Infringe others' intellectual property or other rights",
          "Attempt unauthorized access to systems or other users' accounts",
          'Exploit system vulnerabilities for improper gain',
          'Disrupt or interfere with normal service operation',
        ]),

        _buildH2('5. User-Generated Content'),
        const Text('You are solely responsible for content you post. By posting, you grant OpenFaith a non-exclusive, worldwide, royalty-free license to display and distribute your content. We reserve the right to remove content violating these Terms, but have no obligation to monitor all content.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('6. VIP Membership'),
        _buildList([
          'VIP membership is a paid premium service; benefits are as displayed in-app',
          'VIP benefits take effect immediately upon payment',
          'VIP membership is billed per purchase period and expires automatically',
          'Virtual items (cards, etc.) are non-refundable once used',
        ]),

        _buildH2('7. Intellectual Property'),
        const Text("OpenFaith's platform design, code, and trademarks belong to OpenFaith. Religious scripture texts are in the public domain or used with authorization. You may not copy, modify, or distribute platform content without permission.", style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('8. Disclaimer'),
        _buildList([
          'Services are provided "as is" without warranties',
          'We do not guarantee uninterrupted or error-free service',
          "User-generated content does not represent OpenFaith's views",
          'We are not responsible for third-party links or services',
        ]),

        _buildH2('9. Limitation of Liability'),
        const Text('To the maximum extent permitted by law, OpenFaith shall not be liable for any indirect, incidental, special, or consequential damages arising from the use or inability to use our services.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('10. Account Termination'),
        const Text('Violation of these Terms may result in account suspension or termination. You may request account deletion at any time; your data will be permanently deleted after a cooling-off period.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('11. Dispute Resolution'),
        const Text("These Terms are governed by the laws of the People's Republic of China. Disputes shall be resolved through friendly negotiation; if unresolved, submitted to the competent People's Court.", style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('12. Modifications'),
        const Text('We reserve the right to modify these Terms at any time. Material changes will be communicated via in-app notification. Continued use constitutes acceptance of modified Terms.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('13. Contact Us'),
        const Text('For questions about these Terms:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 4),
        const Text('Email: hello@openfaithhub.com', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
      ],
    );
  }

  Widget _buildH2(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    Expanded(child: Text(item, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final bool isEnglish;
  final VoidCallback onToggleLang;
  final VoidCallback onBack;

  _SliverAppBarDelegate({required this.isEnglish, required this.onToggleLang, required this.onBack});

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: AppColors.headerBg,
            border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Text('← 返回', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 14)),
              ),
              const Spacer(),
              Text(isEnglish ? 'Terms of Service' : '服务条款', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: onToggleLang,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.hoverBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEnglish ? '中文' : 'EN',
                    style: const TextStyle(color: AppColors.iconColorWeak, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
