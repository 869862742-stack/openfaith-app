import 'package:flutter/material.dart';
import 'dart:math';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _rainbowColors = [
    Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),
    Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
  ];

  LinearGradient _diagonalGradient(Size size) {
    final angle = size.height > 0 && size.width > 0 ? atan2(size.width, size.height) : 0.785;
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(angle));
  }

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
            _buildSection('引言', [
              'OpenFaith（"我们"或"本平台"）重视用户的隐私保护。本隐私政策说明我们如何收集、使用、存储和保护您的个人信息。',
              '使用本平台即表示您同意本政策的内容。',
            ]),
            const SizedBox(height: 16),
            _buildSection('信息收集', [
              '我们可能收集以下类型的信息：',
              '• 账户信息：邮箱地址、用户名、密码（加密存储）、头像、个人简介',
              '• 内容信息：您发布的文字、图片、视频、评论等内容',
              '• 交流信息：私信、群聊消息、好友关系',
              '• 设备信息：设备型号、操作系统版本、唯一设备标识',
              '• 使用数据：访问时间、浏览记录、偏好设置',
            ]),
            const SizedBox(height: 16),
            _buildSection('信息使用', [
              '我们使用收集的信息用于：',
              '• 提供、维护和改善平台服务',
              '• 个性化内容推荐',
              '• 安全验证和防欺诈',
              '• 发送服务通知和更新提示',
              '• 遵守法律法规要求',
            ]),
            const SizedBox(height: 16),
            _buildSection('信息共享', [
              '我们不会向第三方出售您的个人信息。以下情况除外：',
              '• 获得您的明确同意',
              '• 为履行法律义务或响应法律程序',
              '• 保护平台及用户的权利和安全',
              '• 与经授权的服务提供商共享（如云存储服务）',
            ]),
            const SizedBox(height: 16),
            _buildSection('数据存储与安全', [
              '• 您的数据存储在安全的云服务器上',
              '• 密码经过加密处理后存储，我们无法查看您的原始密码',
              '• 我们采用行业标准的安全措施保护您的数据',
              '• 您可以随时请求删除您的账户及相关数据',
            ]),
            const SizedBox(height: 16),
            _buildSection('您的权利', [
              '• 访问和更新您的个人信息',
              '• 删除您的账户和数据',
              '• 撤回同意（不影响撤回前的处理）',
              '• 投诉和举报',
            ]),
            const SizedBox(height: 16),
            _buildSection('未成年人保护', [
              '本平台不向未满13周岁的儿童提供服务。我们不会故意收集未成年人的个人信息。',
            ]),
            const SizedBox(height: 16),
            _buildSection('政策更新', [
              '我们可能定期更新本隐私政策。重大变更时，我们会通过平台通知您。',
            ]),
            const SizedBox(height: 16),
            _buildSection('联系我们', [
              '如有关于隐私政策的问题，请通过平台内的反馈功能联系我们。',
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
