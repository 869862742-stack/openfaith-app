import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class PublishPlanScreen extends StatefulWidget {
  const PublishPlanScreen({super.key});

  @override
  State<PublishPlanScreen> createState() => _PublishPlanScreenState();
}

class _PublishPlanScreenState extends State<PublishPlanScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _planDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _dailyCheckin = true;
  bool _isPublic = true;
  bool _publishing = false;
  String? _error;
  List<String> _selectedTags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = '请输入计划名称');
      return;
    }
    setState(() { _publishing = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('未登录');

      final scheduledAt = DateTime(
        _planDate.year, _planDate.month, _planDate.day,
        _startTime.hour, _startTime.minute,
      ).toUtc().toIso8601String();

      await Supabase.instance.client.from('posts').insert({
        'user_id': user.id,
        'content': _contentController.text.trim(),
        'title': _titleController.text.trim(),
        'visibility': _isPublic ? 'public' : 'private',
        'metadata': {
          'type': 'plan',
          'scheduled_at': scheduledAt,
          'end_time': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
          'daily_checkin': _dailyCheckin,
          'tags': _selectedTags,
        },
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceAll('Exception: ', ''); _publishing = false; });
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
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
                    '发起计划',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 发起按钮
                GestureDetector(
                  onTap: _publishing ? null : _publish,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: AppColors.auroraGradient,
                    ),
                    child: _publishing
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
                        : const Text('发起',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 计划名称
                  Text('计划名称', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '例如：每日晨间冥想30分钟',
                      hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderActive),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 日期
                  Text('日期', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 13)),
                  const SizedBox(height: 8),
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
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.inputBg,
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: AppColors.textPlaceholder),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDate(_planDate),
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 开始/结束时间
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('开始时间', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 13)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: _startTime);
                                if (time != null) setState(() => _startTime = time);
                              },
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppColors.inputBg,
                                  border: Border.all(color: AppColors.borderDefault),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: AppColors.textPlaceholder),
                                    const SizedBox(width: 8),
                                    Text(_formatTime(_startTime),
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('结束时间', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 13)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: _endTime);
                                if (time != null) setState(() => _endTime = time);
                              },
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppColors.inputBg,
                                  border: Border.all(color: AppColors.borderDefault),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: AppColors.textPlaceholder),
                                    const SizedBox(width: 8),
                                    Text(_formatTime(_endTime),
                                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 话题标签
                  Text('话题标签', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('标签选择器待集成'),
                          backgroundColor: AppColors.cardBg,
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDefault),
                        color: AppColors.inputBg,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedTags.isNotEmpty ? '已选 ${_selectedTags.length} 个标签' : '选择标签',
                              style: TextStyle(color: AppColors.iconColorWeak, fontSize: 14),
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
                            child: const Text('+', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _selectedTags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.hoverBgLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(tag, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 计划描述
                  Text('计划描述', style: TextStyle(color: AppColors.iconColorWeak, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '描述你的计划目标、内容安排...',
                      hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.inputBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.borderActive),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 打卡开关 - 对齐网页版
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDefault),
                      color: AppColors.hoverBgLight,
                    ),
                    child: Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
                          child: const Icon(Icons.check_circle_outline, color: AppColors.textPrimary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('开启打卡功能', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        ),
                        _buildSwitch(_dailyCheckin, (v) => setState(() => _dailyCheckin = v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 公开开关 - 对齐网页版
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDefault),
                      color: AppColors.hoverBgLight,
                    ),
                    child: Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
                          child: const Icon(Icons.people_outline, color: AppColors.textPrimary, size: 20),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('允许他人参与', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        ),
                        _buildSwitch(_isPublic, (v) => setState(() => _isPublic = v)),
                      ],
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? AppColors.headerBg : AppColors.hoverBg,
          border: value ? null : Border.all(color: AppColors.borderActive),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: value ? 24 : 2,
              top: 2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textPrimary,
                  boxShadow: [
                    BoxShadow(color: AppColors.overlay, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
