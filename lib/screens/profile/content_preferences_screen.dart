import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
import '../../theme/app_colors.dart';

class ContentPreferencesScreen extends StatefulWidget {
  const ContentPreferencesScreen({super.key});

  @override
  State<ContentPreferencesScreen> createState() => _ContentPreferencesScreenState();
}

class _ContentPreferencesScreenState extends State<ContentPreferencesScreen> {
  Set<String> _preferredTags = {};
  Set<String> _blockedTags = {};
  bool _loading = true;
  bool _saving = false;
  bool _showAddPreferred = false;
  bool _showAddBlocked = false;

  static const _allTags = [
    '\u7948\u7977', '\u8bfb\u7ecf', '\u8d5e\u7f8e', '\u5e03\u9053', '\u795e\u5b66',
    '\u6559\u4f1a\u751f\u6d3b', '\u5723\u7ecf\u7814\u7a76', '\u6559\u4f1a\u5386\u53f2',
    '\u5fc3\u7406\u5065\u5eb7', '\u60c5\u7eea\u7ba1\u7406', '\u81ea\u6211\u6210\u957f', '\u4eba\u9645\u5173\u7cfb',
    '\u5a5a\u59fb\u5bb6\u5ead', '\u80b2\u513f\u7ecf\u9a8c',
    '\u97f3\u4e50', '\u7535\u5f71', '\u8bfb\u4e66', '\u7ed8\u753b', '\u6444\u5f71',
    '\u65c5\u884c', '\u7f8e\u98df',
    '\u79d1\u6280', '\u5b66\u4e60', '\u521b\u4e1a', '\u804c\u573a', '\u8d22\u7ecf',
  ];

  final Map<String, List<String>> _tagGroups = {
    '\u57fa\u7763\u6559': const [
      '\u7948\u7977', '\u8bfb\u7ecf', '\u8d5e\u7f8e', '\u5e03\u9053', '\u795e\u5b66',
      '\u6559\u4f1a\u751f\u6d3b', '\u5723\u7ecf\u7814\u7a76', '\u6559\u4f1a\u5386\u53f2',
    ],
    '\u5fc3\u7406\u6210\u957f': const [
      '\u5fc3\u7406\u5065\u5eb7', '\u60c5\u7eea\u7ba1\u7406', '\u81ea\u6211\u6210\u957f', '\u4eba\u9645\u5173\u7cfb',
      '\u5a5a\u59fb\u5bb6\u5ead', '\u80b2\u513f\u7ecf\u9a8c',
    ],
    '\u6587\u5316\u827a\u672f': const [
      '\u97f3\u4e50', '\u7535\u5f71', '\u8bfb\u4e66', '\u7ed8\u753b', '\u6444\u5f71',
      '\u65c5\u884c', '\u7f8e\u98df',
    ],
    '\u79d1\u6280\u5b66\u4e60': const [
      '\u79d1\u6280', '\u5b66\u4e60', '\u521b\u4e1a', '\u804c\u573a', '\u8d22\u7ecf',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final resp = await Supabase.instance.client
            .from('profiles')
            .select('preferred_tags, blocked_tags')
            .eq('id', user.id)
            .maybeSingle();
        if (resp != null) {
          if (resp['preferred_tags'] != null) {
            final tags = (resp['preferred_tags'] as List).cast<String>();
            if (mounted) setState(() => _preferredTags = tags.toSet());
          }
          if (resp['blocked_tags'] != null) {
            final tags = (resp['blocked_tags'] as List).cast<String>();
            if (mounted) setState(() => _blockedTags = tags.toSet());
          }
        }
      }
    } catch (e) { debugPrint('加载内容偏好设置失败: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({
              'preferred_tags': _preferredTags.toList(),
              'blocked_tags': _blockedTags.toList(),
            })
            .eq('id', user.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u5df2\u4fdd\u5b58'),
            backgroundColor: AppColors.inputBg,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('\u4fdd\u5b58\u5931\u8d25: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  void _addPreferredTag(String tag) {
    setState(() {
      _preferredTags.add(tag);
      _showAddPreferred = false;
    });
  }

  void _removePreferredTag(String tag) {
    setState(() => _preferredTags.remove(tag));
  }

  void _addBlockedTag(String tag) {
    setState(() {
      _blockedTags.add(tag);
      _showAddBlocked = false;
    });
  }

  void _removeBlockedTag(String tag) {
    setState(() => _blockedTags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        elevation: 0,
        title: const Text('\u5185\u5bb9\u504f\u597d',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderColor),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.textWeak))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPreferredCard(),
                  const SizedBox(height: 16),
                  _buildBlockedCard(),
                ],
              ),
            ),
      bottomSheet: _showAddPreferred
          ? _buildAddTagSheet(isPreferred: true)
          : _showAddBlocked
              ? _buildAddTagSheet(isPreferred: false)
              : null,
    );
  }

  Widget _buildGradientBorderCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppColors.auroraGradientWithOpacity(0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: AppColors.bgColor,
        ),
        child: child,
      ),
    );
  }

  Widget _buildSectionHeader(
      {required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: AppColors.auroraGradientWithOpacity(0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.6), fontSize: 12)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPreferredCard() {
    return _buildGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: '\u504f\u597d\u6807\u7b7e',
            subtitle: '\u6211\u4eec\u4f1a\u4e3a\u60a8\u4f18\u5148\u63a8\u8350\u60a8\u611f\u5174\u8da3\u7684\u5b66\u4e60\u5185\u5bb9',
          ),
          if (_preferredTags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _preferredTags.map((tag) {
                return _buildTagChip(
                  label: tag,
                  onRemove: () => _removePreferredTag(tag),
                  color: AppColors.hoverBg,
                  borderColor: AppColors.borderActive,
                  textColor: AppColors.textPrimary,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          GestureDetector(
            onTap: () => setState(() => _showAddPreferred = true),
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.transparent,
                ),
                gradient: AppColors.auroraGradientWithOpacity(0.6),
              ),
              child: Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: AppColors.bgColor,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppColors.textPrimary, size: 16),
                    SizedBox(width: 8),
                    Text('\u6dfb\u52a0\u504f\u597d',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedCard() {
    return _buildGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: '\u5c4f\u853d\u6807\u7b7e',
            subtitle: '\u88ab\u5c4f\u853d\u7684\u6807\u7b7e\u5185\u5bb9\u5c06\u4e0d\u4f1a\u51fa\u73b0\u5728\u60a8\u7684\u63a8\u8350\u4e2d',
          ),
          if (_blockedTags.isEmpty)
            Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderColor,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Text('\u6682\u65e0\u5c4f\u853d\u6807\u7b7e',
                    style: TextStyle(
                        color: AppColors.textWeak, fontSize: 12)),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _blockedTags.map((tag) {
                return _buildTagChip(
                  label: tag,
                  onRemove: () => _removeBlockedTag(tag),
                  color: AppColors.hoverBgLight,
                  borderColor: AppColors.borderColor,
                  textColor: AppColors.textSecondary,
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _showAddBlocked = true),
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderActive),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, color: AppColors.textSecondary, size: 16),
                  SizedBox(width: 8),
                  Text('\u6dfb\u52a0\u5c4f\u853d',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip({
    required String label,
    required VoidCallback onRemove,
    required Color color,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      // 外层：彩虹渐变边框
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.auroraGradientWithOpacity(0.6),
      ),
      child: Container(
        // 内层：透明背景
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(color: textColor, fontSize: 12)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, color: textColor, size: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTagSheet({required bool isPreferred}) {
    final currentTags = isPreferred ? _preferredTags : _blockedTags;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.overlayBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isPreferred ? '\u6dfb\u52a0\u504f\u597d\u6807\u7b7e' : '\u6dfb\u52a0\u5c4f\u853d\u6807\u7b7e',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() {
                  _showAddPreferred = false;
                  _showAddBlocked = false;
                }),
                child: const Icon(Icons.close,
                    color: AppColors.textWeak, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('\u63a8\u8350\u6807\u7b7e',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _tagGroups.entries.map((entry) {
                  final availableTags = entry.value
                      .where((t) => !currentTags.contains(t))
                      .toList();
                  if (availableTags.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key,
                          style: TextStyle(
                              color: AppColors.textWeak,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableTags.map((tag) {
                          return GestureDetector(
                            onTap: () {
                              if (isPreferred) {
                                _addPreferredTag(tag);
                              } else {
                                _addBlockedTag(tag);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.hoverBgLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.borderColor, width: 0.5),
                              ),
                              child: Text(tag,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
