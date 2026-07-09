import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class PublishPlanScreen extends StatefulWidget {
  const PublishPlanScreen({super.key});

  @override
  State<PublishPlanScreen> createState() => _PublishPlanScreenState();
}

class _PublishPlanScreenState extends State<PublishPlanScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _planDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _planTime = const TimeOfDay(hour: 8, minute: 0);
  bool _dailyCheckin = false;
  bool _isPublic = true;
  bool _publishing = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }  static const _rainbowColors = [


    Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),


    Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
  ];

  LinearGradient _diagonalGradient(Size size) {
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(0.785398));
  }

  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = '\u8bf7\u8f93\u5165\u8ba1\u5212\u540d\u79f0');
      return;
    }
    setState(() { _publishing = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('\u672a\u767b\u5f55');

      final scheduledAt = DateTime(
        _planDate.year, _planDate.month, _planDate.day,
        _planTime.hour, _planTime.minute,
      ).toUtc().toIso8601String();

      await Supabase.instance.client.from('posts').insert({
        'user_id': user.id,
        'content': _contentController.text.trim(),
        'title': _titleController.text.trim(),
        'visibility': _isPublic ? 'public' : 'private',
        'metadata': {
          'type': 'plan',
          'scheduled_at': scheduledAt,
          'daily_checkin': _dailyCheckin,
        },
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _publishing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('\u53d1\u5e03\u8ba1\u5212', style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _publishing ? null : _publish,
              child: LayoutBuilder(builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _diagonalGradient(size),
                ),
                child: _publishing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('\u53d1\u5e03', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              );
              }),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // \u6807\u9898
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: '\u8ba1\u5212\u540d\u79f0',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 18, fontWeight: FontWeight.w600),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 16),
            // \u5185\u5bb9
            TextField(
              controller: _contentController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: '\u63cf\u8ff0\u4f60\u7684\u8ba1\u5212...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),
            // \u65e5\u671f\u9009\u62e9
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _planDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _planDate = date);
              },
              child: _buildSettingRow(
                icon: Icons.calendar_today,
                label: '\u8ba1\u5212\u65e5\u671f',
                value: '${_planDate.year}-${_planDate.month.toString().padLeft(2, '0')}-${_planDate.day.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 12),
            // \u65f6\u95f4\u9009\u62e9
            GestureDetector(
              onTap: () async {
                final time = await showTimePicker(context: context, initialTime: _planTime);
                if (time != null) setState(() => _planTime = time);
              },
              child: _buildSettingRow(
                icon: Icons.access_time,
                label: '\u8ba1\u5212\u65f6\u95f4',
                value: '${_planTime.hour.toString().padLeft(2, '0')}:${_planTime.minute.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(height: 12),
            // \u6bcf\u65e5\u6253\u5361
            GestureDetector(
              onTap: () => setState(() => _dailyCheckin = !_dailyCheckin),
              child: _buildSwitchRow(
                icon: Icons.check_circle_outline,
                label: '\u6bcf\u65e5\u6253\u5361\u63d0\u9192',
                value: _dailyCheckin,
              ),
            ),
            const SizedBox(height: 12),
            // \u516c\u5f00/\u79c1\u5bc6
            GestureDetector(
              onTap: () => setState(() => _isPublic = !_isPublic),
              child: _buildSwitchRow(
                icon: _isPublic ? Icons.public : Icons.lock_outline,
                label: _isPublic ? '\u516c\u5f00\u8ba1\u5212' : '\u79c1\u5bc6\u8ba1\u5212',
                value: _isPublic,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.inputBg,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(value, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 18),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({required IconData icon, required String label, required bool value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.inputBg,
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.5), size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Switch(
            value: value,
            onChanged: (v) => setState(() {}),
            activeColor: const Color(0xFF00E5FF),
          ),
        ],
      ),
    );
  }
}
