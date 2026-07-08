import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _rainbowGradient = LinearGradient(
    colors: [
      Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),
      Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
    ],
  transform: GradientRotation(0.35),
  );

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
        title: const Text('\u9690\u79c1\u653f\u7b56', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('\u5f15\u8a00', [
              'OpenFaith\uff08\u201c\u6211\u4eec\u201d\u6216\u201c\u672c\u5e73\u53f0\u201d\uff09\u91cd\u89c6\u7528\u6237\u7684\u9690\u79c1\u4fdd\u62a4\u3002\u672c\u9690\u79c1\u653f\u7b56\u8bf4\u660e\u6211\u4eec\u5982\u4f55\u6536\u96c6\u3001\u4f7f\u7528\u3001\u5b58\u50a8\u548c\u4fdd\u62a4\u60a8\u7684\u4e2a\u4eba\u4fe1\u606f\u3002',
              '\u4f7f\u7528\u672c\u5e73\u53f0\u5373\u8868\u793a\u60a8\u540c\u610f\u672c\u653f\u7b56\u7684\u5185\u5bb9\u3002',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u4fe1\u606f\u6536\u96c6', [
              '\u6211\u4eec\u53ef\u80fd\u6536\u96c6\u4ee5\u4e0b\u7c7b\u578b\u7684\u4fe1\u606f\uff1a',
              '\u2022 \u8d26\u6237\u4fe1\u606f\uff1a\u90ae\u7bb1\u5730\u5740\u3001\u7528\u6237\u540d\u3001\u5bc6\u7801\uff08\u52a0\u5bc6\u5b58\u50a8\uff09\u3001\u5934\u50cf\u3001\u4e2a\u4eba\u7b80\u4ecb',
              '\u2022 \u5185\u5bb9\u4fe1\u606f\uff1a\u60a8\u53d1\u5e03\u7684\u6587\u5b57\u3001\u56fe\u7247\u3001\u89c6\u9891\u3001\u8bc4\u8bba\u7b49\u5185\u5bb9',
              '\u2022 \u4ea4\u6d41\u4fe1\u606f\uff1a\u79c1\u4fe1\u3001\u7fa4\u804a\u6d88\u606f\u3001\u597d\u53cb\u5173\u7cfb',
              '\u2022 \u8bbe\u5907\u4fe1\u606f\uff1a\u8bbe\u5907\u578b\u53f7\u3001\u64cd\u4f5c\u7cfb\u7edf\u7248\u672c\u3001\u552f\u4e00\u8bbe\u5907\u6807\u8bc6',
              '\u2022 \u4f7f\u7528\u6570\u636e\uff1a\u8bbf\u95ee\u65f6\u95f4\u3001\u6d4f\u89c8\u8bb0\u5f55\u3001\u504f\u597d\u8bbe\u7f6e',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u4fe1\u606f\u4f7f\u7528', [
              '\u6211\u4eec\u4f7f\u7528\u6536\u96c6\u7684\u4fe1\u606f\u7528\u4e8e\uff1a',
              '\u2022 \u63d0\u4f9b\u3001\u7ef4\u62a4\u548c\u6539\u5584\u5e73\u53f0\u670d\u52a1',
              '\u2022 \u4e2a\u6027\u5316\u5185\u5bb9\u63a8\u8350',
              '\u2022 \u5b89\u5168\u9a8c\u8bc1\u548c\u9632\u6b3a\u8bc8',
              '\u2022 \u53d1\u9001\u670d\u52a1\u901a\u77e5\u548c\u66f4\u65b0\u63d0\u793a',
              '\u2022 \u9075\u5b88\u6cd5\u5f8b\u6cd5\u89c4\u8981\u6c42',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u4fe1\u606f\u5171\u4eab', [
              '\u6211\u4eec\u4e0d\u4f1a\u5411\u7b2c\u4e09\u65b9\u51fa\u552e\u60a8\u7684\u4e2a\u4eba\u4fe1\u606f\u3002\u4ee5\u4e0b\u60c5\u51b5\u9664\u5916\uff1a',
              '\u2022 \u83b7\u5f97\u60a8\u7684\u660e\u786e\u540c\u610f',
              '\u2022 \u4e3a\u5c65\u884c\u6cd5\u5f8b\u4e49\u52a1\u6216\u54cd\u5e94\u6cd5\u5f8b\u7a0b\u5e8f',
              '\u2022 \u4fdd\u62a4\u5e73\u53f0\u53ca\u7528\u6237\u7684\u6743\u5229\u548c\u5b89\u5168',
              '\u2022 \u4e0e\u7ecf\u6388\u6743\u7684\u670d\u52a1\u63d0\u4f9b\u5546\u5171\u4eab\uff08\u5982\u4e91\u5b58\u50a8\u670d\u52a1\uff09',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u6570\u636e\u5b58\u50a8\u4e0e\u5b89\u5168', [
              '\u2022 \u60a8\u7684\u6570\u636e\u5b58\u50a8\u5728\u5b89\u5168\u7684\u4e91\u670d\u52a1\u5668\u4e0a',
              '\u2022 \u5bc6\u7801\u7ecf\u8fc7\u52a0\u5bc6\u5904\u7406\u540e\u5b58\u50a8\uff0c\u6211\u4eec\u65e0\u6cd5\u67e5\u770b\u60a8\u7684\u539f\u59cb\u5bc6\u7801',
              '\u2022 \u6211\u4eec\u91c7\u7528\u884c\u4e1a\u6807\u51c6\u7684\u5b89\u5168\u63aa\u65bd\u4fdd\u62a4\u60a8\u7684\u6570\u636e',
              '\u2022 \u60a8\u53ef\u4ee5\u968f\u65f6\u8bf7\u6c42\u5220\u9664\u60a8\u7684\u8d26\u6237\u53ca\u76f8\u5173\u6570\u636e',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u60a8\u7684\u6743\u5229', [
              '\u2022 \u8bbf\u95ee\u548c\u66f4\u65b0\u60a8\u7684\u4e2a\u4eba\u4fe1\u606f',
              '\u2022 \u5220\u9664\u60a8\u7684\u8d26\u6237\u548c\u6570\u636e',
              '\u2022 \u64a4\u56de\u540c\u610f\uff08\u4e0d\u5f71\u54cd\u64a4\u56de\u524d\u7684\u5904\u7406\uff09',
              '\u2022 \u6295\u8bc9\u548c\u4e3e\u62a5',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u672a\u6210\u5e74\u4eba\u4fdd\u62a4', [
              '\u672c\u5e73\u53f0\u4e0d\u5411\u672a\u6ee113\u5468\u5c81\u7684\u513f\u7ae5\u63d0\u4f9b\u670d\u52a1\u3002\u6211\u4eec\u4e0d\u4f1a\u6545\u610f\u6536\u96c6\u672a\u6210\u5e74\u4eba\u7684\u4e2a\u4eba\u4fe1\u606f\u3002',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u653f\u7b56\u66f4\u65b0', [
              '\u6211\u4eec\u53ef\u80fd\u5b9a\u671f\u66f4\u65b0\u672c\u9690\u79c1\u653f\u7b56\u3002\u91cd\u5927\u53d8\u66f4\u65f6\uff0c\u6211\u4eec\u4f1a\u901a\u8fc7\u5e73\u53f0\u901a\u77e5\u60a8\u3002',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u8054\u7cfb\u6211\u4eec', [
              '\u5982\u6709\u5173\u4e8e\u9690\u79c1\u653f\u7b56\u7684\u95ee\u9898\uff0c\u8bf7\u901a\u8fc7\u5e73\u53f0\u5185\u7684\u53cd\u9988\u529f\u80fd\u8054\u7cfb\u6211\u4eec\u3002',
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
