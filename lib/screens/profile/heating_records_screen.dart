import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class HeatingRecordsScreen extends StatefulWidget {
  const HeatingRecordsScreen({super.key});

  @override
  State<HeatingRecordsScreen> createState() => _HeatingRecordsScreenState();
}

class _HeatingRecordsScreenState extends State<HeatingRecordsScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  bool _checkedInToday = false;
  bool _checkinLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _checkTodayCheckin();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _records = []);
        return;
      }
      final resp = await Supabase.instance.client
          .from('checkin_records')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() => _records = (resp as List).cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('Load heating records error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkTodayCheckin() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final resp = await Supabase.instance.client
          .from('checkin_records')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', '${today}T00:00:00')
          .lte('created_at', '${today}T23:59:59')
          .limit(1);
      if (mounted) {
        setState(() => _checkedInToday = (resp as List).isNotEmpty);
      }
    } catch (e) {
      debugPrint('Check checkin error: $e');
    }
  }

  Future<void> _doCheckin() async {
    if (_checkedInToday || _checkinLoading) return;
    setState(() => _checkinLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('未登录');

      bool isVip = false;
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('is_vip')
            .eq('user_id', user.id)
            .maybeSingle();
        isVip = profile?['is_vip'] == true;
      } catch (_) {}

      final points = isVip ? 10 : 2;

      await Supabase.instance.client.from('checkin_records').insert({
        'user_id': user.id,
      });

      // Try RPC first, fallback to direct update
      try {
        await Supabase.instance.client.rpc('increment_hot_points', params: {
          'p_user_id': user.id,
          'p_amount': points,
        });
      } catch (_) {
        final current = await Supabase.instance.client
            .from('profiles')
            .select('hot_points')
            .eq('user_id', user.id)
            .maybeSingle();
        final currentPoints = (current?['hot_points'] as num?)?.toInt() ?? 0;
        await Supabase.instance.client
            .from('profiles')
            .update({'hot_points': currentPoints + points})
            .eq('user_id', user.id);
      }

      setState(() {
        _checkedInToday = true;
        _checkinLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('签到成功！+$points 热点'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadRecords(); // Reload records
      }
    } catch (e) {
      setState(() => _checkinLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('签到失败: $e'), backgroundColor: const Color(0xFFFF4D6D)),
        );
      }
    }
  }



  String _formatDate(String isoStr) {
    final dt = DateTime.parse(isoStr);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  int _getStreak() {
    if (_records.isEmpty) return 0;
    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final hasRecord = _records.any((r) {
        final dt = DateTime.parse(r['created_at']);
        return dt.year == checkDate.year && dt.month == checkDate.month && dt.day == checkDate.day;
      });
      if (hasRecord) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final streak = _getStreak();
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Column(
        children: [
          // Header - 对齐网页版
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).paddingTop + 16,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '🔥 加热记录',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.auroraOrange,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Streak card - 七彩边框
                        Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: AppColors.auroraGradient,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              color: AppColors.bgColor,
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.local_fire_department, color: AppColors.auroraOrange, size: 40),
                                const SizedBox(height: 8),
                                Text('连续打卡', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$streak',
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text('天', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('累计打卡 ${_records.length} 次',
                                    style: TextStyle(color: AppColors.iconColorWeak, fontSize: 12)),
                                const SizedBox(height: 16),
                                // 签到按钮
                                GestureDetector(
                                  onTap: _checkinLoading ? null : _doCheckin,
                                  child: _checkedInToday
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.hoverBgLight,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: AppColors.borderSubtle),
                                          ),
                                          child: const Text(
                                            '今日已签到 ✓',
                                            style: TextStyle(color: AppColors.textWeak, fontSize: 14),
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            gradient: const LinearGradient(
                                              colors: [AppColors.auroraOrange, AppColors.auroraRed],
                                            ),
                                          ),
                                          child: _checkinLoading
                                              ? const SizedBox(
                                                  width: 16, height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '立即签到 +2',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Records list
                        if (_records.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Column(
                              children: [
                                Icon(Icons.event_note, size: 48, color: AppColors.textPlaceholder.withOpacity(0.3)),
                                const SizedBox(height: 12),
                                Text('暂无打卡记录',
                                    style: TextStyle(color: AppColors.textPlaceholder, fontSize: 13)),
                              ],
                            ),
                          )
                        else
                          ..._records.map((record) {
                            final content = record['content'] ?? '';
                            final tags = record['tags'] as List? ?? [];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.hoverBgLight,
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: AppColors.auroraGreen, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDate(record['created_at']),
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  if (content.toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(content,
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                  ],
                                  if (tags.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: tags.cast<String>().map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: AppColors.hoverBgLight,
                                        ),
                                        child: Text('#$tag',
                                            style: TextStyle(color: AppColors.iconColorWeak, fontSize: 11)),
                                      )).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
