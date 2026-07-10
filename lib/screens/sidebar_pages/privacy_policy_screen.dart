import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
        _buildH2('1. 概述'),
        const Text('OpenFaith（以下简称"我们"）深知个人信息对您的重要性，我们将按照法律法规的规定，保护您的个人信息及隐私安全。本隐私政策适用于 OpenFaith 移动应用及网站（openfaithhub.com）提供的所有服务。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 8),
        const Text('我们制定本隐私政策旨在帮助您了解：我们如何收集、使用、存储和保护您的个人信息；您如何管理您的个人信息。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('2. 我们收集的信息'),
        _buildH3('2.1 您主动提供的信息'),
        _buildList([
          '注册信息：邮箱地址、昵称、身份标签',
          '内容信息：您发布的笔记、评论、问答等用户生成内容',
          '社交信息：关注关系、好友请求、私信内容',
          '支付信息：VIP购买记录（支付处理由第三方完成，我们不存储银行卡信息）',
        ]),
        _buildH3('2.2 自动收集的信息'),
        _buildList([
          '设备信息：设备型号、操作系统版本',
          '使用数据：访问页面、功能使用频率、阅读时长',
          'Cookie 及类似技术：用于维护登录状态、偏好设置',
        ]),

        _buildH2('3. 我们如何使用信息'),
        _buildList([
          '提供、维护和改进我们的服务',
          '个性化推荐内容（基于您的身份标签和阅读偏好）',
          '处理交易和管理VIP会员权益',
          '发送服务通知（系统消息、互动提醒）',
          '安全防护和欺诈检测',
          '遵守法律法规要求',
        ]),

        _buildH2('4. 信息共享'),
        const Text('我们不会出售您的个人信息。仅在以下情况下我们可能共享您的信息：', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        _buildList([
          '获得您的明确同意后',
          '与我们的服务提供商共享（云托管、支付处理），他们仅能出于为我们提供服务之目的使用',
          '遵守法律义务或法律程序',
          '保护我们、用户或公众的权利、财产或安全',
        ]),

        _buildH2('5. 数据存储与安全'),
        const Text('您的数据存储在安全云服务器上，采用行业标准的加密技术传输（TLS/SSL）和存储。我们实施合理的技术和管理措施保护您的信息安全，但无法保证绝对安全。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('6. 您的权利'),
        const Text('根据适用法律，您享有以下权利：', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        _buildListWithBold([
          ('访问权', '：查看您的个人信息'),
          ('更正权', '：修改不准确的信息'),
          ('删除权', '：请求删除您的个人信息'),
          ('数据可携权', '：以通用格式导出您的数据'),
          ('撤回同意权', '：随时撤回您之前给予的同意'),
          ('注销权', '：永久注销您的账号及关联数据'),
        ]),

        _buildH2('7. Cookie 政策'),
        const Text('我们使用 Cookie 和类似技术来：维持登录状态、记住您的偏好设置、分析使用情况以改进服务。您可以通过浏览器设置管理或删除 Cookie，但这可能影响部分功能的使用。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('8. 未成年人保护'),
        const Text('OpenFaith 面向13岁及以上用户。我们不会在知情的情况下收集13岁以下儿童的个人信息。如果我们发现误收集了儿童信息，将及时删除。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('9. 跨境数据传输'),
        const Text('我们的服务可能涉及数据跨境传输。对于中国境内用户，涉及宗教信仰等敏感个人信息的数据处理，我们将在取得您单独同意后进行跨境传输，并确保接收方提供足够的数据保护水平。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('10. 政策更新'),
        const Text('我们可能会不时更新本隐私政策。重大变更时，我们会通过应用内通知或邮件方式告知您。继续使用服务即视为同意更新后的政策。', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('11. 联系我们'),
        const Text('如果您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
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
        _buildH2('1. Overview'),
        const Text('OpenFaith ("we," "us," or "our") respects your privacy and is committed to protecting your personal information. This Privacy Policy applies to all services provided by the OpenFaith mobile application and website (openfaithhub.com).', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('2. Information We Collect'),
        _buildH3('2.1 Information You Provide'),
        _buildList([
          'Registration: Email address, nickname, faith identity tag',
          'Content: Notes, comments, Q&A and other user-generated content',
          'Social: Follow relationships, friend requests, private messages',
          'Payment: VIP purchase records (payment processing handled by third parties; we do not store card details)',
        ]),
        _buildH3('2.2 Information Collected Automatically'),
        _buildList([
          'Device: Model, operating system version',
          'Usage: Pages visited, feature usage frequency, reading time',
          'Cookies: For maintaining login state and preferences',
        ]),

        _buildH2('3. How We Use Information'),
        _buildList([
          'Provide, maintain, and improve our services',
          'Personalize content recommendations',
          'Process transactions and manage VIP memberships',
          'Send service notifications',
          'Security and fraud prevention',
          'Comply with legal obligations',
        ]),

        _buildH2('4. Information Sharing'),
        const Text('We do not sell your personal information. We may share information only:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        _buildList([
          'With your explicit consent',
          'With service providers (cloud hosting, payment processing) for service delivery purposes only',
          'To comply with legal obligations',
          'To protect rights, property, or safety of our users or the public',
        ]),

        _buildH2('5. Data Storage & Security'),
        const Text('Your data is stored on secure cloud servers with industry-standard encryption (TLS/SSL) for transmission and storage. We implement reasonable technical and organizational measures, though no system is completely secure.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('6. Your Rights'),
        const Text('Under applicable law, you have the right to:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
        _buildListWithBold([
          ('Access', ': View your personal information'),
          ('Rectification', ': Correct inaccurate information'),
          ('Erasure', ': Request deletion of your personal information'),
          ('Data Portability', ': Export your data in a common format'),
          ('Withdraw Consent', ': Revoke previously given consent at any time'),
          ('Account Deletion', ': Permanently delete your account and associated data'),
        ]),

        _buildH2('7. Cookie Policy'),
        const Text('We use cookies and similar technologies to: maintain login sessions, remember your preferences, and analyze usage patterns. You can manage or delete cookies through your browser settings, though this may affect functionality.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2("8. Children's Privacy"),
        const Text('OpenFaith is intended for users aged 13 and older. We do not knowingly collect personal information from children under 13. If we discover such information has been collected, we will promptly delete it.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('9. Cross-Border Data Transfers'),
        const Text('Our services may involve cross-border data transfers. For users in China, separate consent will be obtained before transferring sensitive personal data (including religious belief data) across borders, ensuring adequate protection levels.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('10. Policy Updates'),
        const Text('We may update this Privacy Policy from time to time. For material changes, we will notify you via in-app notice or email. Continued use constitutes acceptance of the updated policy.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),

        _buildH2('11. Contact Us'),
        const Text('For questions or suggestions about this Privacy Policy:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
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

  Widget _buildH3(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500)),
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

  Widget _buildListWithBold(List<(String, String)> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: item.$1, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                          TextSpan(text: item.$2, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
                        ]),
                      ),
                    ),
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
              Text(isEnglish ? 'Privacy Policy' : '隐私政策', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
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
