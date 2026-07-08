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
        title: const Text('\u670d\u52a1\u6761\u6b3e', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('\u5f15\u8a00', [
              '\u6b22\u8fce\u4f7f\u7528 OpenFaith\u3002\u901a\u8fc7\u4f7f\u7528\u672c\u5e73\u53f0\uff0c\u60a8\u540c\u610f\u9075\u5b88\u4ee5\u4e0b\u670d\u52a1\u6761\u6b3e\u3002\u8bf7\u4ed4\u7ec6\u9605\u8bfb\u3002',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u8d26\u6237\u6ce8\u518c\u4e0e\u5b89\u5168', [
              '\u2022 \u60a8\u5fc5\u987b\u63d0\u4f9b\u771f\u5b9e\u3001\u51c6\u786e\u7684\u6ce8\u518c\u4fe1\u606f',
              '\u2022 \u60a8\u6709\u8d23\u4efb\u7ef4\u62a4\u8d26\u6237\u5b89\u5168\uff0c\u4fdd\u7ba1\u597d\u5bc6\u7801',
              '\u2022 \u60a8\u5bf9\u8d26\u6237\u4e0b\u7684\u6240\u6709\u6d3b\u52a8\u8d1f\u8d23',
              '\u2022 \u53d1\u73b0\u672a\u6388\u6743\u4f7f\u7528\u8bf7\u7acb\u5373\u901a\u77e5\u6211\u4eec',
              '\u2022 \u6bcf\u4e2a\u7528\u6237\u53ea\u80fd\u6ce8\u518c\u4e00\u4e2a\u8d26\u6237',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u7528\u6237\u884c\u4e3a\u89c4\u8303', [
              '\u60a8\u540c\u610f\u4e0d\u4f1a\u5229\u7528\u672c\u5e73\u53f0\uff1a',
              '\u2022 \u53d1\u5e03\u8fdd\u6cd5\u3001\u6709\u5bb3\u3001\u5a01\u80c1\u3001\u4fb5\u6743\u7684\u5185\u5bb9',
              '\u2022 \u4fb5\u72af\u4ed6\u4eba\u77e5\u8bc6\u4ea7\u6743\u3001\u9690\u79c1\u6216\u5176\u4ed6\u6743\u5229',
              '\u2022 \u53d1\u5e03\u5783\u573e\u4fe1\u606f\u3001\u5e7f\u544a\u6216\u6076\u610f\u5185\u5bb9',
              '\u2022 \u5e72\u6270\u3001\u9a9a\u6270\u6216\u5a01\u80c1\u5176\u4ed6\u7528\u6237',
              '\u2022 \u8bd5\u56fe\u7834\u574f\u6216\u5f71\u54cd\u5e73\u53f0\u6b63\u5e38\u8fd0\u884c',
              '\u2022 \u4f7f\u7528\u81ea\u52a8\u5316\u5de5\u5177\u6216\u722c\u866b\u8bbf\u95ee\u5e73\u53f0',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u5185\u5bb9\u4e0e\u77e5\u8bc6\u4ea7\u6743', [
              '\u2022 \u60a8\u4fdd\u7559\u60a8\u53d1\u5e03\u5185\u5bb9\u7684\u77e5\u8bc6\u4ea7\u6743',
              '\u2022 \u901a\u8fc7\u53d1\u5e03\u5185\u5bb9\uff0c\u60a8\u6388\u4e88\u5e73\u53f0\u5168\u7403\u8303\u56f4\u5185\u7684\u3001\u514d\u8d39\u7684\u3001\u4e0d\u53ef\u8f6c\u8ba9\u7684\u4f7f\u7528\u8bb8\u53ef',
              '\u2022 \u5e73\u53f0\u6709\u6743\u5220\u9664\u8fdd\u53cd\u89c4\u5219\u7684\u5185\u5bb9',
              '\u2022 \u60a8\u5e94\u786e\u4fdd\u53d1\u5e03\u7684\u5185\u5bb9\u4e0d\u4fb5\u72af\u4ed6\u4eba\u6743\u5229',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u5e73\u53f0\u670d\u52a1', [
              '\u2022 \u6211\u4eec\u6709\u6743\u4fee\u6539\u6216\u7ec8\u6b62\u670d\u52a1\uff08\u5168\u90e8\u6216\u90e8\u5206\uff09',
              '\u2022 \u6211\u4eec\u4e0d\u4fdd\u8bc1\u670d\u52a1\u5c06\u59cb\u7ec8\u4e0d\u4e2d\u65ad\u3001\u53ca\u65f6\u6216\u65e0\u9519\u8bef',
              '\u2022 VIP \u529f\u80fd\u4e3a\u4ed8\u8d39\u670d\u52a1\uff0c\u5177\u4f53\u4ee5\u5e73\u53f0\u5c55\u793a\u4e3a\u51c6',
              '\u2022 \u4ed8\u8d39\u670d\u52a1\u4e00\u7ecf\u8d2d\u4e70\uff0c\u9664\u6cd5\u5f8b\u89c4\u5b9a\u5916\u4e0d\u4e88\u9000\u6b3e',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u8d23\u4efb\u9650\u5236', [
              '\u2022 \u672c\u5e73\u53f0\u6309\u201c\u73b0\u72b6\u201d\u548c\u201c\u53ef\u7528\u201d\u57fa\u7840\u63d0\u4f9b\u670d\u52a1',
              '\u2022 \u6211\u4eec\u4e0d\u5bf9\u7528\u6237\u53d1\u5e03\u7684\u5185\u5bb9\u627f\u62c5\u8d23\u4efb',
              '\u2022 \u5728\u6cd5\u5f8b\u5141\u8bb8\u7684\u8303\u56f4\u5185\uff0c\u6211\u4eec\u4e0d\u627f\u62c5\u95f4\u63a5\u3001\u5076\u7136\u6216\u60e9\u7f5a\u6027\u635f\u5bb3\u8d54\u507f',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u8d26\u6237\u7ec8\u6b62', [
              '\u2022 \u60a8\u53ef\u4ee5\u968f\u65f6\u5220\u9664\u60a8\u7684\u8d26\u6237',
              '\u2022 \u6211\u4eec\u6709\u6743\u5728\u8fdd\u53cd\u6761\u6b3e\u65f6\u7ec8\u6b62\u6216\u6682\u505c\u60a8\u7684\u8d26\u6237',
              '\u2022 \u8d26\u6237\u7ec8\u6b62\u540e\uff0c\u76f8\u5173\u5185\u5bb9\u53ef\u80fd\u65e0\u6cd5\u6062\u590d',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u6761\u6b3e\u4fee\u6539', [
              '\u6211\u4eec\u6709\u6743\u968f\u65f6\u4fee\u6539\u672c\u6761\u6b3e\u3002\u4fee\u6539\u540e\u7684\u6761\u6b3e\u5c06\u5728\u5e73\u53f0\u4e0a\u516c\u5e03\uff0c\u7ee7\u7eed\u4f7f\u7528\u5373\u8868\u793a\u63a5\u53d7\u3002',
            ]),
            const SizedBox(height: 16),
            _buildSection('\u8054\u7cfb\u6211\u4eec', [
              '\u5982\u5bf9\u670d\u52a1\u6761\u6b3e\u6709\u7591\u95ee\uff0c\u8bf7\u901a\u8fc7\u5e73\u53f0\u5185\u7684\u53cd\u9988\u529f\u80fd\u8054\u7cfb\u6211\u4eec\u3002',
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
