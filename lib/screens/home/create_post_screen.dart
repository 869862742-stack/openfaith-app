import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  String? _selectedFaithTag = 'seeker';
  final List<String> _selectedTags = [];
  bool _isPublishing = false;
  late String _draftId;

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
    super.dispose();
  }

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
    if (title.isNotEmpty || content.isNotEmpty) {
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
      if (user == null) {
        throw Exception('未登录');
      }

      await _supabase.from('posts').insert({
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
      });

      // Delete draft if editing
      if (widget.editDraft != null) {
        await DraftService.deleteDraft(_draftId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发布成功'), backgroundColor: AppColors.success),
      );
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
                    color: const AppColors.auroraCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const AppColors.auroraCyan.withOpacity(0.3)),
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
}
