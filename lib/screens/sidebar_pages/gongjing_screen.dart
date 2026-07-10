import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rainbow_border.dart';
import '../gongjing/silent_room_screen.dart';

/// 共境页面 - 对齐网页版 Gongjing.tsx
/// 包含四大功能入口：静默同行、世界呼吸时刻、树洞回声、无界圆桌
class GongjingScreen extends StatefulWidget {
  const GongjingScreen({super.key});
  @override
  State<GongjingScreen> createState() => _GongjingScreenState();
}

class _GongjingScreenState extends State<GongjingScreen> {
  final _supabase = Supabase.instance.client;
  int _onlineCount = 0;
  String _activeTab = 'silent';

  // ── 静默同行状态 ──
  String _selectedStatus = '安静中';
  int _selectedDuration = 30;
  String? _musicName;
  String? _musicPath;
  String? _musicFileSize;
  bool _creating = false;
  String? _error;

  // ── 世界呼吸时刻状态 ──
  String _breathingStatus = '安静中';
  int _participantCount = 0;
  bool _isInBreathing = false;
  String? _breathingTheme;

  // ── 树洞回声状态 ──
  final _echoCtrl = TextEditingController();
  bool _isAnonymous = true;
  List<Map<String, dynamic>> _echoList = [];
  bool _echoLoading = false;
  bool _echoSubmitting = false;
  String? _echoError;
  Set<String> _expandedEchoIds = {};
  Map<String, TextEditingController> _replyCtrls = {};
  Map<String, Set<String>> _userReactions = {};

  // ── 无界圆桌状态 ──
  List<Map<String, dynamic>> _roundtables = [];
  bool _roundtablesLoading = false;

  // 状态选项
  static const _statusOptions = [
    {'id': '安静中', 'icon': Icons.nights_stay},
    {'id': '阅读中', 'icon': Icons.menu_book},
    {'id': '反思中', 'icon': Icons.favorite},
    {'id': '冥想中', 'icon': Icons.psychology},
    {'id': '祈祷时', 'icon': Icons.self_improvement},
  ];

  // 呼吸时刻状态选项（增加"感恩中"）
  static const _breathingStatusOptions = [
    {'id': '安静中', 'icon': Icons.nights_stay},
    {'id': '阅读中', 'icon': Icons.menu_book},
    {'id': '反思中', 'icon': Icons.favorite},
    {'id': '冥想中', 'icon': Icons.psychology},
    {'id': '祈祷时', 'icon': Icons.self_improvement},
    {'id': '感恩中', 'emoji': '🙏'},
  ];

  // 时长选项
  static const _durationOptions = [
    {'value': 15, 'label': '15分钟'},
    {'value': 30, 'label': '30分钟'},
    {'value': 60, 'label': '1小时'},
  ];

  // 回声反应类型
  static const _reactionTypes = [
    {'id': 'resonated', 'emoji': '🤍', 'label': 'Resonated'},
    {'id': 'understand', 'emoji': '🌿', 'label': 'I Understand'},
    {'id': 'with_you', 'emoji': '✨', 'label': 'With You'},
    {'id': 'quiet_support', 'emoji': '🌙', 'label': 'Quiet Support'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchOnline();
  }

  @override
  void dispose() {
    _echoCtrl.dispose();
    for (final ctrl in _replyCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchOnline() async {
    try {
      final fiveMinAgo =
          DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String();
      final res = await _supabase
          .from('profiles')
          .select('id')
          .gte('last_online_at', fiveMinAgo);
      if (!mounted) return;
      if (res != null) setState(() => _onlineCount = res.length);
    } catch (e) { debugPrint('获取在线人数失败: $e'); }
  }

  // ── 加载回声列表 ──
  Future<void> _loadEchoList() async {
    setState(() => _echoLoading = true);
    try {
      final data = await _supabase
          .from('echo_shares')
          .select('*,echo_echoes(*),echo_reactions(*)')
          .order('created_at', ascending: false)
          .limit(30);
      if (data != null) {
        if (!mounted) return;
        setState(() {
          _echoList = List<Map<String, dynamic>>.from(data);
        });
        // Load user reactions
        final userId = _supabase.auth.currentUser?.id;
        if (userId != null) {
          final reactions = <String, Set<String>>{};
          for (final share in _echoList) {
            final shareId = share['id']?.toString() ?? '';
            final shareReactions = share['echo_reactions'] as List? ?? [];
            final userTypes = shareReactions
                .whereType<Map>()
                .where((r) => r['user_id'] == userId)
                .map((r) => r['reaction_type']?.toString() ?? '')
                .where((t) => t.isNotEmpty)
                .toSet();
            if (userTypes.isNotEmpty) {
              reactions[shareId] = userTypes;
            }
          }
          if (!mounted) return;
          setState(() => _userReactions = reactions);
        }
      }
    } catch (e) {
      debugPrint('Load echo list error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _echoLoading = false);
    }
  }

  // ── 加载圆桌列表 ──
  Future<void> _loadRoundtables() async {
    setState(() => _roundtablesLoading = true);
    try {
      final data = await _supabase
          .from('roundtables')
          .select()
          .order('created_at', ascending: false);
      if (data != null) {
        if (!mounted) return;
        setState(() {
          _roundtables = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Load roundtables error: $e');
    } finally {
      if (!mounted) return;
      setState(() => _roundtablesLoading = false);
    }
  }

  // ── 加载呼吸数据 ──
  Future<void> _loadBreathingData() async {
    try {
      final themes = await _supabase
          .from('breathing_moments')
          .select()
          .order('created_at', ascending: false)
          .limit(1);
      if (themes != null && themes.isNotEmpty && themes[0]['theme'] != null) {
        if (!mounted) return;
        setState(() => _breathingTheme = themes[0]['theme']);
      }
      final participants = await _supabase
          .from('room_participants')
          .select('user_id,rooms!inner(type,status)')
          .eq('status', 'quiet');
      if (participants != null) {
        // Count unique users in world_breathing rooms
        // Simplified: just count all quiet participants
        if (!mounted) return;
        setState(() => _participantCount = participants.length);
      }
    } catch (e) {
      debugPrint('Load breathing data error: $e');
    }
  }

  Future<void> _handleEnterSilent() async {
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('请先登录');

      // 创建新房间
      final insertData = <String, dynamic>{
        'creator_id': user.id,
        'name': '静默空间',
        'description': '',
        'tags': <String>[],
        'user_count': 1,
        'room_code': DateTime.now().millisecondsSinceEpoch % 1000000,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (_musicPath != null && _musicPath!.isNotEmpty) {
        insertData['custom_audio_url'] = _musicPath;
      }

      final result = await _supabase
          .from('rooms')
          .insert(insertData)
          .select('id')
          .maybeSingle();

      if (result == null || result['id'] == null) {
        throw Exception('创建房间失败');
      }

      final roomId = result['id'].toString();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SilentRoomScreen(roomId: roomId),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _creating = false;
        });
      }
    }
  }

  void _handleEnterBreathing() {
    _loadBreathingData();
    setState(() => _isInBreathing = true);
  }

  void _handleExitBreathing() {
    setState(() => _isInBreathing = false);
  }

  Future<void> _handlePublishEcho() async {
    if (_echoCtrl.text.trim().isEmpty) return;
    setState(() => _echoSubmitting = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('echo_shares').insert({
        'user_id': userId,
        'content': _echoCtrl.text.trim(),
        'author_name': _isAnonymous ? null : 'User',
      });
      _echoCtrl.clear();
      await _loadEchoList();
    } catch (e) {
      if (!mounted) return;
      setState(() => _echoError = '发布失败: $e');
    } finally {
      if (!mounted) return;
      setState(() => _echoSubmitting = false);
    }
  }

  Future<void> _handlePublishEchoReply(String shareId) async {
    final ctrl = _replyCtrls[shareId];
    if (ctrl == null || ctrl.text.trim().isEmpty) return;
    try {
      final userId = _supabase.auth.currentUser?.id;
      await _supabase.from('echo_echoes').insert({
        'share_id': shareId,
        'user_id': userId,
        'content': ctrl.text.trim(),
      });
      ctrl.clear();
      if (!mounted) return;
      setState(() => _expandedEchoIds.remove(shareId));
      await _loadEchoList();
    } catch (e) {
      debugPrint('Reply error: $e');
    }
  }

  Future<void> _handleToggleReaction(String shareId, String reactionType) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final hasReacted =
          (_userReactions[shareId] ?? {}).contains(reactionType);
      if (hasReacted) {
        await _supabase
            .from('echo_reactions')
            .delete()
            .eq('share_id', shareId)
            .eq('user_id', userId)
            .eq('reaction_type', reactionType);
        if (!mounted) return;
        setState(() {
          _userReactions[shareId]?.remove(reactionType);
        });
      } else {
        await _supabase.from('echo_reactions').insert({
          'share_id': shareId,
          'user_id': userId,
          'reaction_type': reactionType,
        });
        if (!mounted) return;
        setState(() {
          _userReactions.putIfAbsent(shareId, () => {}).add(reactionType);
        });
      }
    } catch (e) {
      debugPrint('Toggle reaction error: $e');
    }
  }

  Future<void> _handleDeleteShare(String shareId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase
          .from('echo_shares')
          .delete()
          .eq('id', shareId)
          .eq('user_id', userId);
      await _loadEchoList();
    } catch (e) {
      debugPrint('Delete share error: $e');
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final diff = DateTime.now().difference(date).inSeconds;
      if (diff < 60) return '刚刚';
      if (diff < 3600) return '${diff ~/ 60}分钟前';
      if (diff < 86400) return '${diff ~/ 3600}小时前';
      if (diff < 604800) return '${diff ~/ 86400}天前';
      return '${date.month}/${date.day}';
    } catch (_) {
      return '';
    }
  }

  String? _getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  String _getDisplayName(Map<String, dynamic> share) {
    final authorName = share['author_name'];
    if (authorName != null && authorName.toString().isNotEmpty) {
      return authorName.toString();
    }
    return 'Anonymous Soul';
  }

  bool _isNightMode() {
    final hour = DateTime.now().hour;
    return hour >= 22 || hour < 6;
  }

  void _onTabChanged(String tab) {
    setState(() {
      _activeTab = tab;
      _isInBreathing = false;
    });
    // Load data when switching tabs
    switch (tab) {
      case 'breathing':
        _loadBreathingData();
        break;
      case 'echo':
        _loadEchoList();
        break;
      case 'roundtable':
        _loadRoundtables();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── 毛玻璃 Header + Tab ──
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.headerBg,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.borderSubtle,
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Nav bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              '共境',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 36),
                          ],
                        ),
                      ),
                      // Tab bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            _buildTabButton('silent', '静默同行'),
                            const SizedBox(width: 8),
                            _buildTabButton('breathing', '世界呼吸'),
                            const SizedBox(width: 8),
                            _buildTabButton('echo', '树洞回声'),
                            const SizedBox(width: 8),
                            _buildTabButton('roundtable', '无界圆桌'),
                          ],
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
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isActive ? AppColors.auroraGradientWithOpacity(0.8) : null,
            color: isActive ? null : AppColors.hoverBgLight,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.auroraRed.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: AppColors.auroraCyan.withOpacity(0.2),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Container(
            decoration: isActive
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: AppColors.bgColor,
                  )
                : null,
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppColors.textPrimary
                    : AppColors.textWeak,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'silent':
        return _buildSilentWalkTab();
      case 'breathing':
        return _buildBreathingTab();
      case 'echo':
        return _buildEchoTab();
      case 'roundtable':
        return _buildRoundtableTab();
      default:
        return const SizedBox();
    }
  }

  // ══════════════════════════════════════════════════
  // 静默同行 Tab
  // ══════════════════════════════════════════════════
  Widget _buildSilentWalkTab() {
    return Column(
      children: [
        // 标题区域
        const Icon(Icons.nights_stay, color: AppColors.textPrimary, size: 32),
        const SizedBox(height: 16),
        const Text(
          '静默同行',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '一对一安静陪伴',
          style: TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 48),

        // 状态选择
        Text(
          '此刻你的状态',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: _statusOptions.map((status) {
            final id = status['id'] as String;
            final icon = status['icon'] as IconData;
            final isSelected = _selectedStatus == id;
            return GestureDetector(
              onTap: () => setState(() => _selectedStatus = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected
                      ? AppColors.hoverBg
                      : AppColors.hoverBgLight,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.borderActive
                        : AppColors.borderDefault,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.textPrimary.withOpacity(0.1),
                            blurRadius: 20,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.iconColorWeak,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      id,
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 48),

        // 时长选择
        Text(
          '陪伴时长',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _durationOptions.map((option) {
            final value = option['value'] as int;
            final label = option['label'] as String;
            final isSelected = _selectedDuration == value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedDuration = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isSelected
                        ? AppColors.hoverBg
                        : AppColors.hoverBgLight,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.borderActive
                          : AppColors.borderDefault,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.auroraCyan.withOpacity(0.2),
                              blurRadius: 15,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 48),

        // 音乐上传（可选）
        Text(
          '背景音乐（可选）',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'flac'],
            );
            if (result != null && result.files.isNotEmpty) {
              final file = result.files.first;
              final sizeMB = (file.size / 1024 / 1024);
              final sizeStr = sizeMB >= 1
                  ? '${sizeMB.toStringAsFixed(1)} MB'
                  : '${(file.size / 1024).toStringAsFixed(0)} KB';
              if (!mounted) return;
              setState(() {
                _musicName = file.name;
                _musicPath = file.path;
                _musicFileSize = sizeStr;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.hoverBgLight,
              borderRadius: BorderRadius.circular(16),
              border: _musicName != null
                  ? Border.all(color: AppColors.borderActive)
                  : Border.all(
                      color: AppColors.borderDefault,
                      style: BorderStyle.solid,
                    ),
            ),
            child: _musicName != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _musicName!,
                          style: TextStyle(
                            color: AppColors.textPrimary.withOpacity(0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _musicName = null;
                        }),
                        child: Text(
                          '×',
                          style: TextStyle(
                            color: AppColors.textWeak,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.upload_file,
                        color: AppColors.textPlaceholder,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击上传 MP3 / WAV / AAC',
                        style: TextStyle(
                          color: AppColors.textWeak,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),

        // 错误提示
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.auroraBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textPrimary.withOpacity(0.1),
              ),
            ),
            child: Text(
              _error!,
              style: TextStyle(
                color: AppColors.auroraBlue.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // 进入按钮
        GestureDetector(
          onTap: _creating ? null : _handleEnterSilent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderActive,
                width: 1,
              ),
              gradient: AppColors.auroraGradientWithOpacity(0.3),
              backgroundBlendMode: BlendMode.srcOver,
              color: AppColors.headerBg,
              boxShadow: _creating
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.auroraCyan.withOpacity(0.1),
                        blurRadius: 20,
                      ),
                    ],
            ),
            child: Center(
              child: _creating
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '正在进入...',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      '进入静默同行',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 64),

        // 底部提示
        Text(
          'In silence, we find each other.',
          style: TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // 世界呼吸时刻 Tab
  // ══════════════════════════════════════════════════
  Widget _buildBreathingTab() {
    if (_isInBreathing) {
      return _buildBreathingImmersionView();
    }
    return _buildBreathingPreparationView();
  }

  Widget _buildBreathingPreparationView() {
    return Column(
      children: [
        // 标题区域
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.textPrimary.withOpacity(0.18),
                AppColors.textPrimary.withOpacity(0.06),
                Colors.transparent,
              ],
            ),
          ),
          child: const Icon(
            Icons.public,
            color: AppColors.textPrimary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '世界呼吸时刻',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '与世界各地的人一起静默',
          style: TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 48),

        // 地球动画占位 - 光点效果
        _buildEarthDots(200),
        const SizedBox(height: 48),

        Text(
          'Every light is someone awake tonight.',
          style: TextStyle(
            color: AppColors.textWeak,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 56),

        // 主题或等待
        if (_breathingTheme == null || _breathingTheme!.isEmpty) ...[
          // 等待界面
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.hoverBgLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '主题暂未发布，请等待',
                  style: TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_participantCount 人正在等待',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // 今日主题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppColors.auroraGradientWithOpacity(0.1),
              border: Border.all(
                color: AppColors.borderActive,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withOpacity(0.05),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '今晚主题',
                  style: TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _breathingTheme!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 实时状态
          Text(
            '$_participantCount people are quietly present now',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'The world is breathing quietly together.',
            style: TextStyle(
              color: AppColors.textWeak,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // 状态选择
          Text(
            '此刻你的状态',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: _breathingStatusOptions.map((status) {
              final id = status['id'] as String;
              final isSelected = _breathingStatus == id;
              final emoji = status['emoji'] as String?;
              final icon = status['icon'] as IconData?;
              return GestureDetector(
                onTap: () => setState(() => _breathingStatus = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected
                        ? AppColors.hoverBg
                        : AppColors.hoverBgLight,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.borderActive
                          : AppColors.borderDefault,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (emoji != null)
                        Text(emoji, style: const TextStyle(fontSize: 18))
                      else if (icon != null)
                        Icon(
                          icon,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.iconColorWeak,
                          size: 24,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        id,
                        style: TextStyle(
                          color: AppColors.textPrimary.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 24),

        // 进入按钮
        GestureDetector(
          onTap: _handleEnterBreathing,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.borderActive,
                width: 1,
              ),
              color: AppColors.bgColor,
              gradient: AppColors.auroraGradientWithOpacity(0.3),
              backgroundBlendMode: BlendMode.srcOver,
              boxShadow: [
                BoxShadow(
                  color: AppColors.auroraCyan.withOpacity(0.2),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Text(
              '进入世界呼吸时刻',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 64),

        // 底部提示
        Text(
          'Tonight, the world slowed down together.',
          style: TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBreathingImmersionView() {
    return Column(
      children: [
        // 退出按钮
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _handleExitBreathing,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.hoverBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '退出',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),

        // 地球光点
        _buildEarthDots(240),
        const SizedBox(height: 24),

        // 参与人数
        Text(
          '$_participantCount 人此刻同行',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '点击地球查看各洲分布',
          style: TextStyle(
            color: AppColors.textWeak,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // 当前主题
        if (_breathingTheme != null && _breathingTheme!.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppColors.auroraGradientWithOpacity(0.1),
              border: Border.all(
                color: AppColors.borderActive,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '此刻主题',
                  style: TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _breathingTheme!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // 状态选择
        Text(
          '此刻你的状态',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _breathingStatusOptions.map((status) {
            final id = status['id'] as String;
            final isSelected = _breathingStatus == id;
            final emoji = status['emoji'] as String?;
            final icon = status['icon'] as IconData?;
            return GestureDetector(
              onTap: () => setState(() => _breathingStatus = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? AppColors.hoverBg
                      : AppColors.hoverBgLight,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.borderActive
                        : AppColors.borderDefault,
                  ),
                ),
                child: Column(
                  children: [
                    if (emoji != null)
                      Text(emoji, style: const TextStyle(fontSize: 16))
                    else if (icon != null)
                      Icon(
                        icon,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.iconColorWeak,
                        size: 20,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      id,
                      style: TextStyle(
                        color: AppColors.textPrimary.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 地球光点效果（静态展示）
  Widget _buildEarthDots(double size) {
    // 简化版世界地图光点
    final dots = <Map<String, double>>[];
    for (int i = 0; i < 60; i++) {
      dots.add({
        'x': (i * 17 + 5) % 100,
        'y': (i * 13 + 8) % 100,
      });
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: dots.asMap().entries.map((entry) {
          final i = entry.key;
          final dot = entry.value;
          final colors = AppColors.auroraColors;
          final color = colors[i % colors.length];
          return Positioned(
            left: dot['x']! / 100 * size,
            top: dot['y']! / 100 * size,
            child: Container(
              width: 2.5,
              height: 2.5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // 树洞回声 Tab
  // ══════════════════════════════════════════════════
  Widget _buildEchoTab() {
    final isNight = _isNightMode();
    final currentUserId = _getCurrentUserId();

    return Column(
      children: [
        // 标题区域
        const Icon(
          Icons.chat_bubble_outline,
          color: AppColors.textPrimary,
          size: 32,
        ),
        const SizedBox(height: 16),
        const Text(
          '树洞回声',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '让人被温柔倾听',
          style: TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 48),

        // 深夜模式提示
        if (isNight) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppColors.auroraGradientWithOpacity(0.1),
              border: Border.all(
                color: AppColors.borderActive,
                width: 1,
              ),
            ),
            child: Text(
              '🌙 Night Echo Mode — The world feels quieter tonight.',
              style: TextStyle(
                color: AppColors.textWeak,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        // 发布区域
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppColors.auroraGradientWithOpacity(0.08),
            border: Border.all(
              color: AppColors.borderActive,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // 匿名/公开选择
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '发布身份',
                    style: TextStyle(
                      color: AppColors.textWeak,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.hoverBgLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.borderActive,
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isAnonymous = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isAnonymous
                                  ? AppColors.hoverBg
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: _isAnonymous
                                  ? Border.all(
                                      color: AppColors.borderActive)
                                  : null,
                            ),
                            child: Text(
                              '匿名',
                              style: TextStyle(
                                color: _isAnonymous
                                    ? AppColors.textPrimary
                                    : AppColors.textWeak,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isAnonymous = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: !_isAnonymous
                                  ? AppColors.hoverBg
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: !_isAnonymous
                                  ? Border.all(
                                      color: AppColors.borderActive)
                                  : null,
                            ),
                            child: Text(
                              '公开',
                              style: TextStyle(
                                color: !_isAnonymous
                                    ? AppColors.textPrimary
                                    : AppColors.textWeak,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 身份标识
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(
                      Icons.nights_stay,
                      color: AppColors.textPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isAnonymous ? 'Anonymous Soul' : '你的昵称',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 输入框
              TextField(
                controller: _echoCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: _isAnonymous
                      ? '在这里说出你的心里话...'
                      : '以真实身份分享...',
                  hintStyle: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 14,
                  ),
                  counterStyle: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: AppColors.hoverBgLight,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.borderActive,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.borderActive,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.borderActive,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 发布按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_echoCtrl.text.length}/200',
                    style: TextStyle(
                      color: AppColors.textPlaceholder,
                      fontSize: 12,
                    ),
                  ),
                  GestureDetector(
                    onTap: _echoSubmitting || _echoCtrl.text.trim().isEmpty
                        ? null
                        : _handlePublishEcho,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.hoverBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.borderDefault,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_echoSubmitting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textPrimary,
                              ),
                            )
                          else
                            Icon(
                              Icons.send,
                              color: AppColors.textPrimary,
                              size: 16,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '留下回声',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 错误提示
              if (_echoError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.auroraBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.textPrimary.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    _echoError!,
                    style: TextStyle(
                      color: AppColors.auroraBlue.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 回声列表
        if (_echoLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.textPlaceholder,
              ),
            ),
          )
        else if (_echoList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  Icons.nights_stay,
                  color: AppColors.textPrimary.withOpacity(0.2),
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无回声，成为第一个倾诉者',
                  style: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ..._echoList.map((share) => _buildEchoCard(share, currentUserId)),

        const SizedBox(height: 40),
        // 安全提示
        Text(
          'Share experiences, not arguments.',
          style: TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '这里不是辩论区，而是被倾听的角落',
          style: TextStyle(
            color: AppColors.textPrimary.withOpacity(0.2),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEchoCard(Map<String, dynamic> share, String? currentUserId) {
    final shareId = share['id']?.toString() ?? '';
    final isExpanded = _expandedEchoIds.contains(shareId);
    final echoes = share['echo_echoes'] as List? ?? [];
    final reactions = share['echo_reactions'] as List? ?? [];
    final isOwner = currentUserId == share['user_id'];
    final isNight = _isNightMode();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.auroraGradientWithOpacity(0.05),
        border: Border.all(
          color: AppColors.borderActive,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 发布者信息
          Row(
            children: [
              Icon(
                Icons.nights_stay,
                color: AppColors.textPrimary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _getDisplayName(share),
                style: TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '·',
                style: TextStyle(
                  color: AppColors.textPlaceholder,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(share['created_at']),
                style: TextStyle(
                  color: AppColors.textPlaceholder,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (isOwner)
                GestureDetector(
                  onTap: () => _handleDeleteShare(shareId),
                  child: Icon(
                    Icons.close,
                    color: AppColors.textPlaceholder,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 内容
          Text(
            share['content']?.toString() ?? '',
            style: TextStyle(
              color: AppColors.textPrimary.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // 反应按钮
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reactionTypes.map((reaction) {
              final rId = reaction['id'] as String;
              final emoji = reaction['emoji'] as String;
              final label = reaction['label'] as String;
              final hasReacted =
                  (_userReactions[shareId] ?? {}).contains(rId);
              final count = reactions
                  .whereType<Map>()
                  .where((r) => r['reaction_type'] == rId)
                  .length;

              return GestureDetector(
                onTap: () => _handleToggleReaction(shareId, rId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hasReacted
                        ? AppColors.hoverBg
                        : AppColors.hoverBgLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasReacted
                          ? AppColors.borderActive
                          : AppColors.borderDefault,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: hasReacted
                              ? AppColors.textPrimary
                              : AppColors.textWeak,
                          fontSize: 12,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '($count)',
                          style: TextStyle(
                            color: AppColors.textPlaceholder,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 回声回复列表
          if (echoes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColors.textPrimary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: echoes.map((echo) {
                  final echoMap = echo as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.hoverBgLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: AppColors.textPrimary,
                              size: 12,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Anonymous Soul',
                              style: TextStyle(
                                color: AppColors.textWeak,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '·',
                              style: TextStyle(
                                color: AppColors.textPrimary
                                    .withOpacity(0.2),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(echoMap['created_at']),
                              style: TextStyle(
                                color: AppColors.textPrimary
                                    .withOpacity(0.2),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          echoMap['content']?.toString() ?? '',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 留下回声按钮
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedEchoIds.remove(shareId);
                } else {
                  _expandedEchoIds.add(shareId);
                  _replyCtrls.putIfAbsent(
                    shareId,
                    () => TextEditingController(),
                  );
                }
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.volume_up,
                  color: AppColors.textPlaceholder,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '留下回声',
                  style: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 回复输入框
          if (isExpanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.textPrimary.withOpacity(0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _replyCtrls[shareId],
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: '轻轻回应...',
                      hintStyle: TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 14,
                      ),
                      counterStyle: TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.hoverBgLight,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.borderActive,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.borderActive,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.borderActive,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_replyCtrls[shareId]?.text.length ?? 0}/100',
                        style: TextStyle(
                          color: AppColors.textPlaceholder,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedEchoIds.remove(shareId);
                                _replyCtrls[shareId]?.clear();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: Text(
                                '取消',
                                style: TextStyle(
                                  color: AppColors.textWeak,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final text =
                                  _replyCtrls[shareId]?.text.trim() ?? '';
                              if (text.isNotEmpty) {
                                _handlePublishEchoReply(shareId);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (_replyCtrls[shareId]?.text.trim() ?? '')
                                        .isNotEmpty
                                    ? AppColors.hoverBg
                                    : AppColors.hoverBgLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '发送',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // 无界圆桌 Tab
  // ══════════════════════════════════════════════════
  Widget _buildRoundtableTab() {
    return Column(
      children: [
        // 标题区域
        const Icon(
          Icons.forum_outlined,
          color: AppColors.textPrimary,
          size: 32,
        ),
        const SizedBox(height: 16),
        const Text(
          '无界圆桌',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '哲思与信仰的对话场',
          style: TextStyle(
            color: AppColors.textWeak,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 48),

        // 圆桌列表
        if (_roundtablesLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.textPlaceholder,
              ),
            ),
          )
        else if (_roundtables.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  Icons.forum_outlined,
                  color: AppColors.textPrimary.withOpacity(0.2),
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无进行中的圆桌',
                  style: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '成为第一个创建者吧',
                  style: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ..._roundtables.map((rt) => _buildRoundtableCard(rt)),

        const SizedBox(height: 32),

        // 底部按钮
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('主持人申请功能开发中...'),
                backgroundColor: AppColors.overlayBg,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.borderActive,
                width: 1,
              ),
              color: AppColors.bgColor,
              gradient: AppColors.auroraGradientWithOpacity(0.3),
              backgroundBlendMode: BlendMode.srcOver,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '申请成为主持人',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // 底部引用
        Text(
          'Where wisdom meets across faiths.',
          style: TextStyle(
            color: AppColors.textPlaceholder,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '哲思与信仰，在对话中相遇',
          style: TextStyle(
            color: AppColors.textPrimary.withOpacity(0.2),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoundtableCard(Map<String, dynamic> rt) {
    final status = rt['status']?.toString() ?? 'waiting';
    String statusText;
    Color statusColor;
    switch (status) {
      case 'active':
        statusText = '进行中';
        statusColor = AppColors.auroraCyan;
        break;
      case 'waiting':
        statusText = '等待开始';
        statusColor = AppColors.auroraBlue;
        break;
      default:
        statusText = '已结束';
        statusColor = AppColors.textWeak;
    }

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('进入圆桌: ${rt['topic'] ?? ''}'),
            backgroundColor: AppColors.overlayBg,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.auroraGradientWithOpacity(0.08),
          border: Border.all(
            color: AppColors.borderActive,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rt['topic']?.toString() ?? '',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '主持人: ${rt['moderator_name'] ?? '未知'}',
                        style: TextStyle(
                          color: AppColors.textWeak,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.groups,
                  color: AppColors.textPlaceholder,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${rt['participant_count'] ?? 0} 方',
                  style: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.visibility_outlined,
                  color: AppColors.textPlaceholder,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${rt['audience_count'] ?? 0} 观众',
                  style: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  color: AppColors.textPlaceholder,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(rt['created_at']),
                  style: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
