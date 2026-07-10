import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _currentLang = 'zh';
  bool _saving = false;

  final List<Map<String, String>> _languages = [
    {'code': 'zh', 'name': '\u7b80\u4f53\u4e2d\u6587', 'native': '\u7b80\u4f53\u4e2d\u6587', 'flag': '\u{1F1E8}\u{1F1F3}'},
    {'code': 'zh-TW', 'name': '\u7e41\u9ad4\u4e2d\u6587', 'native': '\u7e41\u9ad4\u4e2d\u6587', 'flag': '\u{1F1E8}\u{1F1F3}'},
    {'code': 'en', 'name': '\u82f1\u6587', 'native': 'English', 'flag': '\u{1F1FA}\u{1F1F8}'},
    {'code': 'ja', 'name': '\u65e5\u672c\u8a9e', 'native': '\u65e5\u672c\u8a9e', 'flag': '\u{1F1EF}\u{1F1F5}'},
    {'code': 'ko', 'name': '\ud55c\uad6d\uc5b4', 'native': '\ud55c\uad6d\uc5b4', 'flag': '\u{1F1F0}\u{1F1F7}'},
    {'code': 'es', 'name': 'Espa\u00f1ol', 'native': 'Espa\u00f1ol', 'flag': '\u{1F1EA}\u{1F1F8}'},
    {'code': 'fr', 'name': 'Fran\u00e7ais', 'native': 'Fran\u00e7ais', 'flag': '\u{1F1EB}\u{1F1F7}'},
    {'code': 'de', 'name': 'Deutsch', 'native': 'Deutsch', 'flag': '\u{1F1E9}\u{1F1EA}'},
    {'code': 'pt', 'name': 'Portugu\u00eas', 'native': 'Portugu\u00eas', 'flag': '\u{1F1E7}\u{1F1F7}'},
    {'code': 'ru', 'name': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439', 'native': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439', 'flag': '\u{1F1F7}\u{1F1FA}'},
    {'code': 'ar', 'name': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629', 'native': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629', 'flag': '\u{1F1F8}\u{1F1E6}'},
    {'code': 'hi', 'name': '\u0939\u093f\u0928\u094d\u0926\u0940', 'native': '\u0939\u093f\u0928\u094d\u0926\u0940', 'flag': '\u{1F1EE}\u{1F1F3}'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentLang();
  }

  Future<void> _loadCurrentLang() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final resp = await Supabase.instance.client
          .from('profiles')
          .select('language')
          .eq('id', user.id)
          .maybeSingle();
      if (resp != null && resp['language'] != null) {
        if (mounted) setState(() => _currentLang = resp['language'] as String);
      }
    }
  }

  Widget _buildLangRow(Map<String, String> lang) {
    return Row(
      children: [
        Text(lang['flag'] ?? '',
            style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lang['native']!,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Text(lang['name']!,
                  style: const TextStyle(
                      color: AppColors.textWeak,
                      fontSize: 12)),
            ],
          ),
        ),
        if (lang['code'] == _currentLang)
          const Icon(Icons.check,
              color: AppColors.textPrimary, size: 20),
      ],
    );
  }

  Future<void> _saveLang(String code) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _currentLang = code;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'language': code})
            .eq('id', user.id);
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

  @override
  Widget build(BuildContext context) {
    final currentLang = _languages.firstWhere(
      (l) => l['code'] == _currentLang,
      orElse: () => _languages[0],
    );

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        elevation: 0,
        title: const Text('\u8bed\u8a00\u8bbe\u7f6e',
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
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Current language card
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.hoverBgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.language,
                          color: AppColors.textPrimary, size: 16),
                      SizedBox(width: 8),
                      Text('\u5f53\u524d\u8bed\u8a00',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 14)),
                    ],
                  ),
                ),
                // Language list
                ..._languages.map((lang) {
                  final isSelected = lang['code'] == _currentLang;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => _saveLang(lang['code']!),
                      child: isSelected
                          ? Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: AppColors.auroraGradient,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: AppColors.bgColor,
                                ),
                                child: _buildLangRow(lang),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.hoverBgLight,
                                border: Border.all(color: AppColors.borderColor),
                              ),
                              child: _buildLangRow(lang),
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                // Hint text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.hoverBgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.borderSubtle),
                  ),
                  child: Center(
                    child: Text('\u8bed\u8a00\u5207\u6362\u540e\u7acb\u5373\u751f\u6548',
                        style: TextStyle(
                            color: AppColors.textWeak, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Loading indicator
          if (_saving)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.overlayBg,
                border: Border(top: BorderSide(color: AppColors.borderColor)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('\u6b63\u5728\u5207\u6362\u8bed\u8a00...',
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
