import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'heating_records_screen.dart';
import 'widgets/edit_profile_dialog.dart';
import '../../theme/colors.dart';
import '../../utils/format_utils.dart';
import '../../utils/api_cache.dart';
import 'widgets/level_benefits_dialog.dart';

// ═══════════════════════════════════════════════════════
// 网页版 Profile.tsx 精确还原
// 所有颜色引用 AppColors，所有尺寸从网页版 CSS 提取
// ═══════════════════════════════════════════════════════

// 网站静态资源基础URL（与网页版 defaultImages.ts 对齐）
const _kWebAssetsBase = 'https://openfaithhub.com';
const _kAvatarNames = ['red', 'orange', 'yellow', 'green', 'cyan', 'blue', 'purple',
  'rose', 'tangerine', 'gold', 'lime', 'aqua', 'sky', 'violet'];
const _kBgNames = ['default', 'deep', 'indigo', 'violet', 'ocean'];

/// 根据用户ID生成确定性的默认头像URL（与网页版 getDefaultAvatarUrl 一致）
String _getDefaultAvatarUrl(String seed) {
  if (seed.isEmpty) seed = 'default';
  int hash = 0;
  for (int i = 0; i < seed.length; i++) {
    hash = seed.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final idx = hash.abs() % _kAvatarNames.length;
  return '$_kWebAssetsBase/images/avatars/default-${_kAvatarNames[idx]}.svg';
}

/// 解析头像URL：有自定义返回自定义，否则返回默认（与网页版 resolveAvatarUrl 一致）
String _resolveAvatarUrl(String? avatarUrl, String seed) {
  if (avatarUrl != null && avatarUrl.trim().isNotEmpty) return avatarUrl;
  return _getDefaultAvatarUrl(seed);
}

/// 根据用户ID生成确定性的默认背景URL
String _getDefaultBackgroundUrl(String seed) {
  if (seed.isEmpty) seed = 'default';
  int hash = 0;
  for (int i = 0; i < seed.length; i++) {
    hash = seed.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final idx = hash.abs() % _kBgNames.length;
  return '$_kWebAssetsBase/images/backgrounds/default-${_kBgNames[idx]}.svg';
}

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

import '../../components/sidebar.dart';
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
  int _selectedTab = 0; // 0=笔记, 1=计划, 2=珍藏

  final _supabase = Supabase.instance.client;
  final _authService = AuthService();

  // 编辑资料弹窗状态
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
      // ── 强制清除旧缓存，确保 avatar_url/background_url 等字段是最新的 ──
      await ApiCache.instance.invalidate('profile:$userId');

      // ── SWR cache layer for user profile ─
      final response = await ApiCache.instance.staleWhileRevalidate<Map<String, dynamic>>(
        'profile:$userId',
        () async {
          final r = await _supabase
              .from('profiles')
              .select('*')
              .eq('user_id', userId)
              .maybeSingle();
          return r != null ? Map<String, dynamic>.from(r as Map) : <String, dynamic>{};
        },
        staleTime: const Duration(minutes: 10),
        ttl: const Duration(minutes: 10),
        onRefresh: (freshProfile) {
          if (mounted && freshProfile.isNotEmpty) _applyProfile(freshProfile);
        },
      );

      if (response != null && (response as Map).isNotEmpty) {
        _applyProfile(response);
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

      // Calculate followers count from follows table
      try {
        final followersResp = await _supabase
            .from('follows')
            .select('id')
            .eq('following_id', userId)
            .eq('status', 'active');
        if (followersResp != null && mounted) {
          setState(() {
            _followersCount = (followersResp as List).length;
          });
        }
      } catch (e) {
        debugPrint('Error fetching followers count: $e');
      }

      // Calculate following count from follows table
      try {
        final followingResp = await _supabase
            .from('follows')
            .select('id')
            .eq('follower_id', userId)
            .eq('status', 'active');
        if (followingResp != null && mounted) {
          setState(() {
            _followingCount = (followingResp as List).length;
          });
        }
      } catch (e) {
        debugPrint('Error fetching following count: $e');
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  /// Apply profile data to state (shared between initial load and SWR refresh).
  void _applyProfile(Map<String, dynamic> response) {
    if (!mounted) return;
    setState(() {
      _profile = Map<String, dynamic>.from(response);
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

  Future<void> _refreshProfile() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      // Invalidate cache before refreshing
      await ApiCache.instance.invalidate('profile:$userId');
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null) {
        final profileMap = Map<String, dynamic>.from(response as Map);
        // Update cache with fresh data
        await ApiCache.instance.set('profile:$userId', profileMap,
            ttl: const Duration(minutes: 10));
        if (!mounted) return;
        _applyProfile(profileMap);
      }
    } catch (e) {
      debugPrint('Refresh profile error: $e');
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
    final userIdForAvatar = _userId ?? 'default';
    final avatarUrl = _resolveAvatarUrl(_profile?['avatar_url'] as String?, userIdForAvatar);
    final bio = _profile?['bio'] as String? ?? '';
    final faithTag = _profile?['faith_tag'] as String? ?? '寻求者';
    final rawBgUrl = _profile?['background_url'] as String?;
    final backgroundUrl = (rawBgUrl != null && rawBgUrl.trim().isNotEmpty) ? rawBgUrl : _getDefaultBackgroundUrl(_userId ?? 'default');

    return Stack(
      children: [
        Scaffold(
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
        // Sidebar overlay
        if (_showSidebar)
          Sidebar(
            onClose: _closeSidebar,
            onMenuItemTap: _handleSidebarMenuItem,
            key: const ValueKey('profile_sidebar'),
          ),
      ],
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
                    ? _buildNetworkImage(
                        backgroundUrl,
                        fit: BoxFit.cover,
                        placeholder: Container(
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
                          onTap: _openSidebar,
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
                                    padding: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(

                                      borderRadius: BorderRadius.circular(13),

                                      border: Border.all(color: AppColors.rainbowEnd, width: 1),

                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 11),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColors.bgColor,
                                      ),
                                      child: const Text('复制链接', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                    ),
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

  /// 智能图片加载：SVG 用 SvgPicture.network，其他用 CachedNetworkImage
  Widget _buildNetworkImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover, Widget? placeholder, Widget? errorWidget}) {
    final isSvg = url.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return SvgPicture.network(
        url,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: placeholder != null ? (_) => placeholder : null,
        errorBuilder: (BuildContext ctx, Object err, StackTrace? st) => errorWidget ?? placeholder ?? const SizedBox.shrink(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder != null ? (_, __) => placeholder : null,
      errorWidget: (BuildContext ctx, String url, Object err) => errorWidget ?? placeholder ?? const SizedBox.shrink(),
    );
  }

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
                ? _buildNetworkImage(
                    avatarUrl,
                    width: 90, height: 90,
                    fit: BoxFit.cover,
                    placeholder: _avatarPlaceholder(),
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

        border: Border.all(color: AppColors.rainbowEnd, width: 1),

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
                _buildShareItem(Icons.share, '更多', onTap: _shareWithSystem),
                _buildShareItem(Icons.link, '复制链接', onTap: _copyProfileLink),
              ],
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

  void _shareWithSystem() {
    final userId = _profile?['id'] ?? '';
    final nickname = _profile?['nickname'] ?? 'OpenFaith';
    final shareText = '来看看 $nickname 在 OpenFaith 的主页：https://openfaithhub.com/#/profile/$userId';
    
    // Copy to clipboard as fallback
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享链接已复制到剪贴板'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _copyProfileLink() {
    final userId = _profile?['id'] ?? '';
    final profileUrl = 'https://openfaithhub.com/#/profile/$userId';
    Clipboard.setData(ClipboardData(text: profileUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('链接已复制到剪贴板')),
    );
  }

  // ═══════════════════════════════════════════════════════
  // Sidebar
  // ═══════════════════════════════════════════════════════
  
  void _openSidebar() {
    setState(() => _showSidebar = true);
  }

  void _closeSidebar() {
    setState(() => _showSidebar = false);
  }

  void _handleSidebarMenuItem(String menuItemId) {
    // Handle sidebar menu items - navigate to different pages
    // For now, just close the sidebar
    _closeSidebar();
  }


  Widget _buildShareItem(IconData icon, String label, {VoidCallback? onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
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
    showDialog(
      context: context,
      builder: (ctx) => EditProfileDialog(
        profile: _profile ?? {},
        onSaveSuccess: _loadData,
      ),
    );
  }

}

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

