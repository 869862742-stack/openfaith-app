import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/api_cache.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rainbow_border.dart';
import 'drafts_screen.dart';
import '../../utils/religion_icon_map.dart';

class PublishNoteScreen extends StatefulWidget {
  final DraftItem? editDraft;

  const PublishNoteScreen({super.key, this.editDraft});

  @override
  State<PublishNoteScreen> createState() => _PublishNoteScreenState();
}

class _PublishNoteScreenState extends State<PublishNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _customTagController = TextEditingController();
  final _requestReasonController = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  List<String> _selectedTags = [];
  List<XFile> _selectedImages = [];
  bool _isPublishing = false;
  String? _editingPostId;
  late String _draftId;

  // 加热卡
  bool _useHeatingCard = false;
  String _heatingTier = 'free';
  int _heatingCards = 0;

  // 其他卡片
  int _qaCards = 0;
  bool _useQACard = false;
  int _echoCards = 0;
  bool _useEchoCard = false;
  int _companionCards = 0;
  bool _useCompanionCard = false;
  bool _isVip = false;

  // 每日限制弹窗
  bool _showLimitModal = false;
  bool _showRequestModal = false;
  bool _isSubmittingRequest = false;
  bool _requestSubmitted = false;

  static const _noteTags = [
    '基督教', '天主教', '伊斯兰教', '印度教', '佛教', '锡克教', '犹太教', '道教',
    '巴哈伊教', '摩门教', '耶和华见证人', '德鲁兹教', '雅兹迪', '曼达安',
    '神道教', '天理教', '天道教', '高台教', '玛雅/阿兹特克', '毛利宗教',
    '耆那教', '琐罗亚斯德教', '诺斯替', '卡巴拉', '约鲁巴教', '伏都教',
  ];

  static const _heatingTiers = [
    {'key': 'free', 'label': '免费加热卡', 'duration': '6小时', 'price': 0, 'desc': 'VIP月赠'},
    {'key': '6h', 'label': '轻度加热', 'duration': '6小时', 'price': 6, 'desc': '约500次曝光'},
    {'key': '12h', 'label': '中度加热', 'duration': '12小时', 'price': 12, 'desc': '约1200次曝光'},
    {'key': '24h', 'label': '深度加热', 'duration': '24小时', 'price': 20, 'desc': '约2500次曝光'},
  ];

  @override
  void initState() {
    super.initState();
    _draftId = DateTime.now().millisecondsSinceEpoch.toString();
    _loadUserInfo();

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
    _requestReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final response = await _supabase
          .from('profiles')
          .select('is_vip,exposure_cards,qa_cards,echo_cards,companion_cards')
          .eq('user_id', user.id)
          .single();
      if (response != null) {
        if (!mounted) return;
        setState(() {
          _isVip = response['is_vip'] ?? false;
          _heatingCards = response['exposure_cards'] ?? 0;
          _qaCards = response['qa_cards'] ?? 0;
          _echoCards = response['echo_cards'] ?? 0;
          _companionCards = response['companion_cards'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('[PublishNote] Failed to load user info: $e');
    }
  }

  // ==================== 图片处理 ====================
  Future<void> _showImageSourceDialog() async {
    if (_selectedImages.length >= 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多选择 9 张图片'), backgroundColor: AppColors.warning),
      );
      return;
    }

    final result = await showModalBottomSheet<String>(
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
        if (!mounted) return;
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
    setState(() => _selectedImages.removeAt(index));
  }

  Future<File> _compressImage(XFile xFile) async {
    final tempDir = await getTemporaryDirectory();
    final compressedPath = '${tempDir.path}/note_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bytes = await xFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('无法解析图片');

    img.Image working = decoded;
    if (working.width > 1200) {
      working = img.copyResize(decoded, width: 1200);
    }
    final jpg = img.encodeJpg(working, quality: 80);
    await File(compressedPath).writeAsBytes(jpg);
    return File(compressedPath);
  }

  Future<List<String>> _uploadImages(String userId, String postId) async {
    final urls = <String>[];
    final bucket = _supabase.storage.from('post-images');

    for (int i = 0; i < _selectedImages.length; i++) {
      final compressedFile = await _compressImage(_selectedImages[i]);
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      await bucket.upload(fileName, compressedFile);
      urls.add(bucket.getPublicUrl(fileName));
    }
    return urls;
  }

  // ==================== 标签处理 ====================
  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _showTagModal() {
    List<String> tempSelected = List.from(_selectedTags);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 头部
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('选择标签', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 自定义标签输入
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customTagController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '输入自定义标签',
                            hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                            filled: true,
                            fillColor: AppColors.inputBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.borderDefault),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.borderDefault),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.borderActive),
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setModalState(() {
                                if (!tempSelected.contains(val.trim())) {
                                  tempSelected.add(val.trim());
                                }
                              });
                              _customTagController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          final val = _customTagController.text.trim();
                          if (val.isNotEmpty && !tempSelected.contains(val)) {
                            setModalState(() => tempSelected.add(val));
                            _customTagController.clear();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.inputBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('添加', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 已选标签
                  if (tempSelected.isNotEmpty) ...[
                    Text('已选 ${tempSelected.length} 个', style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: tempSelected.map((tag) {
                        return GestureDetector(
                          onTap: () => setModalState(() => tempSelected.remove(tag)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: AppColors.auroraGradient,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(tag, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                const SizedBox(width: 4),
                                const Icon(Icons.close, size: 14, color: Colors.white70),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 12),

                  // 标签分组
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTagGroup('主流宗教',
                            ['基督教','天主教','伊斯兰教','印度教','佛教','锡克教','犹太教','道教'],
                            tempSelected, setModalState),
                          _buildTagGroup('亚伯拉罕系',
                            ['巴哈伊教','摩门教','耶和华见证人','德鲁兹教','雅兹迪','曼达安'],
                            tempSelected, setModalState),
                          _buildTagGroup('东亚 & 东盟',
                            ['神道教','天理教','天道教','高台教','玛雅/阿兹特克','毛利宗教'],
                            tempSelected, setModalState),
                          _buildTagGroup('南亚 & 中东',
                            ['耆那教','琐罗亚斯德教','诺斯替','卡巴拉','约鲁巴教','伏都教'],
                            tempSelected, setModalState),
                          // 更多（不在以上分组中的）
                          _buildMoreTagGroup(tempSelected, setModalState),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 确认按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _selectedTags = List.from(tempSelected));
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
                          gradient: AppColors.auroraGradient,
                        ),
                        child: Center(
                          child: Text(
                            tempSelected.isNotEmpty ? '确定 (${tempSelected.length})' : '确定',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildTagGroup(String title, List<String> tags, List<String> tempSelected, void Function(void Function()) setModalState) {
    final filtered = _noteTags.where((t) => tags.contains(t)).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textWeak, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: filtered.map((tag) {
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.rainbowColors.first.withOpacity(0.15) : AppColors.inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.rainbowColors.first : AppColors.borderDefault,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (_) {
                      final iconData = getReligionIcon(tag);
                      return Icon(iconData.icon, size: 14, color: isSelected ? iconData.color : iconData.color.withOpacity(0.6));
                    }),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMoreTagGroup(List<String> tempSelected, void Function(void Function()) setModalState) {
    const grouped = ['基督教','天主教','伊斯兰教','印度教','佛教','锡克教','犹太教','道教','巴哈伊教','摩门教','耶和华见证人','德鲁兹教','雅兹迪','曼达安','神道教','天理教','天道教','高台教','玛雅/阿兹特克','毛利宗教','耆那教','琐罗亚斯德教','诺斯替','卡巴拉','约鲁巴教','伏都教'];
    final others = _noteTags.where((t) => !grouped.contains(t)).toList();
    if (others.isEmpty) return const SizedBox.shrink();
    return _buildTagGroup('更多', others.map((e) => e).toList(), tempSelected, setModalState);
  }

  // ==================== 每日限制检查 ====================
  Future<Map<String, dynamic>> _fetchDailyNoteLimit() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return {};
      final response = await _supabase
          .from('profiles')
          .select('daily_note_count,daily_note_date,extra_note_granted')
          .eq('user_id', user.id)
          .single();
      return response ?? {};
    } catch (e) {
      debugPrint('[PublishNote] Failed to fetch daily limit: $e');
      return {};
    }
  }

  Future<bool> _checkDailyNoteLimit() async {
    try {
      final limit = await _fetchDailyNoteLimit();
      if (limit.isEmpty) return true;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final noteDate = limit['daily_note_date'] as String?;
      if (noteDate != today) return true;
      final count = limit['daily_note_count'] as int? ?? 0;
      final extra = limit['extra_note_granted'] as int? ?? 0;
      return count < (3 + extra);
    } catch (e) {
      debugPrint('[PublishNote] Failed to check daily limit: $e');
      return true;
    }
  }

  Future<void> _updateDailyNoteCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final limit = await _fetchDailyNoteLimit();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final count = limit['daily_note_count'] as int? ?? 0;
      final extra = limit['extra_note_granted'] as int? ?? 0;
      final updateData = <String, dynamic>{
        'daily_note_count': count + 1,
        'daily_note_date': today,
      };
      if (extra > 0) {
        updateData['extra_note_granted'] = extra - 1;
      }
      await _supabase.from('profiles').update(updateData).eq('user_id', user.id);
    } catch (e) {
      debugPrint('[PublishNote] Failed to update daily count: $e');
    }
  }

  // ==================== 申请额外额度 ====================
  Future<void> _submitNoteRequest() async {
    final reason = _requestReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写申请理由'), backgroundColor: AppColors.warning),
      );
      return;
    }
    setState(() => _isSubmittingRequest = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('请先登录');
      await _supabase.from('note_requests').insert({
        'user_id': user.id,
        'reason': reason,
        'status': 'pending',
      });
      if (!mounted) return;
      setState(() {
        _requestSubmitted = true;
        _isSubmittingRequest = false;
        _requestReasonController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败: $e'), backgroundColor: AppColors.error),
      );
      if (!mounted) return;
      setState(() => _isSubmittingRequest = false);
    }
  }

  // ==================== 草稿保存 ====================
  Future<void> _saveDraft() async {
    final draft = DraftItem(
      id: _draftId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: List.from(_selectedTags),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await DraftService.saveDraft(draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存到草稿箱'), backgroundColor: AppColors.cardBg),
      );
    }
  }

  // ==================== 经验值 ====================
  Future<void> _addExperience(String userId, int baseAmount) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('experience,level,is_vip')
          .eq('user_id', userId)
          .single();
      if (response != null) {
        final isVip = response['is_vip'] ?? false;
        final multiplier = isVip ? 1.5 : 1.0;
        final expAmount = (baseAmount * multiplier).ceil();
        final newExp = (response['experience'] ?? 0) + expAmount;
        const thresholds = [0, 1000, 5000, 25000, 125000, 250000, 500000, 1000000, 2000000, 5000000];
        int newLevel = 1;
        for (int i = thresholds.length - 1; i >= 0; i--) {
          if (newExp >= thresholds[i]) { newLevel = i + 1; break; }
        }
        await _supabase.from('profiles').update({
          'experience': newExp,
          'level': newLevel.clamp(1, 10),
        }).eq('user_id', userId);
      }
    } catch (e) {
      debugPrint('[PublishNote] Failed to add experience: $e');
    }
  }

  // ==================== 发布 ====================
  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写标题'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写正文内容'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个标签'), backgroundColor: AppColors.warning),
      );
      return;
    }

    // 每日限制
    final allowed = await _checkDailyNoteLimit();
    if (!allowed) {
      if (!mounted) return;
      setState(() => _showLimitModal = true);
      return;
    }

    if (!mounted) return;
    setState(() => _isPublishing = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('请先登录');

      // 上传图片
      final imageUrls = _selectedImages.isNotEmpty
          ? await _uploadImages(user.id, _draftId)
          : <String>[];

      final postData = {
        'user_id': user.id,
        'title': title,
        'content': content,
        'tags': _selectedTags,
        'images': imageUrls,
        'cover_image': imageUrls.isNotEmpty ? imageUrls.first : null,
        'status': 'pending',
        'qa_card_used': _useQACard,
        'echo_card_used': _useEchoCard,
        'companion_card_used': _useCompanionCard,
      };

      String? postId;

      if (_editingPostId != null) {
        await _supabase.from('posts').update(postData).eq('id', _editingPostId!);
        // Invalidate home posts cache after editing
        await ApiCache.instance.invalidate('home:posts:0');
        postId = _editingPostId;
      } else {
        final result = await _supabase.from('posts').insert(postData).select().single();
        postId = result['id'] as String;

        // 经验值
        await _addExperience(user.id, 10);

        // 加热卡
        if (_useHeatingCard && _heatingTier == 'free' && _heatingCards > 0) {
          await _supabase.from('profiles')
              .update({'exposure_cards': _heatingCards - 1}).eq('user_id', user.id);
        }

        // 答疑卡
        if (_useQACard && _qaCards > 0) {
          await _supabase.from('profiles')
              .update({'qa_cards': _qaCards - 1}).eq('user_id', user.id);
          await _supabase.from('posts').update({
            'heat_count': 500,
            'heating_status': 'heating',
            'heating_end_at': DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
            'heating_tier': 'qa_card',
          }).eq('id', postId);
        }

        // 回响卡
        if (_useEchoCard && _echoCards > 0) {
          await _supabase.from('profiles')
              .update({'echo_cards': _echoCards - 1}).eq('user_id', user.id);
          await _supabase.from('posts').update({
            'heat_count': 300,
            'heating_status': 'heating',
            'heating_end_at': DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
            'heating_tier': 'echo_card',
          }).eq('id', postId);
        }

        // 同行卡
        if (_useCompanionCard && _companionCards > 0) {
          await _supabase.from('profiles')
              .update({'companion_cards': _companionCards - 1}).eq('user_id', user.id);
        }
      }

      // 更新每日笔记计数
      await _updateDailyNoteCount();

      // 删除已编辑的草稿
      if (widget.editDraft != null) {
        await DraftService.deleteDraft(widget.editDraft!.id);
      }

      if (mounted) {
        final msg = _buildSuccessMessage();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success, duration: const Duration(seconds: 3)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('[PublishNote] Publish failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  String _buildSuccessMessage() {
    final buf = StringBuffer('发布成功！等待审核后将在首页显示\n+10 经验值');
    if (_useHeatingCard && _heatingTier == 'free' && _heatingCards > 0) {
      buf.write('\n🔥 已使用1张免费加热卡（6小时）');
    }
    if (_useQACard && _qaCards > 0) {
      buf.write('\n❓ 已使用1张答疑卡（12小时精准推送）');
    }
    if (_useEchoCard && _echoCards > 0) {
      buf.write('\n🔁 已使用1张回响卡（6小时二次推荐）');
    }
    if (_useCompanionCard && _companionCards > 0) {
      buf.write('\n🤝 已使用1张同行卡（推送同信仰用户）');
    }
    return buf.toString();
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bgColor,
          body: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16, right: 16, bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgColor,
                  border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 0.5)),
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
                    Expanded(
                      child: Text(
                        _editingPostId != null ? '编辑笔记' : '发布笔记',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // 存草稿
                    GestureDetector(
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
                    const SizedBox(width: 8),
                    // 发布
                    GestureDetector(
                      onTap: _isPublishing ? null : _publish,
                      child: RainbowBorder(
                        borderRadius: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _isPublishing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
                              : const Text('发布', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图片
                      _buildImageSection(),
                      const SizedBox(height: 20),
                      // 标题
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: '添加标题会有更多赞哦~',
                          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 22, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: AppColors.inputBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderActive)),
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 16),
                      // 内容
                      TextField(
                        controller: _contentController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.6),
                        decoration: InputDecoration(
                          hintText: '分享你的信仰故事...',
                          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 16),
                          filled: true,
                          fillColor: AppColors.inputBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderActive)),
                        ),
                        maxLines: 12,
                        minLines: 6,
                      ),
                      const SizedBox(height: 20),
                      // 标签
                      _buildTagSelection(),
                      const SizedBox(height: 20),
                      // 卡片
                      if (_editingPostId == null) ...[
                        _buildHeatingCard(),
                        const SizedBox(height: 12),
                        if (_isVip) ...[
                          _buildQACard(),
                          const SizedBox(height: 12),
                          _buildEchoCard(),
                          const SizedBox(height: 12),
                          _buildCompanionCard(),
                        ],
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // 每日限制弹窗
        if (_showLimitModal) _buildLimitModal(),
        // 申请额度弹窗
        if (_showRequestModal) _buildRequestModal(),
      ],
    );
  }

  // ==================== 子组件 ====================
  Widget _buildImageSection() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8,
      ),
      itemCount: _selectedImages.length < 9 ? _selectedImages.length + 1 : _selectedImages.length,
      itemBuilder: (context, index) {
        if (index == _selectedImages.length) return _buildAddImageButton();
        return _buildImageThumbnail(index);
      },
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.textWeak.withOpacity(0.4), width: 1.5),
          color: AppColors.inputBg.withOpacity(0.3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 28, color: AppColors.textWeak.withOpacity(0.6)),
            const SizedBox(height: 2),
            Text('添加图片', style: TextStyle(color: AppColors.textWeak.withOpacity(0.6), fontSize: 10)),
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
          child: Image.file(File(_selectedImages[index].path), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('话题标签', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: [
            ..._selectedTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppColors.auroraGradient,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (_) {
                      final iconData = getReligionIcon(tag);
                      return Icon(iconData.icon, size: 12, color: iconData.color);
                    }),
                    const SizedBox(width: 3),
                    Text('#$tag', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _toggleTag(tag),
                      child: const Icon(Icons.close, size: 14, color: Colors.white70),
                    ),
                  ],
                ),
              );
            }),
            GestureDetector(
              onTap: _showTagModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: const Text('+ 添加标签', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 40,
        height: 20,
        decoration: BoxDecoration(
          color: value ? activeColor : AppColors.inputBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 22.0 : 2.0,
              top: 2.0,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.auroraCyan, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('加热卡', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('让更多人看到你的笔记', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
                  ],
                ),
              ),
              _buildToggleSwitch(
                value: _useHeatingCard, activeColor: AppColors.auroraCyan,
                onChanged: (val) => setState(() => _useHeatingCard = val),
              ),
            ],
          ),
          if (_useHeatingCard) ...[
            const SizedBox(height: 12),
            if (_heatingCards > 0) _buildHeatingTierOption('free', '免费加热卡', '6小时', '剩余${_heatingCards}张', false),
            ..._heatingTiers.where((t) => t['key'] != 'free').map((tier) {
              return _buildHeatingTierOption(
                tier['key'] as String, tier['label'] as String,
                '${tier['duration']} · ${tier['desc']}', '¥${tier['price']}', true,
              );
            }),
            if (_heatingCards == 0 && !_isVip)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('开通VIP每月赠送1张免费加热卡', style: TextStyle(color: AppColors.textWeak, fontSize: 11)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeatingTierOption(String key, String label, String desc, String price, bool isPaid) {
    final isSelected = _heatingTier == key;
    return GestureDetector(
      onTap: () => setState(() => _heatingTier = key),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.auroraCyan.withOpacity(0.1) : AppColors.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.auroraCyan.withOpacity(0.3) : AppColors.borderDefault),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                    if (!isPaid) ...[const SizedBox(width: 8), Text('剩余$_heatingCards张', style: const TextStyle(color: AppColors.auroraCyan, fontSize: 12))],
                  ]),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
                ],
              ),
            ),
            if (isPaid) Text(price, style: const TextStyle(color: AppColors.auroraOrange, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQACard() => _buildSpecialCard(
    icon: Icons.help_outline, iconColor: AppColors.auroraGreen,
    title: '答疑卡', subtitle: '精准推送给活跃答疑者',
    count: _qaCards, useCard: _useQACard, activeColor: AppColors.auroraGreen,
    onChanged: (val) => setState(() => _useQACard = val),
    descriptions: ['优先推送给近30天评论活跃的答疑者', '推送给身份标签与笔记标签一致的用户', '效果不低于加热卡（12小时精准推广）'],
  );

  Widget _buildEchoCard() => _buildSpecialCard(
    icon: Icons.refresh, iconColor: AppColors.auroraPurple,
    title: '回响卡', subtitle: '内容二次推荐',
    count: _echoCards, useCard: _useEchoCard, activeColor: AppColors.auroraPurple,
    onChanged: (val) => setState(() => _useEchoCard = val),
    descriptions: ['推送给近期互动过你的内容的用户', '+300热度，6小时二次推广', '适合已有一定关注度的帖子'],
  );

  Widget _buildCompanionCard() => _buildSpecialCard(
    icon: Icons.people_outline, iconColor: AppColors.auroraOrange,
    title: '同行卡', subtitle: '推送同信仰用户',
    count: _companionCards, useCard: _useCompanionCard, activeColor: AppColors.auroraOrange,
    onChanged: (val) => setState(() => _useCompanionCard = val),
    descriptions: ['推送给身份标签与笔记匹配的同信仰用户', '同时推送近期发布过同标签内容的用户', '适合祈祷、分享类帖子找到同行者'],
  );

  Widget _buildSpecialCard({
    required IconData icon, required Color iconColor,
    required String title, required String subtitle,
    required int count, required bool useCard, required Color activeColor,
    required ValueChanged<bool> onChanged, required List<String> descriptions,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(subtitle, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
                  ],
                ),
              ),
              Text(count > 0 ? '剩余${count}张' : '已用完',
                  style: TextStyle(color: count > 0 ? activeColor : AppColors.textWeak, fontSize: 11)),
              const SizedBox(width: 8),
              _buildToggleSwitch(value: useCard, activeColor: activeColor, onChanged: onChanged),
            ],
          ),
          if (useCard) ...[
            const SizedBox(height: 12),
            ...descriptions.map((d) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• $d', style: const TextStyle(color: AppColors.textWeak, fontSize: 11)),
            )),
            if (count == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('\u26a0\ufe0f 暂无$title，下月VIP续费后赠1张', style: TextStyle(color: AppColors.auroraOrange, fontSize: 11)),
              ),
          ],
        ],
      ),
    );
  }

  // ==================== 弹窗 ====================
  Widget _buildLimitModal() {
    return GestureDetector(
      onTap: () => setState(() => _showLimitModal = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.auroraCyan, size: 32),
                  ),
                  const SizedBox(height: 16),
                  if (_requestSubmitted) ...[
                    const Text('申请已提交', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('管理员审核通过后，你会收到通知消息', style: TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: () => setState(() { _showLimitModal = false; _requestSubmitted = false; }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradient),
                          child: const Center(child: Text('我知道了', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text('今日笔记已达上限', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('每天可发布3条笔记，今日已达上限哦', style: TextStyle(color: AppColors.textSecondary, fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showLimitModal = false;
                            _showRequestModal = true;
                            _requestReasonController.clear();
                            _requestSubmitted = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradient),
                          child: const Center(child: Text('申请额外发布额度', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _showLimitModal = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.bgSecondary, shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Center(child: Text('我知道了', style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500))),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestModal() {
    return GestureDetector(
      onTap: () => setState(() => _showRequestModal = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('申请额外发布额度', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => setState(() => _showRequestModal = false),
                        child: const Icon(Icons.close, color: AppColors.textSecondary, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('请填写申请理由，管理员审核通过后可获得额外发布机会', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _requestReasonController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '请输入申请理由...',
                      hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDefault)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderActive)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _showRequestModal = false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bgSecondary, shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Center(child: Text('取消', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmittingRequest ? null : _submitNoteRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradient),
                              child: Center(
                                child: Text(_isSubmittingRequest ? '提交中...' : '提交申请', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
