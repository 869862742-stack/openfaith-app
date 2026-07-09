import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
        title: const Text('用户协议', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
        ),
      ),
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
