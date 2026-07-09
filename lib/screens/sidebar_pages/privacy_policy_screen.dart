import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: const Text('隐私政策', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('OpenFaith 隐私政策', [
              '最后更新日期：2026年4月24日',
              '',
              '我们深知个人信息对您的重要性，并会尽全力保护您的个人信息安全。本政策将帮助您了解我们如何收集、使用、存储和共享您的信息。',
            ]),
            const SizedBox(height: 16),
            _buildSection('1. 我们收集的信息', [
              '注册信息：邮箱地址或手机号码、用户名、身份标签（信仰标签）。',
              '个人资料：头像、昵称、简介、背景图（您自愿提供）。',
              '内容信息：您发布的笔记、评论、图片、视频、学习计划。',
              '互动信息：点赞、收藏、关注、私信、举报等互动记录。',
              '设备与日志信息：IP地址、设备型号、操作系统版本、应用版本、崩溃日志。',
            ]),
            const SizedBox(height: 16),
            _buildSection('2. 我们如何使用信息', [
              '提供、维护、改进我们的服务；',
              '个性化推荐内容（基于您的兴趣标签）；',
              '处理您的客服工单和反馈；',
              '防止欺诈和保障账号安全；',
              '遵守法律义务。',
            ]),
            const SizedBox(height: 16),
            _buildSection('3. 信息共享与披露', [
              '我们不会向第三方出售您的个人信息。仅在以下情况共享：',
              '经您明确同意；',
              '根据法律法规、法律程序或政府要求；',
              '与我们的服务提供商（如云存储、数据分析）合作，但仅限服务于本应用。',
            ]),
            const SizedBox(height: 16),
            _buildSection('4. 数据安全与存储', [
              '我们采用行业标准的安全措施保护您的信息。但请注意，绝对安全并不存在。您的数据将存储于位于香港、新加坡或欧盟的服务器，具体根据用户所在地优化。',
            ]),
            const SizedBox(height: 16),
            _buildSection('5. 您的权利', [
              '依据GDPR及类似法律，您有权：访问、更正、删除您的个人信息；限制或反对某些处理；数据可携权；撤回同意；向监管机构投诉。',
              '',
              '您可以在应用内"设置-账号与安全"中修改大部分信息，或通过 hello@openfaithhub.com 提交删除请求。',
            ]),
            const SizedBox(height: 16),
            _buildSection('6. 未成年人保护', [
              '我们的服务主要面向成年人。如您是未成年人，请在监护人同意下使用。我们不会故意收集未成年人信息。',
            ]),
            const SizedBox(height: 16),
            _buildSection('7. 国际传输', [
              '由于我们服务全球用户，您的信息可能会被传输到您所在国家/地区以外的服务器。我们会采取适当保障措施（如标准合同条款）。',
            ]),
            const SizedBox(height: 16),
            _buildSection('8. 政策更新', [
              '我们可能更新本隐私政策，重大变更将通过应用内通知或电子邮件告知。',
            ]),
            const SizedBox(height: 16),
            _buildSection('9. 联系我们', [
              '数据保护负责人：hello@openfaithhub.com',
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
