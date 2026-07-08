import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';

/// 浏览记录页 - 对齐网页版 History.tsx
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _recording = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('browse_history') ?? [];
    final items = raw.map((s) {
      try { return jsonDecode(s) as Map<String, dynamic>; } catch (_) { return <String, dynamic>{}; }
    }).where((m) => m.isNotEmpty).toList();
    final rec = prefs.getBool('history_recording') ?? true;
    setState(() { _history = items; _recording = rec; });
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('清空记录', style: TextStyle(color: Colors.white)),
        content: const Text('确定要清空所有浏览记录吗？', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('取消', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('清空', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('browse_history');
      setState(() => _history = []);
    }
  }

  void _toggleRecording() async {
    final newVal = !_recording;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('history_recording', newVal);
    setState(() => _recording = newVal);
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
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('浏览记录', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 顶部操作栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_recording ? Icons.fiber_manual_record : Icons.pause_circle_outline,
                            size: 14, color: _recording ? AppColors.error : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(_recording ? '记录中' : '已暂停',
                            style: TextStyle(color: _recording ? AppColors.error : AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (_history.isNotEmpty)
                  GestureDetector(
                    onTap: _clearHistory,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: const Text('清空', style: TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.history, color: Colors.white.withOpacity(0.2), size: 48),
                      const SizedBox(height: 12),
                      const Text('暂无浏览记录', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    ]),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: const Icon(Icons.article_outlined, color: AppColors.textSecondary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item['title']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (item['author'] != null) ...[
                                  const SizedBox(height: 2),
                                  Text('by ${item['author']}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ],
                                const SizedBox(height: 2),
                                Text(_formatTime(item['viewed_at']?.toString() ?? ''), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              ]),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
