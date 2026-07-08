import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

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

  static const _allTags = [
    // \u57fa\u7763\u6559
    '\u7948\u7977', '\u8bfb\u7ecf', '\u8d5e\u7f8e', '\u5e03\u9053', '\u795e\u5b66',
    '\u6559\u4f1a\u751f\u6d3b', '\u5723\u7ecf\u7814\u7a76', '\u6559\u4f1a\u5386\u53f2',
    // \u5fc3\u7406\u6210\u957f
    '\u5fc3\u7406\u5065\u5eb7', '\u60c5\u7eea\u7ba1\u7406', '\u81ea\u6211\u6210\u957f', '\u4eba\u9645\u5173\u7cfb',
    '\u5a5a\u59fb\u5bb6\u5ead', '\u80b2\u513f\u7ecf\u9a8c',
    // \u6587\u5316\u827a\u672f
    '\u97f3\u4e50', '\u7535\u5f71', '\u8bfb\u4e66', '\u7ed8\u753b', '\u6444\u5f71',
    '\u65c5\u884c', '\u7f8e\u98df',
    // \u79d1\u6280\u5b66\u4e60
    '\u79d1\u6280', '\u5b66\u4e60', '\u521b\u4e1a', '\u804c\u573a', '\u8d22\u7ecf',
  ];

  // Groups for display
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
    } catch (_) {}
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
  }  static const _rainbowColors = [


    Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),


    Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
  ];

  LinearGradient _diagonalGradient(Size size) {
    final angle = size.height > 0 && size.width > 0 ? atan2(size.height, size.width) : 0.785;
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(angle));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        elevation: 0,
        title: const Text('\u5185\u5bb9\u504f\u597d', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white24))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // \u504f\u597d\u6807\u7b7e
                  const Text('\u6211\u611f\u5174\u8da3\u7684', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('\u9009\u62e9\u4f60\u611f\u5174\u8da3\u7684\u5185\u5bb9\u6807\u7b7e\uff0c\u6211\u4eec\u4f1a\u4f18\u5148\u63a8\u8350\u76f8\u5173\u5185\u5bb9',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  const SizedBox(height: 12),
                  ..._tagGroups.entries.map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.value.map((tag) => _buildTagChip(tag, false)).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      )),
                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.white.withOpacity(0.06)),
                  const SizedBox(height: 24),
                  // \u5c4f\u853d\u6807\u7b7e
                  const Text('\u6211\u4e0d\u60f3\u770b\u7684', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('\u9009\u62e9\u4f60\u4e0d\u60f3\u770b\u5230\u7684\u5185\u5bb9\u6807\u7b7e',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  const SizedBox(height: 12),
                  ..._tagGroups.entries.map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.value.map((tag) => _buildTagChip(tag, true)).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      )),
                  const SizedBox(height: 24),
                  // \u4fdd\u5b58\u6309\u94ae
                  GestureDetector(
                    onTap: _save,
                    child: LayoutBuilder(builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        return Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: _diagonalGradient(size),
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('\u4fdd\u5b58\u504f\u597d', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    );
                    }),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTagChip(String tag, bool isBlockedSection) {
    final isSelected = isBlockedSection ? _blockedTags.contains(tag) : _preferredTags.contains(tag);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isBlockedSection) {
            if (isSelected) { _blockedTags.remove(tag); } else { _blockedTags.add(tag); }
          } else {
            if (isSelected) { _preferredTags.remove(tag); } else { _preferredTags.add(tag); }
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? (isBlockedSection ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.12))
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: isSelected
                ? (isBlockedSection ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.3))
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
