import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

// ===== 网页版精确 CSS 变量映射 =====
// --bg-color: #050816
// --bg-secondary: rgba(15, 15, 35, 0.75)
// --hover-bg: rgba(255,255,255,0.08)
// --hover-bg-light: rgba(255,255,255,0.03)
// --text-color: #FFFFFF
// --text-secondary: rgba(255,255,255,0.72)
// --text-placeholder: rgba(255,255,255,0.35)
// --border-color: rgba(255,255,255,0.08)
// --input-bg: rgba(255,255,255,0.05)

const _kBgColor = Color(0xFF050816);
const _kBgSecondary = Color.fromRGBO(15, 15, 35, 0.75);
const _kHoverBg = Color.fromRGBO(255, 255, 255, 0.08);
const _kHoverBgLight = Color.fromRGBO(255, 255, 255, 0.03);
const _kTextSecondary = Color.fromRGBO(255, 255, 255, 0.72);
const _kTextWeak = Color.fromRGBO(255, 255, 255, 0.45);
const _kTextPlaceholder = Color.fromRGBO(255, 255, 255, 0.35);
const _kBorderColor = Color.fromRGBO(255, 255, 255, 0.08);

// 七彩渐变色值（来自网页版 rainbow.ts）
const _kAuroraColors = [
  Color(0xFFFF4D6D), // red
  Color(0xFFFF9F1C), // orange
  Color(0xFFFFD60A), // yellow
  Color(0xFF70E000), // green
  Color(0xFF00E5FF), // cyan
  Color(0xFF3A86FF), // blue
  Color(0xFF9D4EDD), // purple
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ===== 业务逻辑状态（保持不变）=====
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

  String? get _userId {
    final session = _supabase.auth.currentSession;
    return session?.user.id;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
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
        setState(() {
          _profile = Map<String, dynamic>.from(response as Map);
          _followersCount = (response['followers_count'] as num?)?.toInt() ?? 0;
          _followingCount = (response['following_count'] as num?)?.toInt() ?? 0;
          _heatCount = (response['heat_count'] as num?)?.toInt() ?? 0;
          _hotPoints = (response['hot_points'] as num?)?.toInt() ?? 0;
          _level = (response['level'] as num?)?.toInt() ?? 1;
          _experience = (response['experience'] as num?)?.toInt() ?? 0;
        });
      }

      final postsResp = await _supabase
          .from('posts')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'published');

      if (postsResp != null) {
        setState(() {
          _postCount = (postsResp as List).length;
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }

    setState(() => _loading = false);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0E1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        title: const Text('退出登录', style: TextStyle(color: Colors.white)),
        content: const Text('确定要退出当前账号吗？',
            style: TextStyle(color: _kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(color: _kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出', style: TextStyle(color: Color(0xFFFF4D6D))),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}w';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  // 网页版等级名称（精确匹配）
  String get _levelName {
    const names = {
      1: '探索者', 2: '追寻者', 3: '思辨者', 4: '笃行者', 5: '融通者',
      6: '守望者', 7: '觉悟者', 8: '至诚者', 9: '明达者', 10: '光明者',
    };
    return names[_level] ?? '探索者';
  }

  // 网页版等级阈值（精确匹配）
  static const _levelThresholds = [0, 1000, 5000, 25000, 125000, 250000, 500000, 1000000, 2000000, 5000000];

  double get _expProgress {
    if (_level <= 0 || _level > 10) return 0;
    final currentThreshold = _levelThresholds[(_level - 1).clamp(0, 9)];
    final nextThreshold = _levelThresholds[_level.clamp(0, 9)];
    final range = nextThreshold - currentThreshold;
    if (range <= 0) return 100;
    final progress = (_experience - currentThreshold) / range * 100;
    return progress.clamp(0, 100).toDouble();
  }

  // ===== UI 构建（基于网页版源码精确还原）=====

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBgColor,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3A86FF)),
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
    final isAdmin = _profile?['is_admin'] as bool? ?? false;

    return Scaffold(
      backgroundColor: _kBgColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildProfileHeader(
              nickname: nickname,
              username: username,
              avatarUrl: avatarUrl,
              bio: bio,
              faithTag: faithTag,
              isAdmin: isAdmin,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildTabContent(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader({
    required String nickname,
    required String username,
    String? avatarUrl,
    required String bio,
    required String faithTag,
    required bool isAdmin,
  }) {
    return Column(
      children: [
        // === 星空 Banner（网页版: h-48 = 192px）===
        SizedBox(
          height: 192,
          width: double.infinity,
          child: Stack(
            children: [
              // 星空背景（网页版: 8个radial-gradient精确定位）
              Positioned.fill(
                child: Container(
                  color: _kBgColor,
                  child: CustomPaint(
                    size: const Size(double.infinity, 192),
                    painter: _WebStarfieldPainter(),
                  ),
                ),
              ),
              // 左上角菜单按钮（网页版: top-4 left-4 w-10 h-10）
              Positioned(
                top: 16, left: 16,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _kHoverBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu, color: Colors.white, size: 20),
                ),
              ),
              // 右上角分享按钮（网页版: top-4 right-4 w-10 h-10）
              Positioned(
                top: 16, right: 16,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _kHoverBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                ),
              ),
              // 头像居中在 banner 底部（网页版: -mt-12 = -48px，即半露出）
              Positioned(
                bottom: -48,
                left: 0, right: 0,
                child: Center(
                  child: _buildAvatar(avatarUrl),
                ),
              ),
            ],
          ),
        ),

        // === 用户名 + 徽章（网页版: pt-4 因为头像下方有48px露出，这里从头像底部开始）===
        Padding(
          padding: const EdgeInsets.only(top: 56, left: 16, right: 16),
          child: Column(
            children: [
              // 用户名 + 徽章（网页版: flex items-center justify-center gap-2 mb-1）
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20, // text-xl
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8), // gap-2
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // px-2 py-0.5
                    decoration: BoxDecoration(
                      color: _kHoverBgLight, // var(--hover-bg-light)
                      borderRadius: BorderRadius.circular(999), // rounded-full
                    ),
                    child: Text(
                      isAdmin ? '管理员' : faithTag,
                      style: const TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 0.8),
                        fontSize: 12, // text-xs
                      ),
                    ),
                  ),
                ],
              ),

              // === ID 行（网页版: flex items-center justify-center gap-2 mb-4）===
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ID: ${username.isNotEmpty ? username : '------'}',
                    style: const TextStyle(
                      color: _kTextSecondary, // 0.72
                      fontSize: 14, // text-sm
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 二维码按钮（网页版: p-1 rounded bg-secondary）
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _kBgSecondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.qr_code_2,
                      color: _kTextSecondary,
                      size: 16, // w-4 h-4
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 编辑按钮（网页版: w-7 h-7 rounded-full）
                  GestureDetector(
                    onTap: () {
                      // TODO: 编辑资料
                    },
                    child: SizedBox(
                      width: 28, height: 28,
                      child: Icon(
                        Icons.edit,
                        color: Colors.white, // 网页版: color: "white"
                        size: 14, // w-3.5 h-3.5
                      ),
                    ),
                  ),
                ],
              ),

              // === 统计数据行（网页版: gap-6 md:gap-8 mb-4）===
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem(_followersCount, '粉丝', Icons.people, Icons.people),
                  const SizedBox(width: 24), // gap-6
                  _buildStatItem(_followingCount, '关注', Icons.people, Icons.people),
                  const SizedBox(width: 24),
                  _buildStatItem(_heatCount, '热值', Icons.local_fire_department, Icons.local_fire_department),
                  const SizedBox(width: 24),
                  _buildStatItem(_hotPoints, '热点', Icons.bolt, Icons.bolt),
                ],
              ),

              // === 等级区域（网页版: flex items-center justify-center gap-2 mb-2）===
              const SizedBox(height: 16),
              _buildLevelBar(),

              // === 引用文字框（网页版: rounded-xl p-4 mb-4）===
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildBioQuote(bio),
              ],

              // === Tab 按钮栏（网页版: gap-2 mb-4，在 px-4 区域内）===
              const SizedBox(height: 16),
              _buildTabBar(),
            ],
          ),
        ),
      ],
    );
  }

  /// 头像（网页版: w-24 h-24 = 96px，1px rainbow border，background-clip法）
  Widget _buildAvatar(String? avatarUrl) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // 网页版: linear-gradient(#050816, #050816) padding-box + rainbow border-box
        // 在 Flutter 中用 padding 嵌套法实现
        gradient: const SweepGradient(
          colors: [
            Color.fromRGBO(255, 77, 109, 0.7),
            Color.fromRGBO(255, 159, 28, 0.7),
            Color.fromRGBO(255, 214, 10, 0.7),
            Color.fromRGBO(112, 224, 0, 0.7),
            Color.fromRGBO(0, 229, 255, 0.7),
            Color.fromRGBO(58, 134, 255, 0.7),
            Color.fromRGBO(157, 78, 221, 0.7),
            Color.fromRGBO(255, 77, 109, 0.7), // 闭合渐变
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
        margin: const EdgeInsets.all(2), // 2px border width (网页版1px但需要覆盖渐变)
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _kBgColor,
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: _kBgSecondary,
                    child: const Icon(Icons.person, color: _kTextPlaceholder, size: 36),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: _kBgSecondary,
                    child: const Icon(Icons.person, color: _kTextPlaceholder, size: 36),
                  ),
                )
              : Container(
                  color: _kBgSecondary,
                  child: const Icon(Icons.person, color: _kTextPlaceholder, size: 36),
                ),
        ),
      ),
    );
  }

  /// 统计数据项（网页版: flex-col items-center, icon+number in row, label below）
  /// 网页版: icon w-4 h-4 color rgba(255,255,255,0.6), number font-bold, label text-xs
  Widget _buildStatItem(int count, String label, IconData iconData, IconData iconData2) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              color: Colors.white.withOpacity(0.6),
              size: 16, // w-4 h-4
            ),
            const SizedBox(width: 4), // gap-1
            Text(
              _formatCount(count),
              style: const TextStyle(
                color: Colors.white, // var(--text-color)
                fontSize: 14, // 默认字号，font-bold
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: _kTextSecondary, // 0.72
            fontSize: 12, // text-xs
          ),
        ),
      ],
    );
  }

  /// 等级进度条
  /// 网页版: LV pill(px-3 py-1 text-sm rounded-full, bg: hover-bg-light, color: rgba(255,255,255,0.8))
  ///        + level name in same pill
  ///        + progress bar (w-24 h-2 rounded-full, bg: bg-secondary, fill: white)
  ///        + percentage text (text-xs, color: text-secondary)
  Widget _buildLevelBar() {
    final progress = _expProgress / 100.0;
    final percent = _expProgress.round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // LV 标签（网页版: px-3 py-1 text-sm rounded-full）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _kHoverBgLight, // 网页版: var(--hover-bg-light)
            borderRadius: BorderRadius.circular(999), // rounded-full
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LV.$_level $_levelName',
                style: const TextStyle(
                  color: Color.fromRGBO(255, 255, 255, 0.8),
                  fontSize: 14, // text-sm
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8), // gap-2
        // 进度条（网页版: w-24 h-2 rounded-full = 96px × 8px）
        SizedBox(
          width: 96,
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                // 背景
                Container(color: _kBgSecondary),
                // 填充（网页版: background: white）
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 百分比
        Text(
          '$percent%',
          style: const TextStyle(
            color: _kTextSecondary,
            fontSize: 12, // text-xs
          ),
        ),
      ],
    );
  }

  /// 引用框
  /// 网页版: rounded-xl p-4 mb-4
  /// 边框: background-clip法, 1.1px, 0.5透明度彩虹
  /// 背景: #050816
  /// 文字: text-sm(14px) leading-relaxed, color: text-secondary(0.72)
  Widget _buildBioQuote(String bio) {
    return Container(
      padding: const EdgeInsets.all(1), // 模拟 border
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // rounded-xl
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(255, 77, 109, 0.5),
            Color.fromRGBO(255, 159, 28, 0.5),
            Color.fromRGBO(255, 214, 10, 0.5),
            Color.fromRGBO(112, 224, 0, 0.5),
            Color.fromRGBO(0, 229, 255, 0.5),
            Color.fromRGBO(58, 134, 255, 0.5),
            Color.fromRGBO(157, 78, 221, 0.5),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16), // p-4
        decoration: BoxDecoration(
          color: _kBgColor, // #050816
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          bio,
          style: const TextStyle(
            color: _kTextSecondary, // 0.72
            fontSize: 14, // text-sm
            height: 1.6, // leading-relaxed
          ),
        ),
      ),
    );
  }

  /// Tab 按钮栏
  /// 网页版: gap-2 mb-4
  /// 选中态: outer padding 2px rainbow gradient, inner rounded-full px-3 py-1 text-xs font-semibold bg:#050816
  /// 未选中态: px-3 py-1.5 rounded-full text-xs font-medium, bg: bg-secondary, border: 1px solid rgba(255,255,255,0.2)
  Widget _buildTabBar() {
    final tabs = ['笔记', '计划', '珍藏'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(tabs.length, (index) {
        final isSelected = _selectedTab == index;
        return Padding(
          padding: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0), // gap-2 = 8px
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: isSelected
                // 选中态：2px rainbow padding + inner #050816
                ? Container(
                    padding: const EdgeInsets.all(2), // 2px rainbow border
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _kAuroraColors,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // px-3 py-1
                      decoration: const BoxDecoration(
                        color: _kBgColor, // #050816
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                      child: Text(
                        tabs[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12, // text-xs
                          fontWeight: FontWeight.w600, // font-semibold
                        ),
                      ),
                    ),
                  )
                // 未选中态
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-3 py-1.5
                    decoration: BoxDecoration(
                      color: _kBgSecondary,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tabs[index],
                      style: const TextStyle(
                        color: _kTextSecondary,
                        fontSize: 12, // text-xs
                        fontWeight: FontWeight.w500, // font-medium
                      ),
                    ),
                  ),
          ),
        );
      }),
    );
  }

  /// Tab 内容区域
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

  /// 内容区域
  Widget _buildContentArea() {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF3A86FF)),
        ),
      );
    }

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
            color: Colors.white.withOpacity(0.2),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _selectedTab == 0
                ? '暂无笔记'
                : _selectedTab == 1
                    ? '暂无计划'
                    : '暂无珍藏',
            style: const TextStyle(
              color: _kTextPlaceholder,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// 星空效果绘制器 — 精确匹配网页版8个radial-gradient
/// 网页版:
///   radial-gradient(1.5px 1.5px at 10% 30%, rgba(255,255,255,0.8), transparent),
///   radial-gradient(1px 1px at 40% 60%, rgba(200,220,255,0.7), transparent),
///   radial-gradient(2px 2px at 70% 20%, rgba(255,255,255,0.9), transparent),
///   radial-gradient(1px 1px at 85% 70%, rgba(180,200,255,0.7), transparent),
///   radial-gradient(1.2px 1.2px at 25% 80%, rgba(255,255,255,0.6), transparent),
///   radial-gradient(1px 1px at 55% 45%, rgba(200,220,255,0.8), transparent),
///   radial-gradient(1.5px 1.5px at 90% 40%, rgba(255,255,255,0.7), transparent),
///   radial-gradient(1px 1px at 15% 55%, rgba(180,200,255,0.6), transparent)
class _WebStarfieldPainter extends CustomPainter {
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

    // 额外添加一些微弱的随机小星点增加质感
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

  _Star(this.xPercent, this.yPercent, this.radius, this.color);
}
