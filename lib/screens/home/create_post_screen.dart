import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../theme/colors.dart';
import '../../theme/rainbow_widgets.dart';
import '../publish/drafts_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final DraftItem? editDraft;
  const CreatePostScreen({super.key, this.editDraft});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _customTagController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  String? _selectedFaithTag = 'seeker';
  final List<String> _selectedTags = [];
  final List<XFile> _selectedImages = [];
  bool _isPublishing = false;
  late String _draftId;

  // ══════ EXP 动画 ══════
  AnimationController? _expAnimController;
  Animation<Offset>? _expSlideAnimation;
  Animation<double>? _expFadeAnimation;
  OverlayEntry? _expOverlayEntry;
  int _expAmount = 0;

  void _showExpAnimation(int amount) {
    _expAmount = amount;
    _expOverlayEntry?.remove();
    _expAnimController?.dispose();

    _expAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _expSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(
      parent: _expAnimController!,
      curve: Curves.easeOut,
    ));
    _expFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _expAnimController!,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));

    _expOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height * 0.35,
        left: 0,
        right: 0,
        child: Center(
          child: AnimatedBuilder(
            animation: _expAnimController!,
            builder: (context, child) {
              return Opacity(
                opacity: _expFadeAnimation!.value,
                child: FractionalTranslation(
                  translation: _expSlideAnimation!.value,
                  child: Text(
                    '+$amount EXP',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Color(0xFFFFD700).withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_expOverlayEntry!);
    _expAnimController!.forward().then((_) {
      _expOverlayEntry?.remove();
      _expOverlayEntry = null;
    });
  }

  static const _faithTags = [
    {'key': 'seeker', 'label': '寻道者'},
    {'key': 'believer', 'label': '信徒'},
    {'key': 'scholar', 'label': '学者'},
    {'key': 'clergy', 'label': '神职人员'},
  ];

  static const _commonTags = [
    '基督教', '天主教', '伊斯兰教', '佛教', '道教',
    '人生', '信仰', '祷告', '圣经', '感悟',
  ];

  @override
  void initState() {
    super.initState();
    _draftId = DateTime.now().millisecondsSinceEpoch.toString();

    if (widget.editDraft != null) {
      final draft = widget.editDraft!;
      _titleController.text = draft.title;
      _contentController.text = draft.content;
      _selectedTags.addAll(draft.tags);
      _draftId = draft.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _customTagController.dispose();
    _expAnimController?.dispose();
    _expOverlayEntry?.remove();
    super.dispose();
  }

  // ==========================================================================
  // Image picker logic
  // ==========================================================================
  Future<void> _showImageSourceDialog() async {
    if (_selectedImages.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多选择 9 张图片'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.auroraCyan),
                title: const Text('拍照', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.auroraPurple),
                title: const Text('从相册选择', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;

    try {
      List<XFile>? picked;
      final remaining = 9 - _selectedImages.length;

      if (result == 'camera') {
        final image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1200,
        );
        if (image != null) picked = [image];
      } else {
        picked = await _imagePicker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1200,
          requestFullMetadata: false,
        );
        if (picked != null && picked.length > remaining) {
          picked = picked.take(remaining).toList();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已限制最多 9 张，本次添加了 $remaining 张'), backgroundColor: AppColors.warning),
            );
          }
        }
      }

      if (picked != null && picked.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(picked!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Compress image file: max width 1200px, JPEG quality 80%
  Future<File> _compressImage(XFile xFile) async {
    final tempDir = await getTemporaryDirectory();
    final compressedPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final bytes = await xFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('无法解析图片');

    // Resize if wider than 1200px
    if (image.width > 1200) {
      final resized = img.copyResize(image, width: 1200);
      final jpg = img.encodeJpg(resized, quality: 80);
      await File(compressedPath).writeAsBytes(jpg);
    } else {
      final jpg = img.encodeJpg(image, quality: 80);
      await File(compressedPath).writeAsBytes(jpg);
    }

    return File(compressedPath);
  }

  /// Upload images to Supabase Storage and return list of public URLs
  Future<List<String>> _uploadImages(String userId, String postId) async {
    final urls = <String>[];
    final bucket = _supabase.storage.from('posts');

    for (int i = 0; i < _selectedImages.length; i++) {
      final compressed = await _compressImage(_selectedImages[i]);
      final path = '$userId/$postId/$i.jpg';

      await bucket.upload(path, compressed,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));

      final publicUrl = bucket.getPublicUrl(path);
      urls.add(publicUrl);
    }

    return urls;
  }

  // ==========================================================================
  // Draft / Publish
  // ==========================================================================
  Future<void> _saveDraft() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('内容为空，无法保存草稿'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    final now = DateTime.now();
    final draft = DraftItem(
      id: _draftId,
      title: title.isNotEmpty ? title : '无标题',
      content: content,
      tags: List<String>.from(_selectedTags),
      createdAt: widget.editDraft?.createdAt ?? now,
      updatedAt: now,
    );
    await DraftService.saveDraft(draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('草稿已保存'), backgroundColor: AppColors.auroraCyan, duration: Duration(seconds: 1)),
      );
    }
  }

  Future<bool> _onWillPop() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isNotEmpty || content.isNotEmpty || _selectedImages.isNotEmpty) {
      await _saveDraft();
    }
    return true;
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('未登录');

      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      List<String> imageUrls = [];

      // Upload images if any
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(user.id, postId);
      }

      final postData = {
        'user_id': user.id,
        'title': title,
        'content': content,
        'status': 'published',
        'faith_tag': _selectedFaithTag,
        'tags': _selectedTags,
        'likes_count': 0,
        'heat_count': 0,
        'comments_count': 0,
        'views_count': 0,
        'shares_count': 0,
        'favorites_count': 0,
        'images': imageUrls,
        if (imageUrls.isNotEmpty) 'cover_image': imageUrls.first,
      };

      await _supabase.from('posts').insert(postData);

      // Delete draft if editing
      if (widget.editDraft != null) {
        await DraftService.deleteDraft(_draftId);
      }

      // 增加经验值 +10
      try {
        await _supabase.rpc('increment_experience', params: {
          'p_user_id': user.id,
          'p_amount': 10,
        });
      } catch (_) {
        // RPC not available, skip EXP update
        debugPrint('EXP update failed, RPC may not exist yet');
      }

      if (!mounted) return;
      _showExpAnimation(10);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发布成功 +10 EXP'), backgroundColor: AppColors.success),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发布失败: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  void _addTag(String tag) {
    if (!_selectedTags.contains(tag) && tag.isNotEmpty) {
      setState(() => _selectedTags.add(tag));
    }
  }

  // ==========================================================================
  // UI
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editDraft != null;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () async {
              await _onWillPop();
              if (mounted) Navigator.pop(context);
            },
          ),
          actions: [
            // 保存草稿按钮
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: _saveDraft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_outlined, size: 14, color: AppColors.textPrimary.withOpacity(0.7)),
                      const SizedBox(width: 4),
                      const Text('存草稿', style: TextStyle(color: AppColors.textWeak, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            // 发布按钮
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: _isPublishing ? null : _publish,
                child: RainbowBorderContainer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _isPublishing
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                          )
                        : const Text('发布', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.auroraCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.auroraCyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_note, size: 16, color: AppColors.auroraCyan),
                      const SizedBox(width: 8),
                      const Text('正在编辑草稿', style: TextStyle(color: AppColors.auroraCyan, fontSize: 13)),
                    ],
                  ),
                ),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: '标题',
                  hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 22, fontWeight: FontWeight.bold),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _contentController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.6),
                decoration: const InputDecoration(
                  hintText: '分享你的想法...',
                  hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 12,
                minLines: 6,
              ),
              const SizedBox(height: 16),

              // ====== 图片预览网格 + 添加按钮 ======
              _buildImageSection(),

              const SizedBox(height: 24),
              const Text('信仰身份', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _faithTags.map((tag) {
                  final selected = _selectedFaithTag == tag['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFaithTag = tag['key']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.rainbowColors.first.withOpacity(0.15) : AppColors.inputBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? AppColors.rainbowColors.first : AppColors.borderDefault,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag['label']!,
                        style: TextStyle(
                          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('话题标签', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._commonTags.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selectedTags.remove(tag);
                          } else {
                            _selectedTags.add(tag);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.rainbowColors.first.withOpacity(0.15) : AppColors.inputBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? AppColors.rainbowColors.first : AppColors.borderDefault,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#$tag',
                              style: TextStyle(
                                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _customTagController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: '+自定义',
                        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.borderDefault),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        isDense: true,
                      ),
                      onSubmitted: (val) {
                        _addTag(val.trim());
                        _customTagController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Image section: preview grid + add button
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _getImageItemCount(),
          itemBuilder: (context, index) {
            // Last item is the add button (if < 9 images)
            if (index == _selectedImages.length) {
              return _buildAddImageButton();
            }
            return _buildImageThumbnail(index);
          },
        ),
      ],
    );
  }

  int _getImageItemCount() {
    // Show add button if < 9 images
    if (_selectedImages.length < 9) {
      return _selectedImages.length + 1;
    }
    return _selectedImages.length;
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.textWeak.withOpacity(0.4),
            style: BorderStyle.solid,
            width: 1.5,
          ),
          color: AppColors.inputBg.withOpacity(0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 28,
              color: AppColors.textWeak.withOpacity(0.6),
            ),
            const SizedBox(height: 2),
            Text(
              '添加图片',
              style: TextStyle(
                color: AppColors.textWeak.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_selectedImages[index].path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Delete button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
