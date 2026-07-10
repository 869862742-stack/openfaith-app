import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  String _fontSize = 'standard';
  bool _saving = false;

  static const _fontSizes = [
    {'id': 'small', 'label': '小', 'desc': '12px / 14px'},
    {'id': 'standard', 'label': '标准', 'desc': '14px / 16px'},
    {'id': 'large', 'label': '大', 'desc': '16px / 18px'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final size = prefs.getString('font_size') ?? 'standard';
    if (mounted) setState(() => _fontSize = size);
  }

  Future<void> _setFontSize(String size) async {
    setState(() {
      _fontSize = size;
      _saving = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('font_size', size);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'font_size': size}).eq('user_id', userId);
      }
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  double _previewTitleSize() {
    switch (_fontSize) {
      case 'small':
        return 14;
      case 'large':
        return 18;
      default:
        return 16;
    }
  }

  double _previewTextSize() {
    switch (_fontSize) {
      case 'small':
        return 12;
      case 'large':
        return 16;
      default:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('显示设置',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('字体大小',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: _fontSizes.map((s) {
                final isSelected = _fontSize == s['id'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _setFontSize(s['id'] as String),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isSelected
                            ? AppColors.auroraGradient
                            : null,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          color: isSelected
                              ? AppColors.bgColor
                              : AppColors.hoverBgLight,
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: AppColors.borderColor),
                        ),
                        child: Column(
                          children: [
                            Text(s['label'] as String,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(s['desc'] as String,
                                style: const TextStyle(
                                    color: AppColors.textWeak,
                                    fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            // Preview card with gradient border
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.auroraGradientWithOpacity(0.6),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: AppColors.bgColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.text_fields,
                            color: AppColors.textPrimary, size: 16),
                        SizedBox(width: 8),
                        Text('预览效果',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.hoverBgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('预览标题',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: _previewTitleSize(),
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            '这是一段预览文本，用于展示当前字体大小效果。OpenFaith - 探索灵性世界。',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: _previewTextSize(),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  gradient: AppColors.auroraGradient,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(19),
                                    color: AppColors.bgColor,
                                  ),
                                  child: const Text('确认',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(20),
                                  color: AppColors.inputBg,
                                  border: Border.all(
                                      color: AppColors.borderColor),
                                ),
                                child: Text('取消',
                                    style: TextStyle(
                                        color: AppColors.textWeak,
                                        fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
