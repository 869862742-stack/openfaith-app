import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class HeatingRecordsScreen extends StatefulWidget {
  const HeatingRecordsScreen({super.key});

  @override
  State<HeatingRecordsScreen> createState() => _HeatingRecordsScreenState();
}

class _HeatingRecordsScreenState extends State<HeatingRecordsScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
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

  static const _rainbowGradient = LinearGradient(
    colors: [
      Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),
      Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
    ],
  transform: GradientRotation(0.125),
  );

  @override
  Widget build(BuildContext context) {
    final streak = _getStreak();
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('\u6253\u5361\u8bb0\u5f55', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white24))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Streak card
                  Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: _rainbowGradient,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        color: const Color(0xFF050816),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.local_fire_department, color: const Color(0xFFFF9F1C), size: 40),
                          const SizedBox(height: 8),
                          Text('\u8fde\u7eed\u6253\u5361', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$streak', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('\u5929', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('\u7d2f\u8ba1\u6253\u5361 ${_records.length} \u6b21',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
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
                          Icon(Icons.event_note, size: 48, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text('\u6682\u65e0\u6253\u5361\u8bb0\u5f55', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
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
                          color: AppColors.inputBg,
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Color(0xFF70E000), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDate(record['created_at']),
                                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                                ),
                              ],
                            ),
                            if (content.toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(content, style: const TextStyle(color: Colors.white, fontSize: 13)),
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
                                    color: Colors.white.withOpacity(0.06),
                                  ),
                                  child: Text('#$tag', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
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
    );
  }
}
