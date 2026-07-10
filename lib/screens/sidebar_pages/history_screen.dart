import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rainbow_border.dart';

/// 浏览记录页 - 对齐网页版 History.tsx
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _recording = true;
  String? _longPressItemId;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('browse_history') ?? [];
    final items = raw.map((s) {
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((m) => m.isNotEmpty).toList();
    final rec = prefs.getBool('history_recording') ?? true;
    setState(() {
      _history = items;
      _recording = rec;
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('browse_history');
    setState(() => _history = []);
    setState(() => _longPressItemId = null);
  }

  void _toggleRecording() async {
    final newVal = !_recording;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('history_recording', newVal);
    setState(() => _recording = newVal);
  }

  void _deleteSingleRecord(String id) {
    try {
      final raw = _history
          .where((m) => m['id']?.toString() != id)
          .map((e) => jsonEncode(e))
          .toList();
      SharedPreferences.getInstance().then((prefs) {
        prefs.setStringList('browse_history', raw);
      });
    } catch (_) {}
    setState(() {
      _history.removeWhere((m) => m['id']?.toString() == id);
      _longPressItemId = null;
    });
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
      if (diff.inDays < 1) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }

  /// 按日期分组
  Map<String, List<Map<String, dynamic>>> _groupedByDate() {
    final groups = <String, List<Map<String, dynamic>>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final item in _history) {
      try {
        final dt = DateTime.parse(item['viewed_at']?.toString() ?? '');
        final dateOnly = DateTime(dt.year, dt.month, dt.day);
        String label;
        if (dateOnly == today) {
          label = '今天';
        } else if (dateOnly == yesterday) {
          label = '昨天';
        } else {
          label = '${dt.month}月${dt.day}日';
        }
        groups.putIfAbsent(label, () => []).add(item);
      } catch (_) {}
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedByDate();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 毛玻璃 Header ──
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.headerBg,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.borderDefault,
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '浏览记录',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleRecording,
                        child: Text(
                          _recording ? '关闭记录' : '开启记录',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 内容区域 ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 清空浏览记录按钮 - 七彩渐变边框
                  RainbowBorder(
                    borderRadius: 12,
                    borderWidth: 1,
                    child: GestureDetector(
                      onTap: _clearHistory,
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '清空浏览记录',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_history.isEmpty) ...[
                    // 空状态
                    const SizedBox(height: 48),
                    Icon(
                      Icons.visibility_outlined,
                      color: AppColors.textSecondary.withOpacity(0.3),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '暂无浏览记录',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '浏览笔记时会自动记录',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    // 分组列表
                    ...grouped.entries.expand((entry) {
                      final dateLabel = entry.key;
                      final items = entry.value;
                      return [
                        // 日期标签
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: AppColors.textSecondary,
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateLabel,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${items.length})',
                                style: TextStyle(
                                  color: AppColors.textSecondary
                      .withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 列表项
                        ...items.map((item) => _buildHistoryItem(item)),
                        const SizedBox(height: 16),
                      ];
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final itemId = item['id']?.toString() ?? '';
    final title = item['title']?.toString() ?? '';
    final author = item['author_name']?.toString() ?? '';
    final tags = item['tags'];
    final firstTag = (tags is List && tags.isNotEmpty)
        ? tags[0]?.toString() ?? ''
        : '';
    final viewedAt = item['viewed_at']?.toString() ?? '';
    final coverImage = item['cover_image']?.toString();

    return GestureDetector(
      onTap: () {
        // TODO: 打开笔记详情
      },
      onLongPress: () {
        setState(() => _longPressItemId = itemId);
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // 封面缩略图
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.hoverBgLight,
                  ),
                  child: coverImage != null && coverImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            coverImage,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildDefaultCover(),
                          ),
                        )
                      : _buildDefaultCover(),
                ),
                const SizedBox(width: 12),
                // 标题 + 标签 + 作者 + 时间
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (firstTag.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              firstTag,
                              style: TextStyle(
                                color: AppColors.textPlaceholder,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (author.isNotEmpty) ...[
                            Text(
                              author,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _formatTime(viewedAt),
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 长按删除遮罩
          if (_longPressItemId == itemId)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.overlay.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: RainbowBorder(
                          borderRadius: 12,
                          borderWidth: 0.5,
                          opacity: 0.5,
                          child: GestureDetector(
                            onTap: () => _deleteSingleRecord(itemId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: AppColors.textPrimary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '删除此记录',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _longPressItemId = null),
                          child: Icon(
                            Icons.close,
                            color: AppColors.iconColorWeak,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDefaultCover() {
    return const Center(
      child: Text('📖', style: TextStyle(fontSize: 18)),
    );
  }
}
