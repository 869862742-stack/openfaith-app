import 'dart:math';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'heating_records_screen.dart';
import 'widgets/edit_profile_dialog.dart';
import '../../theme/colors.dart';
import '../../utils/format_utils.dart';
import 'widgets/level_benefits_dialog.dart';

// ═══════════════════════════════════════════════════════
// 网页版 Profile.tsx 精确还原
// 所有颜色引用 AppColors，所有尺寸从网页版 CSS 提取
// ═══════════════════════════════════════════════════════

/// 头像颜色映射（与网页版 AVATAR_COLOR_MAP 一致）
const Map<String, Color> _avatarColorMap = {
  'red': AppColors.auroraRed,
  'orange': AppColors.auroraOrange,
  'yellow': AppColors.auroraYellow,
  'green': AppColors.auroraGreen,
  'cyan': AppColors.auroraCyan,
  'blue': AppColors.auroraBlue,
  'purple': AppColors.auroraPurple,
};

/// 等级名称（与网页版 levelNames 一致）
const Map<int, String> _levelNames = {
  1: '探索者', 2: '追寻者', 3: '思辨者', 4: '笃行者', 5: '融通者',
  6: '守望者', 7: '觉悟者', 8: '至诚者', 9: '明达者', 10: '光明者',
};

/// 等级阈值（与网页版 LEVEL_THRESHOLDS 一致）
const List<int> _levelThresholds = [
  0, 1000, 5000, 25000, 125000, 250000, 500000, 1000000, 2000000, 5000000
];

/// Fallback 身份标签（与网页版 FALLBACK_FAITH_TAGS 一致）
const List<String> _fallbackFaithTags = [
  '基督教', '伊斯兰教', '犹太教', '佛教', '印度教', '道教', '锡克教',
  '巴哈伊教', '摩门教', '耶和华见证人', '琐罗亚斯德教', '诺斯替',
  '卡巴拉', '神道教', '耆那教', '德鲁兹教', '约鲁巴教', '伏都教',
  '雅兹迪', '曼达安', '玛雅/阿兹特克', '毛利宗教', '天理教', '天道教',
  '高台教', '宗教研究者', '经文爱好者', '寻求者'
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ══════ 业务逻辑状态（全部保留）══════
  Map<String, dynamic>? _profile;
  int _followersCount = 0;
  int _followingCount = 0;
  int _heatCount = 0;
  int _hotPoints = 0;
  int _postCount = 0;
  int _level = 1;
  int _experience = 0;
  bool _loading = true;
  String? _backgroundUrl;
  int _selectedTab = 0; // 0=笔记, 1=计划, 2=珍藏

  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  // 编辑资料弹窗状态
  String _editUsername = '';
  String _editBio = '';
  String _editFaithTag = '寻求者';
  String? _selectedDefaultAvatar;
  bool _editAllowStrangerVisit = true;
  bool _editAllowFriendVisit = true;
  bool _isSaving = false;
  List<String> _faithTags = List.from(_fallbackFaithTags);

  // ══════ 编辑次数限制 ══════
  int _profileEditCount = 0;
  String _profileEditMonth = '';
  bool _isVip = false;

  int get _remainingEditCount {
    if (_isVip) return -1; // VIP 无限制
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    if (_profileEditMonth != currentMonth) return 3; // 新月重置
    return (3 - _profileEditCount).clamp(0, 3);
  }

  String get _editCountLabel {
    if (_isVip) return '编辑资料';
    return '编辑资料（本月剩余 ${_remainingEditCount} 次）';
  }

  String? get _userId {
    final session = _supabase.auth.currentSession;
    return session?.user.id;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFaithTags();
  }

  Future<void> _loadFaithTags() async {
    try {
      final response = await _supabase
          .from('tags')
          .select('name')
          .eq('category', 'identity')
          .order('name');
      if (response != null && (response as List).isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _faithTags = (response as List)
              .map((t) => t['name'] as String)
              .where((n) => n.isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('[Profile] loadFaithTags error: $e');
    }
  }

  Future<void> _loadData() async {
    final userId = _userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        if (!mounted) return;
        setState(() {
          _profile = Map<String, dynamic>.from(response as Map);
          _followersCount = (response['followers_count'] as num?)?.toInt() ?? 0;
          _followingCount = (response['following_count'] as num?)?.toInt() ?? 0;
          _heatCount = (response['heat_count'] as num?)?.toInt() ?? 0;
          _hotPoints = (response['hot_points'] as num?)?.toInt() ?? 0;
          _level = (response['level'] as num?)?.toInt() ?? 1;
          _experience = (response['experience'] as num?)?.toInt() ?? 0;
          _editUsername = (response['nickname'] as String?)?.isNotEmpty == true
              ? response['nickname'] as String
              : (response['username'] as String?) ?? '';
          _editBio = (response['bio'] as String?) ?? '';
          _editFaithTag = (response['faith_tag'] as String?) ?? '寻求者';
          _editAllowStrangerVisit = response['allow_stranger_visit'] != false;
          _editAllowFriendVisit = response['allow_friend_visit'] != false;
          _isVip = response['is_vip'] == true;
          _profileEditCount = (response['profile_edit_count'] as num?)?.toInt() ?? 0;
          _profileEditMonth = (response['profile_edit_month'] as String?) ?? '';
        });
      }

      final postsResp = await _supabase
          .from('posts')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'published');

      if (postsResp != null) {
        if (!mounted) return;
        setState(() {
          _postCount = (postsResp as List).length;
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _refreshProfile() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null) {
        if (!mounted) return;
        setState(() {
          _profile = Map<String, dynamic>.from(response as Map);
          _followersCount = (response['followers_count'] as num?)?.toInt() ?? 0;
          _followingCount = (response['following_count'] as num?)?.toInt() ?? 0;
          _heatCount = (response['heat_count'] as num?)?.toInt() ?? 0;
          _hotPoints = (response['hot_points'] as num?)?.toInt() ?? 0;
          _level = (response['level'] as num?)?.toInt() ?? 1;
          _experience = (response['experience'] as num?)?.toInt() ?? 0;
          _isVip = response['is_vip'] == true;
          _profileEditCount = (response['profile_edit_count'] as num?)?.toInt() ?? 0;
          _profileEditMonth = (response['profile_edit_month'] as String?) ?? '';
        });
      }
    } catch (e) {
      debugPrint('Refresh profile error: $e');
    }
  }

  Future<void> _handleSaveProfile() async {
    final userId = _userId;
    if (userId == null) return;

    // ══ 编辑次数检查 ══
    if (!_isVip) {
      final now = DateTime.now();
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      int monthCount = (_profileEditMonth == currentMonth) ? _profileEditCount : 0;
      if (monthCount >= 3) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.auroraPurple, width: 1),
              ),
              title: const Text('提示', style: TextStyle(color: AppColors.textPrimary)),
              content: const Text(
                '本月编辑次数已达上限（3次），升级VIP可无限修改',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('知道了', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    // ══ 信仰标签30天限制检查 ══
    final oldFaithTag = _profile?['faith_tag'] as String? ?? '寻求者';
    if (_editFaithTag != oldFaithTag && !_canEditFaithTag()) {
      final lastModified = _profile?['tag_last_modified_at'] as String?;
      int daysAgo = 0;
      if (lastModified != null) {
        final lastDate = DateTime.tryParse(lastModified);
        if (lastDate != null) {
          daysAgo = DateTime.now().difference(lastDate).inDays;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('身份标签修改间隔需至少30天，上次修改于 $daysAgo 天前'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updates = <String, dynamic>{
        'nickname': _editUsername,
        'bio': _editBio,
        'faith_tag': _editFaithTag,
        'allow_stranger_visit': _editAllowStrangerVisit,
        'allow_friend_visit': _editAllowFriendVisit,
      };

      if (_selectedDefaultAvatar != null) {
        updates['avatar_url'] = '/images/avatars/default-$_selectedDefaultAvatar.svg';
      }

      // 信仰标签修改时更新 tag_last_modified_at
      if (_editFaithTag != oldFaithTag) {
        updates['tag_last_modified_at'] = DateTime.now().toIso8601String();
      }

      // 更新编辑次数
      if (!_isVip) {
        final now = DateTime.now();
        final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        int newCount = (_profileEditMonth == currentMonth) ? _profileEditCount + 1 : 1;
        updates['profile_edit_count'] = newCount;
        updates['profile_edit_month'] = currentMonth;
      }

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('user_id', userId);

      await _refreshProfile();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Save profile error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
        title: const Text('退出登录',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('确定要退出当前账号吗？',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('退出', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  String _formatCount(int count) => formatCount(count);

  String get _levelName => _levelNames[_level] ?? '探索者';

  double get _expProgress {
    if (_level <= 0 || _level > 10) return 0;
    final current = _levelThresholds[(_level - 1).clamp(0, 9)];
    final next = _levelThresholds[_level.clamp(0, 9)];
    final range = next - current;
    if (range <= 0) return 100;
    return ((_experience - current) / range * 100).clamp(0, 100).toDouble();
  }

  /// 检查信仰标签是否可修改（30天限制）
  bool _canEditFaithTag() {
    if (_profile == null) return true;
    final lastModified = _profile!['tag_last_modified_at'] as String?;
    if (lastModified == null) return true;
    final lastDate = DateTime.tryParse(lastModified);
    if (lastDate == null) return true;
    return DateTime.now().difference(lastDate).inDays >= 30;
  }

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.auroraBlue),
        ),
      );
    }

    final nickname = (_profile?['nickname'] as String?)?.isNotEmpty == true
        ? _profile!['nickname'] as String
        : (_profile?['username'] as String?) ?? '用户';
    final username = _profile?['username'] as String? ?? '';
    final avatarUrl = _profile?['avatar_url'] as String?;
    final bio = _profile?['bio'] as String? ?? '';
    final faithTag = _profile?['faith_tag'] as String? ?? '寻求者';
    final backgroundUrl = _profile?['background_url'] as String?;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildProfileHeader(
              nickname: nickname,
              username: username,
              avatarUrl: avatarUrl,
              bio: bio,
              faithTag: faithTag,
              backgroundUrl: backgroundUrl,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildTabContent(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Profile Header
  // ═══════════════════════════════════════════════════════
  Widget _buildProfileHeader({
    required String nickname,
    required String username,
    String? avatarUrl,
    required String bio,
    required String faithTag,
    String? backgroundUrl,
  }) {
    return Column(
      children: [
        // ── 背景图区域：h-56 ≈ 224px + 渐变遮罩 overlay ──
        SizedBox(
          height: 224,
          width: double.infinity,
          child: Stack(
            children: [
              // 背景图 or 星空背景
              Positioned.fill(
                child: backgroundUrl != null && backgroundUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: backgroundUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.bgColor,
                          child: const CustomPaint(painter: _StarfieldPainter(), size: Size.infinite),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.bgColor,
                          child: const CustomPaint(painter: _StarfieldPainter(), size: Size.infinite),
                        ),
                      )
                    : Container(
                        color: AppColors.bgColor,
                        child: const CustomPaint(painter: _StarfieldPainter(), size: Size.infinite),
                      ),
              ),
              // 渐变遮罩 overlay（网页版: bg-gradient-to-t from-bg-color via-bg-color/60）
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.bgColor.withOpacity(0.2),
                        AppColors.bgColor.withOpacity(0.6),
                        AppColors.bgColor,
                      ],
                    ),
                  ),
                ),
              ),
              // 顶部操作栏：返回 + 菜单 + 分享
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // 菜单按钮（网页版: w-10 h-10 rounded-full bg-hoverBg）
                        _buildCircleButton(
                          icon: Icons.menu,
                          onTap: () {
                            // 打开侧边栏
                          },
                        ),
                        const Spacer(),
                        // 分享按钮
                        _buildCircleButton(
                          icon: Icons.share_outlined,
                          onTap: () => _showShareModal(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 头像居中在底部，半露出（网页版: -mt-12 即 bottom: -48）
              Positioned(
                bottom: -48,
                left: 0,
                right: 0,
                child: Center(child: _buildAvatar(avatarUrl)),
              ),
            ],
          ),
        ),

        // ── 用户名 + 信仰标签 + ID + 统计 + 等级 + Bio + Tabs ──
        Padding(
          padding: const EdgeInsets.only(top: 56, left: 16, right: 16),
          child: Column(
            children: [
              // 用户名 + 信仰标签（网页版: flex items-center justify-center gap-2 mb-1）
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      nickname,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24, // text-2xl
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.hoverBg, // 网页版 hoverBg 背景
                      borderRadius: BorderRadius.circular(8), // rounded-lg
                    ),
                    child: Text(
                      faithTag,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12, // text-sm
                      ),
                    ),
                  ),
                ],
              ),

              // ID 行
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ID: ${username.isNotEmpty ? username : '------'}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14, // text-sm
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 二维码按钮
                  GestureDetector(
                    onTap: () {
                      final username = _profile?['username'] as String? ?? _profile?['id'] as String? ?? '';
                      final profileUrl = 'https://openfaithhub.com/u/$username';
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: Container(
                            width: 300,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.bgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderDefault),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code_2, size: 64, color: AppColors.textPrimary),
                                const SizedBox(height: 16),
                                Text(
                                  '我的个人名片',
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  profileUrl,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: profileUrl));
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('链接已复制'), backgroundColor: AppColors.success),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: LinearGradient(colors: AppColors.auroraGradient),
                                    ),
                                    child: const Text('复制链接', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.qr_code_2,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 编辑按钮
                  GestureDetector(
                    onTap: () => _showEditModal(),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: Icon(
                        Icons.edit,
                        color: AppColors.textPrimary,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),

              // ── 等级区域（网页版: flex items-center justify-center gap-2 mb-2）──
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => LevelBenefitsDialog(
                    currentLevel: _level,
                    experience: _experience,
                    isVip: _isVip,
                  ),
                ),
                child: _buildLevelBar(),
              ),

              // ── 统计数据（网页版: flex-3列，每列 center）──
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                        _followersCount, '粉丝', () => _showFollowList(true)),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                        _followingCount, '关注', () => _showFollowList(false)),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                        _heatCount + _hotPoints, '获赞', null),
                  ),
                ],
              ),

              // ── 签到 / 加热记录 ──
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HeatingRecordsScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: AppColors.auroraOrange, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '加热记录 & 每日签到',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 18),
                    ],
                  ),
                ),
              ),

              // ── Bio 引用框 ──
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildBioQuote(bio),
              ],

              // ── Tab 栏（笔记/计划/收藏）──
              const SizedBox(height: 16),
              _buildTabBar(),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // Avatar（网页版: w-24 h-24 rounded-full + 彩色渐变边框）
  // ═══════════════════════════════════════════════════════
  Widget _buildAvatar(String? avatarUrl) {
    return GestureDetector(
      onTap: () {
        // 可点击更换头像
      },
      child: Container(
        width: 96, // w-24
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 彩色渐变边框（网页版: 非七彩，是渐变红色系）
          gradient: SweepGradient(
            colors: [
              AppColors.auroraRed,
              AppColors.auroraOrange,
              AppColors.auroraYellow,
              AppColors.auroraGreen,
              AppColors.auroraCyan,
              AppColors.auroraBlue,
              AppColors.auroraPurple,
              AppColors.auroraRed, // 闭合
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.4),
              blurRadius: 15,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(3), // border width
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgColor,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _avatarPlaceholder(),
                    errorWidget: (_, __, ___) => _avatarPlaceholder(),
                  )
                : _avatarPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() => Container(
        color: AppColors.bgSecondary,
        child: const Icon(Icons.person,
            color: AppColors.textPlaceholder, size: 36),
      );

  // ═══════════════════════════════════════════════════════
  // Circle button (top bar)
  // ═══════════════════════════════════════════════════════
  Widget _buildCircleButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.hoverBg, // 网页版: bg-hoverBg
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Stat column（网页版: flex-3列, text-xl bold 数字, text-xs label）
  // ═══════════════════════════════════════════════════════
  Widget _buildStatColumn(int count, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            _formatCount(count),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20, // text-xl
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12, // text-xs
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Level bar（网页版: LV pill + 进度条 + 百分比）
  // ═══════════════════════════════════════════════════════
  Widget _buildLevelBar() {
    final progress = _expProgress / 100.0;
    final percent = _expProgress.round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // LV 标签 pill
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.hoverBgLight, // 网页版: var(--hover-bg-light)
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LV.$_level $_levelName',
                style: const TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 进度条（网页版: w-24 h-2 rounded-full，aurora渐变填充）
        SizedBox(
          width: 96,
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(color: AppColors.bgSecondary),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.auroraGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percent%',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // Bio quote（网页版: rounded-xl p-4, 彩虹渐变边框）
  // ═══════════════════════════════════════════════════════
  Widget _buildBioQuote(String bio) {
    return Container(
      padding: const EdgeInsets.all(1), // border width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppColors.auroraGradientWithOpacity(0.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgColor,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          bio,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Tab bar（网页版: flex-3, 选中底部 aurora 渐变下划线 2px）
  // ═══════════════════════════════════════════════════════
  Widget _buildTabBar() {
    final tabs = ['笔记', '计划', '收藏'];

    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = _selectedTab == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    tabs[index],
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                // 选中底部 aurora 渐变下划线 2px
                Container(
                  height: 2,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.auroraGradient
                        : null,
                    borderRadius: BorderRadius.circular(1),
                    color: isSelected ? null : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Tab content
  // ═══════════════════════════════════════════════════════
  Widget _buildTabContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildContentArea(),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child:
              CircularProgressIndicator(color: AppColors.auroraBlue),
        ),
      );
    }

    // 空状态（网页版: flex-col center, textSecondary）
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            _selectedTab == 0
                ? Icons.article_outlined
                : _selectedTab == 1
                    ? Icons.event_note_outlined
                    : Icons.star_outline,
            color: AppColors.textPrimary.withOpacity(0.2),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _selectedTab == 0
                ? '暂无笔记'
                : _selectedTab == 1
                    ? '暂无计划'
                    : '暂无收藏',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Share Modal
  // ═══════════════════════════════════════════════════════
  void _showShareModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.borderActive, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '分享',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareItem(Icons.person, '好友'),
                _buildShareItem(Icons.group, '群聊'),
                _buildShareItem(Icons.share, '更多'),
                _buildShareItem(Icons.link, '复制链接'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '点击"更多"可分享到微信、QQ、微博等应用',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('取消',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.auroraGradientWithOpacity(0.5),
          ),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgColor,
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // Follow list modal
  // ═══════════════════════════════════════════════════════
  void _showFollowList(bool isFollowers) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppColors.borderActive, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  isFollowers ? '粉丝' : '关注',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close,
                      color: AppColors.iconColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text(
                  isFollowers ? '暂无粉丝' : '暂无关注',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Edit Profile Modal（网页版: rounded-2xl, cardBg 背景）
  // ═══════════════════════════════════════════════════════
  void _showEditModal() {
    // 编辑次数预检查
    if (!_isVip && _remainingEditCount <= 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.auroraPurple, width: 1),
          ),
          title: const Text('提示', style: TextStyle(color: AppColors.textPrimary)),
          content: const Text(
            '本月编辑次数已达上限（3次），升级VIP可无限修改',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Row(
                children: [
                  Text(
                    _editCountLabel,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close,
                        color: AppColors.iconColor, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 头像选择区 ──
              Center(
                child: Column(
                  children: [
                    Text('更换头像',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14)),
                    const SizedBox(height: 12),
                    // 当前头像
                    _buildEditAvatar(),
                    const SizedBox(height: 16),
                    // 默认头像颜色选择（7色圆形按钮）
                    Text('选择头像颜色',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _avatarColorMap.entries.map((entry) {
                        final isSelected =
                            _selectedDefaultAvatar == entry.key;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDefaultAvatar = entry.key;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  entry.value,
                                  entry.value.withOpacity(0.67),
                                ],
                              ),
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.textPrimary, width: 2)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: AppColors.textPrimary, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_selectedDefaultAvatar != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDefaultAvatar = null;
                          });
                        },
                        child: const Text('使用自定义头像',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            )),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 背景图更换区 ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text('更换背景图',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  try {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1080);
                    if (image == null) return;

                    final user = _supabase.auth.currentUser;
                    if (user == null) return;

                    if (mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('上传中...'), backgroundColor: AppColors.cardBg, duration: Duration(seconds: 30)),
                      );
                    }

                    final ext = image.path.split('.').last;
                    final path = 'backgrounds/${user.id}/${DateTime.now().millisecondsSinceEpoch}.$ext';
                    await _supabase.storage.from('media').upload(path, File(image.path));
                    final url = _supabase.storage.from('media').getPublicUrl(path);

                    await _supabase.from('profiles').update({'background_url': url}).eq('user_id', user.id);

                    if (!mounted) return;
                    setState(() {
                      _backgroundUrl = url;
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('背景图已更新'), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('上传失败: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: Container(
                  height: 96, // h-24
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('点击更换背景图',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 昵称输入框 ──
              _buildLabel('昵称'),
              const SizedBox(height: 8),
              _buildInputField(
                hintText: '请输入昵称',
                onChanged: (v) => _editUsername = v,
                initialValue: _editUsername,
              ),
              const SizedBox(height: 20),

              // ── 签名 ──
              _buildLabel('个性签名'),
              const SizedBox(height: 8),
              _buildTextArea(
                hintText: '请输入个性签名',
                onChanged: (v) => setState(() => _editBio = v),
                initialValue: _editBio,
                maxLength: 100,
              ),
              const SizedBox(height: 20),

              // ── 信仰标签下拉选择 ──
              _buildLabel(
                '信仰标签',
                suffix: _canEditFaithTag()
                    ? null
                    : '（30天内仅可修改一次）',
              ),
              const SizedBox(height: 8),
              _buildFaithTagDropdown(),
              const SizedBox(height: 20),

              // ── 隐私设置 ──
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: AppColors.borderColor, width: 0.5),
                  ),
                ),
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('隐私设置',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 12),
                    // 允许陌生人访问
                    _buildPrivacyToggle(
                      title: '允许陌生人访问主页',
                      subtitle: '关闭后，只有好友才能访问',
                      value: _editAllowStrangerVisit,
                      onChanged: (v) {
                        setState(() => _editAllowStrangerVisit = v);
                      },
                    ),
                    const SizedBox(height: 8),
                    // 允许好友访问
                    _buildPrivacyToggle(
                      title: '允许好友访问主页',
                      subtitle: '双向关注即为好友',
                      value: _editAllowFriendVisit,
                      onChanged: (v) {
                        setState(() => _editAllowFriendVisit = v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 保存按钮（aurora-btn 七彩渐变）──
              GestureDetector(
                onTap: _isSaving ? null : _handleSaveProfile,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.auroraGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _isSaving ? '保存中...' : '保存修改',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditAvatar() {
    final selectedColor = _selectedDefaultAvatar != null
        ? _avatarColorMap[_selectedDefaultAvatar]
        : null;
    final displayColor = selectedColor ?? AppColors.auroraPurple;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: displayColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [displayColor, displayColor.withOpacity(0.67)],
        ),
      ),
      child: const Icon(Icons.person, color: AppColors.textPrimary, size: 36),
    );
  }

  Widget _buildLabel(String text, {String? suffix}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14)),
          if (suffix != null)
            Text(suffix,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String hintText,
    required ValueChanged<String> onChanged,
    String? initialValue,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        onChanged: onChanged,
        controller:
            initialValue != null ? TextEditingController(text: initialValue) : null,
        style:
            const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
              color: AppColors.textPlaceholder, fontSize: 14),
          filled: true,
          fillColor: AppColors.bgColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderActive, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea({
    required String hintText,
    required ValueChanged<String> onChanged,
    String? initialValue,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          height: 80,
          child: TextField(
            onChanged: onChanged,
            maxLength: maxLength,
            controller: initialValue != null
                ? TextEditingController(text: initialValue)
                : null,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                  color: AppColors.textPlaceholder, fontSize: 14),
              filled: true,
              fillColor: AppColors.bgColor,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: AppColors.borderActive, width: 1),
              ),
              counterText: '',
            ),
          ),
        ),
        if (maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${_editBio.length}/$maxLength',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildFaithTagDropdown() {
    return SizedBox(
      height: 48,
      child: DropdownButtonFormField<String>(
        value: _faithTags.contains(_editFaithTag) ? _editFaithTag : null,
        isExpanded: true,
        style:
            const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        dropdownColor: AppColors.cardBg,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.bgColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: AppColors.borderActive, width: 1),
          ),
        ),
        icon: const Icon(Icons.keyboard_arrow_down,
            color: AppColors.iconColor, size: 20),
        items: _faithTags.map((tag) {
          return DropdownMenuItem<String>(
            value: tag,
            child: Text(tag,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          );
        }).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _editFaithTag = v);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Privacy toggle（网页版: 七彩渐变边框 + 渐变滑块）
  // ═══════════════════════════════════════════════════════
  Widget _buildPrivacyToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // 开启：七彩渐变边框
              // 关闭：普通灰色背景
              gradient: value ? AppColors.auroraGradient : null,
              color: value ? null : AppColors.hoverBgLight,
              border: value
                  ? null
                  : Border.all(
                      color: AppColors.borderActive, width: 1),
            ),
            child: value
                ? Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.bgColor,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.auroraGradient,
                          ),
                          margin: const EdgeInsets.only(right: 2),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Positioned(
                        left: 3,
                        top: 3,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textWeak,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// Starfield painter — 精确匹配网页版8个 radial-gradient
// ═══════════════════════════════════════════════════════
class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 网页版精确坐标和样式
    final stars = <_Star>[
      _Star(0.10, 0.30, 1.5, const Color.fromRGBO(255, 255, 255, 0.8)),
      _Star(0.40, 0.60, 1.0, const Color.fromRGBO(200, 220, 255, 0.7)),
      _Star(0.70, 0.20, 2.0, const Color.fromRGBO(255, 255, 255, 0.9)),
      _Star(0.85, 0.70, 1.0, const Color.fromRGBO(180, 200, 255, 0.7)),
      _Star(0.25, 0.80, 1.2, const Color.fromRGBO(255, 255, 255, 0.6)),
      _Star(0.55, 0.45, 1.0, const Color.fromRGBO(200, 220, 255, 0.8)),
      _Star(0.90, 0.40, 1.5, const Color.fromRGBO(255, 255, 255, 0.7)),
      _Star(0.15, 0.55, 1.0, const Color.fromRGBO(180, 200, 255, 0.6)),
    ];

    for (final star in stars) {
      paint.color = star.color;
      canvas.drawCircle(
        Offset(star.xPercent * size.width, star.yPercent * size.height),
        star.radius,
        paint,
      );

      // 光晕效果
      final glowPaint = Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.radius * 3);
      glowPaint.color = star.color.withOpacity(star.color.opacity * 0.4);
      canvas.drawCircle(
        Offset(star.xPercent * size.width, star.yPercent * size.height),
        star.radius * 0.5,
        glowPaint,
      );
    }

    // 额外的微弱随机星点
    final random = Random(42);
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 0.6 + 0.2;
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.3 + 0.1);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Star {
  final double xPercent;
  final double yPercent;
  final double radius;
  final Color color;

  const _Star(this.xPercent, this.yPercent, this.radius, this.color);
}
