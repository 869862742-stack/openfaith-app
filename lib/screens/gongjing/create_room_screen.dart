import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import 'silent_room_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _descFocusNode = FocusNode();
  final List<String> _selectedTags = [];
  String? _musicFilePath;
  String? _musicTitle;
  String? _musicFileSize;
  bool _isPublic = true;
  bool _creating = false;
  String? _error;

  final List<String> _availableTags = [
    '冥想', '音乐', '治愈', '读书', '祈祷',
    '学习', '工作', '运动', '编程', '写作',
  ];

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() => setState(() {}));
    _descFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _nameFocusNode.dispose();
    _descFocusNode.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = '请输入房间名称');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('未登录');

      String? musicUrl;
      if (_musicFilePath != null) {
        final ext = _musicFilePath!.split('.').last;
        final path =
            'music/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
        await Supabase.instance.client.storage
            .from('media')
            .upload(path, File(_musicFilePath!));
        musicUrl =
            Supabase.instance.client.storage.from('media').getPublicUrl(path);
      }

      await Supabase.instance.client.from('rooms').insert({
        'owner_id': user.id,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'tags': _selectedTags,
        'is_public': _isPublic,
        'music_url': musicUrl,
        'music_title': _musicTitle,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (!mounted) return;
      
      // Get the created room ID for navigation
      final roomResult = await Supabase.instance.client
          .from('rooms')
          .select('id')
          .eq('owner_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (roomResult != null && roomResult['id'] != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SilentRoomScreen(roomId: roomResult['id'].toString()),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _creating = false;
        });
      }
    }
  }

  // ===== UI Helpers =====

  Widget _glassHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.headerBg,
            border: Border(
              bottom: BorderSide(color: AppColors.borderDefault, width: 1),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Text(
                '创建房间',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // 创建按钮
              GestureDetector(
                onTap: _creating ? null : _createRoom,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppColors.auroraGradient,
                  ),
                  child: _creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Text(
                          '创建',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styledInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    TextStyle? style,
    TextStyle? hintStyle,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        style: style ??
            const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: hintStyle ??
              const TextStyle(
                color: AppColors.textPlaceholder,
                fontSize: 14,
              ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onTapOutside: (event) => focusNode.unfocus(),
      ),
    );
  }

  Widget _tagChip(String tag) {
    final isSelected = _selectedTags.contains(tag);
    if (isSelected) {
      return GestureDetector(
        onTap: () => setState(() => _selectedTags.remove(tag)),
        child: Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: AppColors.auroraGradientWithOpacity(0.5),
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              color: AppColors.hoverBg,
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _selectedTags.add(tag)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.hoverBgLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            color: AppColors.iconColorWeak,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            _glassHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 房间名称
                    _styledInput(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      hint: '房间名称',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      hintStyle: const TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_nameController.text.length}/30',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 描述
                    _styledInput(
                      controller: _descController,
                      focusNode: _descFocusNode,
                      hint: '描述你的房间...',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_descController.text.length}/100',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 音频上传
                    Row(
                      children: [
                        const Icon(
                          Icons.music_note,
                          color: AppColors.iconColorWeak,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '音频（可选）',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '可以在创建房间后上传音频文件到播放列表',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 音乐上传区域
                    GestureDetector(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'flac'],
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          final sizeMB = (file.size / 1024 / 1024);
                          final sizeStr = sizeMB >= 1
                              ? '${sizeMB.toStringAsFixed(1)} MB'
                              : '${(file.size / 1024).toStringAsFixed(0)} KB';
                          if (!mounted) return;
                          setState(() {
                            _musicFilePath = file.path;
                            _musicTitle = file.name;
                            _musicFileSize = sizeStr;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _musicFilePath != null
                                ? AppColors.borderActive
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _musicFilePath != null
                                  ? Icons.check_circle
                                  : Icons.music_note,
                              color: _musicFilePath != null
                                  ? AppColors.auroraCyan
                                  : AppColors.iconColorWeak,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _musicFilePath != null
                                        ? _musicTitle ?? '已选择音乐'
                                        : '添加背景音乐',
                                    style: TextStyle(
                                      color: _musicFilePath != null
                                          ? AppColors.textPrimary
                                          : AppColors.textPlaceholder,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_musicFileSize != null)
                                    Text(
                                      _musicFileSize!,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_musicFilePath != null)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _musicFilePath = null;
                                  _musicTitle = null;
                                  _musicFileSize = null;
                                }),
                                child: const Icon(
                                  Icons.close,
                                  color: AppColors.textWeak,
                                  size: 20,
                                ),
                              )
                            else
                              const Icon(
                                Icons.add,
                                color: AppColors.textWeak,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 房间标签
                    const Text(
                      '房间标签',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map(_tagChip).toList(),
                    ),
                    const SizedBox(height: 20),
                    // 公开/私密
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPublic ? Icons.public : Icons.lock_outline,
                            color: AppColors.iconColorWeak,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isPublic ? '公开房间' : '私密房间',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isPublic,
                            onChanged: (v) =>
                                setState(() => _isPublic = v),
                            activeColor: AppColors.auroraCyan,
                            inactiveThumbColor: AppColors.textWeak,
                            inactiveTrackColor: AppColors.hoverBg,
                          ),
                        ],
                      ),
                    ),
                    // 错误提示
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // 创建按钮（底部大按钮）
                    GestureDetector(
                      onTap: _creating ? null : _createRoom,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: AppColors.auroraGradient,
                        ),
                        child: Center(
                          child: _creating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : const Text(
                                  '创建房间',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        '创建房间即表示你愿意在这个空间陪伴他人',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
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
