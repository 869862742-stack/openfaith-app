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
            _buildSection('引言', [
              '欢迎使用 OpenFaith。通过使用本平台，您同意遵守以下用户协议。请仔细阅读。',
            ]),
            const SizedBox(height: 16),
            _buildSection('账户注册与安全', [
              '• 您必须提供真实、准确的注册信息',
              '• 您有责任维护账户安全，保管好密码',
              '• 您对账户下的所有活动负责',
              '• 发现未授权使用请立即通知我们',
              '• 每个用户只能注册一个账户',
            ]),
            const SizedBox(height: 16),
            _buildSection('用户行为规范', [
              '您同意不会利用本平台：',
              '• 发布违法、有害、威胁、侵权的内容',
              '• 侵犯他人知识产权、隐私或其他权利',
              '• 发布垃圾信息、广告或恶意内容',
              '• 干扰、骚扰或威胁其他用户',
              '• 试图破坏或影响平台正常运行',
              '• 使用自动化工具或爬虫访问平台',
            ]),
            const SizedBox(height: 16),
            _buildSection('内容与知识产权', [
              '• 您保留您发布内容的知识产权',
              '• 通过发布内容，您授予平台全球范围内的、免费的、不可转让的使用许可',
              '• 平台有权删除违反规则的内容',
              '• 您应确保发布的内容不侵犯他人权利',
            ]),
            const SizedBox(height: 16),
            _buildSection('平台服务', [
              '• 我们有权修改或终止服务（全部或部分）',
              '• 我们不保证服务将始终不中断、及时或无错误',
              '• VIP 功能为付费服务，具体以平台展示为准',
              '• 付费服务一经购买，除法律规定外不予退款',
            ]),
            const SizedBox(height: 16),
            _buildSection('责任限制', [
              '• 本平台按"现状"和"可用"基础提供服务',
              '• 我们不对用户发布的内容承担责任',
              '• 在法律允许的范围内，我们不承担间接、偶然或惩罚性损害赔偿',
            ]),
            const SizedBox(height: 16),
            _buildSection('账户终止', [
              '• 您可以随时删除您的账户',
              '• 我们有权在违反条款时终止或暂停您的账户',
              '• 账户终止后，相关内容可能无法恢复',
            ]),
            const SizedBox(height: 16),
            _buildSection('条款修改', [
              '我们有权随时修改本条款。修改后的条款将在平台上公布，继续使用即表示接受。',
            ]),
            const SizedBox(height: 16),
            _buildSection('联系我们', [
              '如对用户协议有疑问，请通过平台内的反馈功能联系我们。',
              '联系邮箱：869862742@qq.com',
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
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        )),
      ],
    );
  }
}
