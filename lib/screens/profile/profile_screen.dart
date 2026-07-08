import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
import '../../theme/rainbow_widgets.dart';
import '../../services/auth_service.dart';
import 'settings_screen.dart';
import 'my_posts_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  int _followersCount = 0;
  int _followingCount = 0;
  int _heatCount = 0;
  int _postCount = 0;
  int _level = 1;
  int _experience = 0;
  bool _loading = true;

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
          .select(
              '*, followers_count, following_count, heat_count, level, experience')
          .eq('id', userId)
          .single();

      if (response != null) {
        setState(() {
          _profile = Map<String, dynamic>.from(response as Map);
          _followersCount =
              (response['followers_count'] as num?)?.toInt() ?? 0;
          _followingCount =
              (response['following_count'] as num?)?.toInt() ?? 0;
          _heatCount = (response['heat_count'] as num?)?.toInt() ?? 0;
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
        backgroundColor: AppColors.cardBg,
        title: const Text('退出登录', style: TextStyle(color: Colors.white)),
        content: const Text('确定要退出当前账号吗？',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出', style: TextStyle(color: AppColors.error)),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.rainbowEnd),
        ),
      );
    }

    final nickname = _profile?['nickname'] as String? ?? '用户';
    final username = _profile?['username'] as String? ?? '';
    final avatarUrl = _profile?['avatar_url'] as String?;
    final bio = _profile?['bio'] as String? ?? '';
    final faithTag = _profile?['faith_tag'] as String? ?? '信仰者';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _buildHeader(
              nickname: nickname,
              username: username,
              avatarUrl: avatarUrl,
              bio: bio,
              faithTag: faithTag,
            ),
          ),
        ],
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildMenuSection(),
            const SizedBox(height: 12),
            _buildSettingsSection(),
            const SizedBox(height: 12),
            _buildLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String nickname,
    required String username,
    String? avatarUrl,
    required String bio,
    required String faithTag,
  }) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.rainbowStart.withOpacity(0.3),
                  AppColors.rainbowEnd.withOpacity(0.3),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -48),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: AppColors.rainbowColors,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background,
                      ),
                      child: ClipOval(
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.cardBg,
                                  child: const Icon(Icons.person,
                                      color: AppColors.textMuted, size: 40),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.cardBg,
                                  child: const Icon(Icons.person,
                                      color: AppColors.textMuted, size: 40),
                                ),
                              )
                            : Container(
                                color: AppColors.cardBg,
                                child: const Icon(Icons.person,
                                    color: AppColors.textMuted, size: 40),
                              ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nickname,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          if (username.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('@$username',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.borderColor, width: 1),
                        ),
                        child: const Text('编辑资料',
                            style:
                                TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.rainbowStart.withOpacity(0.2),
                        AppColors.rainbowEnd.withOpacity(0.2),
                      ],
                    ),
                    border: Border.all(
                        color: AppColors.rainbowEnd.withOpacity(0.3)),
                  ),
                  child: Text(faithTag,
                      style: const TextStyle(
                          color: AppColors.rainbowEnd, fontSize: 12)),
                ),
                const SizedBox(height: 12),
                if (bio.isNotEmpty)
                  RainbowBorderContainer(
                    padding: const EdgeInsets.all(12),
                    child: Text(bio,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5)),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem('帖子', _postCount),
                    const SizedBox(width: 32),
                    _buildStatItem('粉丝', _followersCount),
                    const SizedBox(width: 32),
                    _buildStatItem('关注', _followingCount),
                    const SizedBox(width: 32),
                    _buildStatItem('热值', _heatCount),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(colors: [
                            AppColors.rainbowStart,
                            AppColors.rainbowEnd
                          ]),
                        ),
                        child: Text('LV.$_level',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_experience % 100) / 100,
                                backgroundColor: AppColors.borderColor,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppColors.rainbowEnd),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('${_experience % 100}/100 EXP',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(_formatCount(count),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}w';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.article_outlined,
            title: '我的帖子',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyPostsScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.star_outline,
            title: '我的收藏',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.history,
            title: '阅读历史',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: '设置',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.language,
            title: '语言切换',
            trailing: const Text('中文',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            onTap: () {
              _showLanguageDialog();
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            title: '通知设置',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen(initialTab: 2)),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: '隐私政策',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: '用户协议',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.feedback_outlined,
            title: '意见反馈',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title:
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: trailing ??
          const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 20),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 28,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 0.5,
        color: AppColors.borderColor.withOpacity(0.5),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _handleLogout,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.3)),
          ),
          child: const Center(
            child: Text('退出登录',
                style: TextStyle(
                    color: AppColors.error,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('选择语言', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('中文', true),
            _buildLanguageOption('English', false),
            _buildLanguageOption('日本語', false),
            _buildLanguageOption('한국어', false),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, bool selected) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title:
          Text(language, style: const TextStyle(color: Colors.white)),
      trailing: selected
          ? const Icon(Icons.check_circle,
              color: AppColors.rainbowEnd, size: 20)
          : null,
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}
