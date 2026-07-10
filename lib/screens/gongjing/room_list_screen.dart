import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rainbow_border.dart';
import '../../widgets/glass_card.dart';
import 'create_room_screen.dart';

/// 房间列表页面 - 对齐网页版 RoomList.tsx
/// 显示当前所有活跃的静默房间，支持搜索、筛选、下拉刷新、自动清理
class RoomListScreen extends StatefulWidget {
  /// 是否作为独立页面打开（true），或作为嵌入组件（false）
  final bool standalone;

  const RoomListScreen({super.key, this.standalone = true});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _rooms = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    _cleanupStaleRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 获取所有房间列表，按人数和最近活跃排序
  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _supabase
          .from('rooms')
          .select('id,name,description,ambient_sound,user_count,room_code,tags,created_at,last_activity_at,creator_id')
          .order('user_count', ascending: false)
          .order('last_activity_at', ascending: false)
          .limit(50);
      if (data != null) {
        setState(() {
          _rooms = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _rooms = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch rooms: $e');
      setState(() {
        _error = '加载房间列表失败';
        _isLoading = false;
      });
    }
  }

  /// 清理超时空房间（1小时无人且无活动）
  Future<void> _cleanupStaleRooms() async {
    try {
      final oneHourAgo =
          DateTime.now().subtract(const Duration(hours: 1)).toUtc().toIso8601String();
      final staleRooms = await _supabase
          .from('rooms')
          .select('id')
          .eq('user_count', 0)
          .lt('last_activity_at', oneHourAgo);

      if (staleRooms != null && staleRooms.isNotEmpty) {
        for (final room in staleRooms) {
          final roomId = room['id']?.toString() ?? '';
          if (roomId.isEmpty) continue;
          try {
            await _supabase.from('room_participants').delete().eq('room_id', roomId);
            await _supabase.from('room_sentences').delete().eq('room_id', roomId);
            await _supabase.from('rooms').delete().eq('id', roomId);
          } catch (_) {}
        }
        // 清理后刷新列表
        _fetchRooms();
      }
    } catch (e) {
      debugPrint('Failed to cleanup stale rooms: $e');
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await _fetchRooms();
    await _cleanupStaleRooms();
  }

  /// 根据搜索词过滤房间
  List<Map<String, dynamic>> get _filteredRooms {
    if (_searchQuery.trim().isEmpty) return _rooms;
    final query = _searchQuery.toLowerCase().trim();
    return _rooms.where((room) {
      final name = room['name']?.toString().toLowerCase() ?? '';
      final code = room['room_code']?.toString() ?? '';
      final desc = room['description']?.toString().toLowerCase() ?? '';
      final tags = (room['tags'] as List?)?.map((t) => t.toString().toLowerCase()).join(' ') ?? '';
      return name.contains(query) ||
          code.contains(query) ||
          desc.contains(query) ||
          tags.contains(query);
    }).toList();
  }

  /// 进入房间
  void _handleEnterRoom(Map<String, dynamic> room) {
    final roomId = room['id']?.toString() ?? '';
    if (roomId.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在进入「${room['name'] ?? '房间'}」...'),
        backgroundColor: AppColors.overlayBg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pushNamed(
      '/silent-room',
      arguments: {'room_id': roomId, 'room_name': room['name']},
    ).catchError((_) {});
  }

  /// 创建房间
  void _handleCreateRoom() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
    );
    if (result == true) {
      _fetchRooms();
    }
  }

  /// 获取房间状态
  _RoomStatus _getRoomStatus(Map<String, dynamic> room) {
    final userCount = room['user_count'] as int? ?? 0;
    if (userCount == 0) return _RoomStatus.quiet;
    if (userCount >= 10) return _RoomStatus.full;
    return _RoomStatus.active;
  }

  /// 获取音效图标
  IconData _getSoundIcon(String? sound) {
    switch (sound) {
      case 'rain':
        return Icons.grain;
      case 'ocean':
        return Icons.waves;
      case 'forest':
        return Icons.forest;
      case 'wind':
        return Icons.air;
      case 'piano':
        return Icons.piano;
      case 'custom':
        return Icons.music_note;
      default:
        return Icons.volume_off;
    }
  }

  /// 获取音效名称
  String _getSoundName(String? sound) {
    switch (sound) {
      case 'rain':
        return '雨声';
      case 'ocean':
        return '海浪';
      case 'forest':
        return '森林';
      case 'wind':
        return '风声';
      case 'piano':
        return '钢琴';
      case 'custom':
        return '自定义';
      default:
        return '静音';
    }
  }

  /// 格式化时间
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final time = DateTime.parse(timeStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(time);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${time.month}/${time.day}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.standalone) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      );
    }
    return _buildBody();
  }

  /// 顶部导航栏
  Widget _buildHeader() {
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
              if (widget.standalone)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              if (widget.standalone) const SizedBox(width: 8),
              const Text(
                '共境房间',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.auroraCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_rooms.length}个房间',
                  style: const TextStyle(
                    color: AppColors.auroraCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 主体内容
  Widget _buildBody() {
    return RefreshIndicator(
      color: AppColors.auroraCyan,
      backgroundColor: AppColors.bgSecondarySolid,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildStatusSummary()),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.textPlaceholder,
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _buildErrorState(),
            )
          else if (_filteredRooms.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildRoomCard(_filteredRooms[index]),
                  childCount: _filteredRooms.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 搜索栏 + 创建按钮
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search,
                    color: AppColors.textPlaceholder,
                    size: 20,
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
                        hintText: '搜索房间名或房间ID...',
                        hintStyle: const TextStyle(
                          color: AppColors.textPlaceholder,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.close,
                          color: AppColors.textWeak,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _handleCreateRoom,
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.auroraGradient,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: AppColors.bgColor,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: AppColors.textPrimary, size: 18),
                    SizedBox(width: 4),
                    Text(
                      '创建',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

  /// 状态概览栏
  Widget _buildStatusSummary() {
    final activeCount = _rooms.where((r) => _getRoomStatus(r) == _RoomStatus.active).length;
    final quietCount = _rooms.where((r) => _getRoomStatus(r) == _RoomStatus.quiet).length;
    final fullCount = _rooms.where((r) => _getRoomStatus(r) == _RoomStatus.full).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _statusChip(Icons.circle, Colors.green.shade400, '$activeCount 活跃', activeCount > 0),
          const SizedBox(width: 8),
          _statusChip(Icons.nights_stay, AppColors.textPlaceholder, '$quietCount 安静', true),
          const SizedBox(width: 8),
          _statusChip(Icons.groups, AppColors.auroraOrange, '$fullCount 已满', fullCount > 0),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, Color color, String label, bool hasValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(hasValue ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(hasValue ? 1.0 : 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 房间卡片
  Widget _buildRoomCard(Map<String, dynamic> room) {
    final status = _getRoomStatus(room);
    final userCount = room['user_count'] as int? ?? 0;
    final roomCode = room['room_code']?.toString() ?? '';
    final ambientSound = room['ambient_sound']?.toString();
    final tags = (room['tags'] as List?)?.cast<String>() ?? [];
    final description = room['description']?.toString() ?? '';
    final lastActivity = room['last_activity_at']?.toString() ?? room['created_at']?.toString();

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case _RoomStatus.active:
        statusColor = Colors.green.shade400;
        statusText = '活跃';
        statusIcon = Icons.circle;
        break;
      case _RoomStatus.full:
        statusColor = AppColors.auroraOrange;
        statusText = '已满';
        statusIcon = Icons.groups;
        break;
      case _RoomStatus.quiet:
        statusColor = AppColors.textPlaceholder;
        statusText = '安静';
        statusIcon = Icons.nights_stay;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _handleEnterRoom(room),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: status == _RoomStatus.active
                  ? AppColors.borderActive
                  : AppColors.borderDefault,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.auroraPurple.withOpacity(0.1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.nights_stay,
                        color: AppColors.auroraPurple,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                room['name']?.toString() ?? '未命名房间',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 10),
                                  const SizedBox(width: 3),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (roomCode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: AppColors.auroraGradientWithOpacity(0.1),
                      ),
                      child: ShaderMask(
                        shaderCallback: (rect) =>
                            AppColors.auroraGradient.createShader(rect),
                        child: Text(
                          'ID: $roomCode',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  const Icon(Icons.people_outline, color: AppColors.textPlaceholder, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    '$userCount人在',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (ambientSound != null && ambientSound != 'silence' && ambientSound.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(
                      _getSoundIcon(ambientSound),
                      color: AppColors.textPlaceholder,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _getSoundName(ambientSound),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (lastActivity != null) ...[
                    const Spacer(),
                    const Icon(Icons.access_time, color: AppColors.textPlaceholder, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      _formatTime(lastActivity),
                      style: const TextStyle(
                        color: AppColors.textPlaceholder,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tags.take(4).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.hoverBgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppColors.textWeak,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.auroraBlue.withOpacity(0.15),
                  AppColors.auroraPurple.withOpacity(0.15),
                ],
              ),
            ),
            child: const Icon(
              Icons.nights_stay,
              color: AppColors.textPlaceholder,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '暂无房间',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '成为第一个创建者吧',
            style: TextStyle(
              color: AppColors.textWeak,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _handleCreateRoom,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.auroraGradient,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: AppColors.bgColor,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, color: AppColors.textPrimary, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '创建房间',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

  /// 错误状态
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            color: AppColors.textPlaceholder,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? '加载失败',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchRooms,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.hoverBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderActive),
              ),
              child: const Text(
                '重试',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 房间状态枚举
enum _RoomStatus {
  active,
  quiet,
  full,
}
