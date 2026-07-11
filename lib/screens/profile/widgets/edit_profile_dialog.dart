import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';

/// 信仰标签候选列表
const List<String> kFaithTags = [
  '基督教', '伊斯兰教', '犹太教', '佛教', '印度教', '道教', '锡克教',
  '巴哈伊教', '摩门教', '耶和华见证人', '琐罗亚斯德教', '诺斯替',
  '卡巴拉', '神道教', '耆那教', '德鲁兹教', '约鲁巴教', '伏都教',
  '雅兹迪', '曼达安', '玛雅/阿兹特克', '毛利宗教', '天理教', '天道教',
  '高台教', '宗教研究者', '经文爱好者', '寻求者',
];

/// 头像颜色映射（默认头像）
const Map<String, Color> kAvatarColorMap = {
  'red': AppColors.auroraRed,
  'orange': AppColors.auroraOrange,
  'yellow': AppColors.auroraYellow,
  'green': AppColors.auroraGreen,
  'cyan': AppColors.auroraCyan,
  'blue': AppColors.auroraBlue,
  'purple': AppColors.auroraPurple,
};

/// 编辑资料弹窗
class EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onSaveSuccess;

  const EditProfileDialog({
    super.key,
    required this.profile,
    required this.onSaveSuccess,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nicknameCtrl;
  late TextEditingController _bioCtrl;
  late String _editFaithTag;
  String? _editAvatarUrl;
  String? _editBgUrl;
  bool _isSaving = false;
  String _editGender = "neutral";
  bool _showTagDropdown = false;
  bool _allowStrangerVisit = true;
  bool _allowFriendVisit = true;

  final _supabase = Supabase.instance.client;

  // ══════ 编辑次数限制 ══════
  late bool _isVip;
  late int _profileEditCount;
  late String _profileEditMonth;

  int get _remainingEditCount {
    if (_isVip) return -1; // VIP 无限制
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    if (_profileEditMonth != currentMonth) return 3;
    return (3 - _profileEditCount).clamp(0, 3);
  }

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nicknameCtrl = TextEditingController(text: p['nickname'] as String? ?? '');
    _bioCtrl = TextEditingController(text: p['bio'] as String? ?? '');
    _editFaithTag = p['faith_tag'] as String? ?? '寻求者';
    _editAvatarUrl = p['avatar_url'] as String?;
    _editBgUrl = p['background_url'] as String?;
    _editGender = (p['gender'] as String?) ?? 'neutral';
    _allowStrangerVisit = p['allow_stranger_visit'] != false;
    _allowFriendVisit = p['allow_friend_visit'] != false;
    _isVip = p['is_vip'] == true;
    _profileEditCount = (p['profile_edit_count'] as num?)?.toInt() ?? 0;
    _profileEditMonth = (p['profile_edit_month'] as String?) ?? '';
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  bool _canEditFaithTag() {
    final tagModified = widget.profile['tag_last_modified_at'] as String?;
    if (tagModified == null) return true;
    final lastModified = DateTime.tryParse(tagModified);
    if (lastModified == null) return true;
    final now = DateTime.now();
    return now.difference(lastModified).inDays >= 30;
  }

  int get _tagDaysAgo {
    final tagModified = widget.profile['tag_last_modified_at'] as String?;
    if (tagModified == null) return -1;
    final lastModified = DateTime.tryParse(tagModified);
    if (lastModified == null) return -1;
    return DateTime.now().difference(lastModified).inDays;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.cardBg),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.size > 2 * 1024 * 1024) {
        _showSnack('图片大小不能超过 2MB');
        return;
      }
      final filePath = file.path;
      if (filePath == null) return;
      final userId =
          widget.profile['user_id'] as String? ?? widget.profile['id'] as String?;
      final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await File(filePath).readAsBytes();
      await _supabase.storage.from('avatars').uploadBinary(fileName, fileBytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      if (!mounted) return;
      setState(() => _editAvatarUrl = publicUrl);
    } catch (e) {
      _showSnack('头像上传失败: $e');
    }
  }

  Future<void> _pickAndUploadBg() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.size > 2 * 1024 * 1024) {
        _showSnack('图片大小不能超过 2MB');
        return;
      }
      final filePath = file.path;
      if (filePath == null) return;
      final userId =
          widget.profile['user_id'] as String? ?? widget.profile['id'] as String?;
      final fileName = 'bg_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await File(filePath).readAsBytes();
      await _supabase.storage.from('backgrounds').uploadBinary(fileName, fileBytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      final publicUrl = _supabase.storage.from('backgrounds').getPublicUrl(fileName);
      if (!mounted) return;
      setState(() => _editBgUrl = publicUrl);
    } catch (e) {
      _showSnack('背景上传失败: $e');
    }
  }

  Future<void> _handleSave() async {
    if (_nicknameCtrl.text.trim().isEmpty) {
      _showSnack('昵称不能为空');
      return;
    }

    // ══ 编辑次数检查 ══
    if (!_isVip && _remainingEditCount <= 0) {
      _showSnack('本月编辑次数已达上限（3次），升级VIP可无限修改');
      return;
    }

    // ══ 信仰标签30天限制 ══
    final oldFaithTag = widget.profile['faith_tag'] as String? ?? '';
    if (_editFaithTag != oldFaithTag && !_canEditFaithTag()) {
      final daysAgo = _tagDaysAgo;
      _showSnack('身份标签修改间隔需至少30天，上次修改于 $daysAgo 天前');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId =
          widget.profile['user_id'] as String? ?? widget.profile['id'] as String?;
      if (userId == null) {
        _showSnack('用户信息异常，请重新登录');
        return;
      }
      final updates = <String, dynamic>{
        'nickname': _nicknameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'allow_stranger_visit': _allowStrangerVisit,
        'allow_friend_visit': _allowFriendVisit,
        'gender': _editGender,
      };
      if (_editFaithTag != oldFaithTag) {
        updates['faith_tag'] = _editFaithTag;
        updates['tag_last_modified_at'] = DateTime.now().toIso8601String();
      }
      if (_editAvatarUrl != (widget.profile['avatar_url'] as String?)) {
        updates['avatar_url'] = _editAvatarUrl;
      }
      if (_editBgUrl != (widget.profile['background_url'] as String?)) {
        updates['background_url'] = _editBgUrl;
      }

      // 更新编辑次数
      if (!_isVip) {
        final now = DateTime.now();
        final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        int newCount = (_profileEditMonth == currentMonth) ? _profileEditCount + 1 : 1;
        updates['profile_edit_count'] = newCount;
        updates['profile_edit_month'] = currentMonth;
      }

      await _supabase.from('profiles').update(updates).eq('user_id', userId);
      if (!mounted) return;
      widget.onSaveSuccess();
      Navigator.pop(context);
    } catch (e) {
      _showSnack('保存失败: $e');
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = _editAvatarUrl ?? widget.profile['avatar_url'] as String?;
    final currentBg = _editBgUrl ?? widget.profile['background_url'] as String?;

    return Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 420,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.borderColor.withOpacity(0.3))),
                  ),
                  child: Row(children: [
                    Text(_isVip ? '编辑资料' : '编辑资料（本月剩余 ${_remainingEditCount} 次）',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                    ),
                  ]),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      // ---- 头像 ----
                      Text('修改头像', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickAndUploadAvatar,
                        child: Container(
                          width: 80, height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.auroraGradient,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.background),
                            child: ClipOval(
                              child: currentAvatar != null && currentAvatar.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: currentAvatar, fit: BoxFit.cover,
                                      placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                                      errorWidget: (_, __, ___) => _buildDefaultAvatar())
                                  : _buildDefaultAvatar(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('点击更换', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 20),

                      // ---- 背景图 ----
                      Text('更换背景图', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickAndUploadBg,
                        child: Container(
                          height: 80, width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.background,
                            image: currentBg != null && currentBg.isNotEmpty
                                ? DecorationImage(image: CachedNetworkImageProvider(currentBg), fit: BoxFit.cover)
                                : null,
                          ),
                          child: currentBg == null || currentBg.isEmpty
                              ? const Center(child: Text('点击更换背景图', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---- 昵称 ----
                      _label('昵称'),
                      const SizedBox(height: 8),
                      _inputField(controller: _nicknameCtrl, hint: '输入昵称'),
                      const SizedBox(height: 16),

                      // ---- 简介 ----
                      _label('简介'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bioCtrl,
                        maxLength: 100, maxLines: 3,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '介绍一下自己...',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          filled: true, fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.auroraPurple)),
                          counterText: '',
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _bioCtrl,
                          builder: (_, v, __) => Text('${v.text.length}/100',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ),
                      ),
                      const SizedBox(height: 16),


                      // ---- 性别 ----
                      _label('性别'),
                      const SizedBox(height: 8),
                      Row(children: [
                        _buildGenderChoice('male', '男', Icons.male),
                        const SizedBox(width: 8),
                        _buildGenderChoice('female', '女', Icons.female),
                        const SizedBox(width: 8),
                        _buildGenderChoice('neutral', '其他', Icons.transgender),
                      ]),
                      const SizedBox(height: 16),
                      // ---- 信仰标签 ----
                      Row(children: [
                        const Text('信仰标签', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        if (!_canEditFaithTag() &&
                            _editFaithTag == (widget.profile['faith_tag'] as String? ?? ''))
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text('(${_tagDaysAgo >= 0 ? _tagDaysAgo : 0}天后可修改)', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ),
                      ]),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          if (_canEditFaithTag() ||
                              _editFaithTag != (widget.profile['faith_tag'] as String? ?? '')) {
                            setState(() => _showTagDropdown = !_showTagDropdown);
                          }
                        },
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: Row(children: [
                            Expanded(child: Text(_editFaithTag, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
                            Icon(_showTagDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: AppColors.textSecondary, size: 20),
                          ]),
                        ),
                      ),
                      if (_showTagDropdown)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true, padding: EdgeInsets.zero,
                            itemCount: kFaithTags.length,
                            itemBuilder: (context, index) {
                              final tag = kFaithTags[index];
                              final isSelected = tag == _editFaithTag;
                              return ListTile(
                                dense: true,
                                title: Text(tag, style: TextStyle(
                                    color: isSelected ? AppColors.auroraPurple : AppColors.textPrimary, fontSize: 14)),
                                trailing: isSelected ? const Icon(Icons.check, color: AppColors.auroraPurple, size: 18) : null,
                                onTap: () => setState(() {
                                  _editFaithTag = tag;
                                  _showTagDropdown = false;
                                }),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),

                      // ---- 隐私设置 ----
                      Container(height: 0.5, color: AppColors.borderColor.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('隐私设置', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(height: 12),
                      _buildPrivacyRow('允许陌生人访问主页', '关闭后，只有好友才能访问', _allowStrangerVisit,
                          (v) => setState(() => _allowStrangerVisit = v)),
                      const SizedBox(height: 12),
                      _buildPrivacyRow('允许好友访问主页', '双向关注即为好友', _allowFriendVisit,
                          (v) => setState(() => _allowFriendVisit = v)),
                      const SizedBox(height: 24),

                      // ---- 保存按钮 ----
                      GestureDetector(
                        onTap: _isSaving ? null : _handleSave,
                        child: Container(
                          width: double.infinity, height: 48, alignment: Alignment.center,
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            gradient: _isSaving ? null : AppColors.auroraGradient,
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: _isSaving ? AppColors.textMuted : AppColors.bgColor,
                            ),
                            child: _isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
                                : const Text('保存修改', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.bgSecondary,
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) =>
              const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.auroraColors).createShader(bounds),
          child: const Text('OF',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Align(alignment: Alignment.centerLeft, child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)));
  }

  Widget _inputField({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true, fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.auroraPurple)),
      ),
    );
  }

  Widget _buildPrivacyRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
      ),
      GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          width: 48, height: 26,
          padding: value ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: value ? AppColors.auroraGradient : null,
            color: value ? null : AppColors.textMuted.withOpacity(0.2),
            border: value ? null : Border.all(color: AppColors.borderColor),
          ),
          child: Stack(children: [
            // 背景层：开启时为内部实色
            if (value)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11.5),
                    color: AppColors.bgColor,
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: value ? 24 : 2, top: 2,
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textPrimary,
                  boxShadow: [BoxShadow(color: AppColors.overlay, blurRadius: 4)],
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildGenderChoice(String value, String label, IconData icon) {
    final isSelected = _editGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _editGender = value),
        child: Container(
          height: 40,
          padding: isSelected ? const EdgeInsets.all(1) : EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSelected ? 11 : 10),
            gradient: isSelected ? AppColors.auroraGradient : null,
            color: isSelected ? null : AppColors.background,
            border: isSelected ? null : Border.all(color: AppColors.borderColor),
          ),
          child: isSelected ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.background,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: AppColors.textPrimary),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ) : null,

        ),
      ),
    );
  }
}
