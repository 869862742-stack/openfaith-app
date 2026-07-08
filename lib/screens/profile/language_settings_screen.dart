import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _currentLang = 'zh';
  bool _saving = false;

  final List<Map<String, String>> _languages = [
    {'code': 'zh', 'name': '\u7b80\u4f53\u4e2d\u6587', 'native': '\u7b80\u4f53\u4e2d\u6587'},
    {'code': 'zh-TW', 'name': '\u7e41\u9ad4\u4e2d\u6587', 'native': '\u7e41\u9ad4\u4e2d\u6587'},
    {'code': 'en', 'name': '英文', 'native': 'English'},
    {'code': 'ja', 'name': '\u65e5\u672c\u8a9e', 'native': '\u65e5\u672c\u8a9e'},
    {'code': 'ko', 'name': '\ud55c\uad6d\uc5b4', 'native': '\ud55c\uad6d\uc5b4'},
    {'code': 'es', 'name': 'Espa\u00f1ol', 'native': 'Espa\u00f1ol'},
    {'code': 'fr', 'name': 'Fran\u00e7ais', 'native': 'Fran\u00e7ais'},
    {'code': 'de', 'name': 'Deutsch', 'native': 'Deutsch'},
    {'code': 'pt', 'name': 'Portugu\u00eas', 'native': 'Portugu\u00eas'},
    {'code': 'ru', 'name': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439', 'native': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439'},
    {'code': 'ar', 'name': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629', 'native': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629'},
    {'code': 'hi', 'name': '\u0939\u093f\u0928\u094d\u0926\u0940', 'native': '\u0939\u093f\u0928\u094d\u0926\u0940'},
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

  Future<void> _saveLang(String code) async {
    if (_saving) return;
    setState(() { _saving = true; _currentLang = code; });
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
        title: const Text('\u8bed\u8a00\u8bbe\u7f6e', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _languages.length,
        separatorBuilder: (_, __) => Container(height: 1, color: Colors.white.withOpacity(0.06)),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final isSelected = lang['code'] == _currentLang;
          return GestureDetector(
            onTap: () => _saveLang(lang['code']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lang['native']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: _rainbowGradient,
                      ),
                      child: const Icon(Icons.check, size: 16, color: Colors.white),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
