import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';

class PublishVideoScreen extends StatefulWidget {
  const PublishVideoScreen({super.key});

  @override
  State<PublishVideoScreen> createState() => _PublishVideoScreenState();
}

class _PublishVideoScreenState extends State<PublishVideoScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedVideoPath;
  String? _coverImagePath;
  bool _isPublic = true;
  bool _publishing = false;
  String? _error;
  List<String> _selectedTags = [];
  String? _selectedVideoName;
  String? _selectedVideoSize;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_selectedVideoPath == null) {
      setState(() => _error = '请先选择视频');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = '请输入视频标题');
      return;
    }
    setState(() { _publishing = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('未登录');

      // Upload video
      final videoExt = _selectedVideoPath!.split('.').last;
      final videoPath = 'videos/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$videoExt';
      await Supabase.instance.client.storage.from('media').upload(
        videoPath,
        File(_selectedVideoPath!),
      );

      final videoUrl = Supabase.instance.client.storage.from('media').getPublicUrl(videoPath);

      // Upload cover if exists
      String? coverUrl;
      if (_coverImagePath != null) {
        final coverExt = _coverImagePath!.split('.').last;
        final coverPath = 'covers/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$coverExt';
        await Supabase.instance.client.storage.from('media').upload(coverPath, File(_coverImagePath!));
        coverUrl = Supabase.instance.client.storage.from('media').getPublicUrl(coverPath);
      }

      await Supabase.instance.client.from('posts').insert({
        'user_id': user.id,
        'content': _descriptionController.text.trim(),
        'title': _titleController.text.trim(),
        'visibility': _isPublic ? 'public' : 'private',
        'metadata': {
          'type': 'video',
          'video_url': videoUrl,
          'cover_url': coverUrl,
          'tags': _selectedTags,
        },
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _publishing = false; });
    }
  }

  Future<void> _saveDraft() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已保存到草稿箱'),
        backgroundColor: AppColors.cardBg,
      ),
    );
  }


  void _showTagPicker(BuildContext context) {
    final allTags = ['基督教', '天主教', '伊斯兰教', '佛教', '道教', '人生', '信仰', '祷告', '圣经', '感悟', '见证', '灵修'];
    List<String> tempSelected = List.from(_selectedTags);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择话题标签', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: allTags.map((tag) {
                          final isSelected = tempSelected.contains(tag);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  tempSelected.remove(tag);
                                } else {
                                  tempSelected.add(tag);
                                }
                              });
                            },
                            child: isSelected
                              ? Container(
                                  padding: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(21),
                                    gradient: AppColors.auroraGradient,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: AppColors.bgColor,
                                    ),
                                    child: Text('#$tag',
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.borderDefault),
                                    color: AppColors.cardBg,
                                  ),
                                  child: Text('#$tag',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTags = List.from(tempSelected);
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.bgColor,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: AppColors.auroraGradient,
                          ),
                          padding: const EdgeInsets.all(1.5),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9.5),
                              color: AppColors.bgColor,
                            ),
                            child: const Center(child: Text('确认', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Column(
        children: [
          // 毛玻璃 Header - 对齐网页版
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.headerBg,
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderDefault, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '发布视频笔记',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // 存草稿
                    GestureDetector(
                      onTap: _saveDraft,
                      child: const Text(
                        '存草稿',
                        style: TextStyle(color: AppColors.textWeak, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 发布按钮
                    GestureDetector(
                      onTap: _publishing ? null : _publish,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          gradient: AppColors.auroraGradient,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.bgColor,
                          ),
                          child: _publishing
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
                              : const Text('发布',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 视频上传区
                  const Text('视频', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
                        );
                        if (result != null && result.files.single.path != null) {
                          final file = result.files.single;
                          final sizeMB = (file.size / 1024 / 1024).toStringAsFixed(1);
                          if (!mounted) return;
                          setState(() {
                            _selectedVideoPath = file.path;
                            _selectedVideoName = file.name;
                            _selectedVideoSize = '${sizeMB}MB';
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('选择视频失败: $e'),
                              backgroundColor: AppColors.cardBg,
                            ),
                          );
                        }
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderDefault,
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: _selectedVideoPath != null
                            ? Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.play_circle_fill, size: 48, color: AppColors.textSecondary),
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            _selectedVideoName ?? '',
                                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedVideoSize ?? '',
                                          style: TextStyle(color: AppColors.textWeak, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedVideoPath = null;
                                        _selectedVideoName = null;
                                        _selectedVideoSize = null;
                                      }),
                                      child: Container(
                                        width: 32, height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.overlay,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: AppColors.textPrimary, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.video_library, size: 48, color: AppColors.textSecondary),
                                  const SizedBox(height: 8),
                                  const Text('点击上传视频', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('最大50MB', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 封面上传区
                  Text('视频封面（可选）', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      try {
                        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          if (!mounted) return;
                          setState(() {
                            _coverImagePath = picked.path;
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('选择封面失败: $e'),
                              backgroundColor: AppColors.cardBg,
                            ),
                          );
                        }
                      }
                    },
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDefault, style: BorderStyle.solid, width: 1.5),
                        ),
                        child: _coverImagePath != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.file(
                                      File(_coverImagePath!),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _coverImagePath = null),
                                      child: Container(
                                        width: 32, height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.overlay,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: AppColors.textPrimary, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 32, color: AppColors.textSecondary),
                                  const SizedBox(height: 8),
                                  const Text('点击上传封面', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 标题
                  Text('标题', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '填写视频标题...',
                      hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.hoverBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderActive),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 简介
                  Text('简介', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '介绍一下你的视频...',
                      hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.hoverBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderActive),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 话题标签
                  Text('话题标签', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      _showTagPicker(context);
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedTags.isNotEmpty ? '已选 ${_selectedTags.length} 个标签' : '选择标签',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
                            child: const Text('+', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _selectedTags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.hoverBgLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(tag, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      )).toList(),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
