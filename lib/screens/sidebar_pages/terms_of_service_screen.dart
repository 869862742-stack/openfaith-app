import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEnglish ? 'Terms of Service' : '用户协议',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEnglish = !_isEnglish),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Text(
                _isEnglish ? '中文' : 'EN',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isEnglish ? _buildEnglishContent() : _buildChineseContent(),
      ),
    );
  }

  Widget _buildChineseContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('OpenFaith 用户协议', [
          '最后更新日期：2026年4月24日',
          '',
          '欢迎使用 OpenFaith（"本应用"、"我们"或"我们的"）。本协议由您（"用户"）与 OpenFaith 运营方共同缔结。',
        ]),
        const SizedBox(height: 16),
        _buildSection('1. 接受本协议', [
          '通过注册、登录或使用 OpenFaith，您确认您已阅读、理解并同意受本协议所有条款的约束。如果您不同意，请勿使用本应用。',
        ]),
        const SizedBox(height: 16),
        _buildSection('2. 账号注册与安全', [
          '您须提供真实、准确的注册信息（如邮箱/手机、用户名）。您对账号下的所有活动负全责。如发现未经授权使用，请立即通知我们。',
        ]),
        const SizedBox(height: 16),
        _buildSection('3. 用户行为规范', [
          '您承诺在使用本应用时遵守所有适用的国际、国家和地方法律法规，并不得：',
          '发布任何非法、诽谤、淫秽、仇恨、暴力或煽动宗教对立的内容；',
          '侵犯他人隐私、知识产权或其他合法权益；',
          '传播病毒、恶意代码或进行任何可能破坏本应用安全的行为；',
          '冒充他人或组织，或虚假陈述与某一实体的关联。',
          '',
          '我们有权对违规内容进行删除，并对违规账号采取警告、限制功能、暂停或永久封禁等措施。',
        ]),
        const SizedBox(height: 16),
        _buildSection('4. 内容所有权与授权', [
          '您保留您发布的内容（如笔记、评论）的所有权。但您授予 OpenFaith 一项全球范围内、免版税、非独占的许可，以便我们存储、展示、推广您的内容。',
        ]),
        const SizedBox(height: 16),
        _buildSection('5. 隐私政策', [
          '我们重视您的隐私。收集、使用和保护您个人信息的具体做法，请查阅我们的《隐私政策》，该政策是本协议不可分割的一部分。',
        ]),
        const SizedBox(height: 16),
        _buildSection('6. 免责声明', [
          '本应用按"现状"提供，我们不保证服务无中断、无错误。用户发布的内容不代表本应用立场。',
        ]),
        const SizedBox(height: 16),
        _buildSection('7. 修改与终止', [
          '我们有权修改本协议，修改后的协议将通过应用内公告通知您。如您继续使用，则视为接受修改。您可随时停止使用并注销账号。',
        ]),
        const SizedBox(height: 16),
        _buildSection('8. 适用法律与争议解决', [
          '本协议的解释及争议解决，适用香港法律（或您指定的法律区域）。争议应首先通过友好协商解决；协商不成的，提交香港国际仲裁中心（HKIAC）仲裁。',
        ]),
        const SizedBox(height: 16),
        _buildSection('9. 联系我们', [
          '如有疑问，请通过 hello@openfaithhub.com 与我们联系。',
        ]),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEnglishContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('OpenFaith Terms of Service', [
          'Last Updated: April 24, 2026',
          '',
          'Welcome to OpenFaith ("the App," "we," "our," or "us"). This Agreement is entered into between you ("User") and the OpenFaith operator.',
        ]),
        const SizedBox(height: 16),
        _buildSection('1. Acceptance of Terms', [
          'By registering, logging in, or using OpenFaith, you confirm that you have read, understood, and agree to be bound by all terms of this Agreement. If you do not agree, please do not use the App.',
        ]),
        const SizedBox(height: 16),
        _buildSection('2. Account Registration & Security', [
          'You must provide true and accurate registration information (e.g., email/phone, username). You are fully responsible for all activities under your account. If you discover unauthorized use, please notify us immediately.',
        ]),
        const SizedBox(height: 16),
        _buildSection('3. User Conduct', [
          'You agree to comply with all applicable international, national, and local laws when using this App, and you must not:',
          'Post any illegal, defamatory, obscene, hateful, violent, or religiously divisive content;',
          'Infringe upon others\' privacy, intellectual property, or other legal rights;',
          'Spread viruses, malicious code, or engage in any activity that may compromise the App\'s security;',
          'Impersonate another person or organization, or misrepresent your affiliation with any entity.',
          '',
          'We reserve the right to remove violating content and take measures against violating accounts, including warnings, feature restrictions, suspension, or permanent bans.',
        ]),
        const SizedBox(height: 16),
        _buildSection('4. Content Ownership & License', [
          'You retain ownership of content you post (e.g., notes, comments). However, you grant OpenFaith a worldwide, royalty-free, non-exclusive license to store, display, and promote your content.',
        ]),
        const SizedBox(height: 16),
        _buildSection('5. Privacy Policy', [
          'We value your privacy. For details on how we collect, use, and protect your personal information, please refer to our Privacy Policy, which is an integral part of this Agreement.',
        ]),
        const SizedBox(height: 16),
        _buildSection('6. Disclaimer', [
          'The App is provided "as is." We do not guarantee uninterrupted or error-free service. Content posted by users does not represent the App\'s position.',
        ]),
        const SizedBox(height: 16),
        _buildSection('7. Modifications & Termination', [
          'We reserve the right to modify this Agreement. Changes will be communicated via in-app announcements. Continued use constitutes acceptance of the modifications. You may stop using the App and delete your account at any time.',
        ]),
        const SizedBox(height: 16),
        _buildSection('8. Governing Law & Dispute Resolution', [
          'This Agreement shall be governed by and construed in accordance with the laws of Hong Kong (or your specified jurisdiction). Disputes shall first be resolved through amicable negotiation; if unresolved, submitted to the Hong Kong International Arbitration Centre (HKIAC) for arbitration.',
        ]),
        const SizedBox(height: 16),
        _buildSection('9. Contact Us', [
          'If you have any questions, please contact us at hello@openfaithhub.com.',
        ]),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection(String title, List<String> paragraphs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...paragraphs.map((text) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            text,
            style: TextStyle(
              color: text.isEmpty ? Colors.transparent : Colors.white.withOpacity(0.65),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        )),
      ],
    );
  }
}
