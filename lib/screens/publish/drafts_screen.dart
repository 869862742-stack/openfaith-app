import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rainbow_border.dart';

class DraftItem {
  final String id;
  final String content;
  final String title;
  final String? coverUrl;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  DraftItem({
    required this.id,
    required this.content,
    this.title = '',
    this.coverUrl,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'title': title,
    'coverUrl': coverUrl,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DraftItem.fromJson(Map<String, dynamic> json) => DraftItem(
    id: json['id'] as String,
    content: json['content'] as String,
    title: json['title'] as String? ?? '',
    coverUrl: json['coverUrl'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class DraftService {
  static const String _key = 'openfaith_drafts';

  static Future<List<DraftItem>> loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((e) => DraftItem.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDraft(DraftItem draft) async {
    final drafts = await loadDrafts();
    final idx = drafts.indexWhere((d) => d.id == draft.id);
    if (idx >= 0) {
      drafts[idx] = draft;
    } else {
      drafts.insert(0, draft);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(drafts.map((d) => d.toJson()).toList()));
  }

  static Future<void> deleteDraft(String id) async {
    final drafts = await loadDrafts();
    drafts.removeWhere((d) => d.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(drafts.map((d) => d.toJson()).toList()));
  }

  static Future<String> createDraftId() async {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key, this.onEditDraft});
  final void Function(DraftItem draft)? onEditDraft;

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  List<DraftItem> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _loading = true);
    final drafts = await DraftService.loadDrafts();
    setState(() {
      _drafts = drafts;
      _loading = false;
    });
  }

  void _deleteDraft(DraftItem draft) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除草稿', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('确定要删除这篇草稿吗？', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消', style: TextStyle(color: AppColors.textWeak)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await DraftService.deleteDraft(draft.id);
              _loadDrafts();
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Column(
        children: [
          // Header - 对齐网页版
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).paddingTop + 12,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgColor,
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
                    '草稿箱',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Spacer to center title
                const SizedBox(width: 36),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.auroraCyan))
                : _drafts.isEmpty
                    ? _buildEmptyState()
                    : _buildDraftList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined, size: 64, color: AppColors.textPlaceholder.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('暂无草稿', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14)),
          const SizedBox(height: 4),
          Text('发布笔记时保存的草稿会出现在这里',
              style: TextStyle(color: AppColors.textPlaceholder.withOpacity(0.4), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDraftList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _drafts.length,
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return RainbowBorder(
          borderRadius: 16,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        draft.title.isNotEmpty ? draft.title : '无标题',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: AppColors.iconColorWeak),
                      onPressed: () => _deleteDraft(draft),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  draft.content,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (draft.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: draft.tags.take(5).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.hoverBgLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(tag, style: TextStyle(color: AppColors.iconColorWeak, fontSize: 11)),
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  '更新于 ${_formatDate(draft.updatedAt)}',
                  style: TextStyle(color: AppColors.textPlaceholder, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }
}
