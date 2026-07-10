import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();
  final _customTagController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _searchFocusNode = FocusNode();
  final List<Map<String, dynamic>> _allFriends = [];
  final Set<String> _selectedIds = {};
  final List<String> _selectedTags = [];
  final List<String> _customTags = [];
  bool _loading = true;
  String _activeTab = 'search';

  static const _fallbackGroupTags = [
    '基督教', '伊斯兰教', '犹太教', '佛教', '印度教', '道教', '锡克教',
    '巴哈伊教', '摩门教', '耶和华见证人', '琐罗亚斯德教', '诺斯替',
    '卡巴拉', '神道教', '耆那教', '德鲁兹教', '约鲁巴教', '伏都教',
    '雅兹迪', '曼达安', '玛雅/阿兹特克', '毛利宗教', '天理教', '天道教',
    '高台教',
  ];

  List<String> get _groupTags => _fallbackGroupTags;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _nameFocusNode.addListener(() => setState(() {}));
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _searchController.dispose();
    _customTagController.dispose();
    _nameFocusNode.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _loading = false);
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _addCustomTag() {
    final tag = _customTagController.text.trim();
    if (tag.isEmpty) return;
    if (_customTags.contains(tag) || _selectedTags.contains(tag)) return;
    setState(() {
      _customTags.add(tag);
      _selectedTags.add(tag);
      _customTagController.clear();
    });
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入群聊名称'),
          backgroundColor: AppColors.cardBg,
        ),
      );
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请至少选择一个标签'),
          backgroundColor: AppColors.cardBg,
        ),
      );
      return;
    }

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final groupResp = await client.from('group_chats').insert({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'owner_id': user.id,
        'tags': _selectedTags,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select();

      if (groupResp.isNotEmpty) {
        final groupId = groupResp[0]['id'];
        final memberIds = [user.id, ..._selectedIds];
        for (final memberId in memberIds) {
          await client.from('group_chat_members').insert({
            'group_id': groupId,
            'user_id': memberId,
            'joined_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建失败: $e'),
            backgroundColor: AppColors.cardBg,
          ),
        );
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
                  Icons.arrow_back_ios,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              const Text(
                '添加群聊',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, String tab) {
    final isActive = _activeTab == tab;
    if (isActive) {
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _activeTab = tab),
          child: Container(
            height: 40,
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppColors.auroraGradient,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: AppColors.background,
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.hoverBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderActive),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textWeak,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientButton({
    required Widget child,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: AppColors.auroraGradient,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _styledInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    int maxLines = 1,
    bool showBorder = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: showBorder
            ? Border.all(color: AppColors.borderDefault)
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onTapOutside: (event) => focusNode.unfocus(),
      ),
    );
  }

  Widget _tagChip(String tag) {
    final isSelected = _selectedTags.contains(tag);
    if (isSelected) {
      return GestureDetector(
        onTap: () => _toggleTag(tag),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.transparent, width: 1.5),
            gradient: AppColors.auroraGradientWithOpacity(0.5),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.all(-1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.background,
            ),
            child: Text(
              tag,
              style: const TextStyle(
                color: AppColors.auroraCyan,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _toggleTag(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }


  List<Map<String, dynamic>> _searchResultsList = [];
  bool _searching = false;

  Future<void> _searchGroups() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入搜索关键词'),
          backgroundColor: AppColors.cardBg,
        ),
      );
      return;
    }
    setState(() => _searching = true);
    try {
      final client = Supabase.instance.client;
      final results = await client
          .from('group_chats')
          .select()
          .ilike('name', '%$keyword%')
          .limit(20);
      setState(() {
        _searchResultsList = List<Map<String, dynamic>>.from(results);
        _searching = false;
      });
    } catch (e) {
      setState(() => _searching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('搜索失败: $e'),
            backgroundColor: AppColors.cardBg,
          ),
        );
      }
    }
  }

  // ===== Search Tab =====

  Widget _searchTab() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: '搜索群名或群ID',
                          hintStyle: const TextStyle(
                            color: AppColors.textPlaceholder,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onTapOutside: (event) =>
                            FocusScope.of(context).unfocus(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _gradientButton(
              onPressed: _searchGroups,
              child: const Text(
                '搜索',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        const Text(
          '暂无群聊',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  // ===== Create Tab =====

  Widget _createTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 群聊名称
        const Text(
          '群聊名称',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _styledInput(
          controller: _nameController,
          focusNode: _nameFocusNode,
          hint: '请输入群聊名称',
        ),
        const SizedBox(height: 16),
        // 群聊描述
        const Text(
          '群聊描述',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _styledInput(
          controller: _descController,
          focusNode: _searchFocusNode,
          hint: '请输入群聊描述（选填）',
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        // 选择标签
        const Text(
          '选择标签',
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
          children: _groupTags.map(_tagChip).toList(),
        ),
        // 自定义标签
        if (_customTags.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            '自定义标签',
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
            children: _customTags.map(_tagChip).toList(),
          ),
        ],
        const SizedBox(height: 16),
        // 添加自定义标签
        const Text(
          '添加自定义标签',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _styledInput(
                controller: _customTagController,
                focusNode: FocusNode(),
                hint: '输入标签名称',
                showBorder: true,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap:
                  _customTagController.text.trim().isEmpty ? null : _addCustomTag,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.hoverBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: const Text(
                  '添加',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 提交按钮
        GestureDetector(
          onTap: _createGroup,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppColors.auroraGradient,
            ),
            child: const Center(
              child: Text(
                '提交申请',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
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
            // Tab 切换
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _tabButton('搜索群聊', 'search'),
                  const SizedBox(width: 8),
                  _tabButton('创建群聊', 'create'),
                ],
              ),
            ),
            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _activeTab == 'search' ? _searchTab() : _createTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
