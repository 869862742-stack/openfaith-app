import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';

/// 梯形绶带裁剪器
class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 0.85, size.height);
    path.lineTo(size.width * 0.15, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// 热门排行组件 - 对齐网页版 HotRanking.tsx
class HotRanking extends StatefulWidget {
  final void Function(String postId)? onPostClick;
  const HotRanking({super.key, this.onPostClick});

  @override
  State<HotRanking> createState() => _HotRankingState();
}

class _HotRankingState extends State<HotRanking> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _topPosts = [];
  List<Map<String, dynamic>> _hotPosts = [];
  bool _loading = false;
  String _activeTab = 'day';

  static const _tabs = [
    {'id': 'day', 'label': '本日'},
    {'id': 'week', 'label': '本周'},
    {'id': 'month', 'label': '本月'},
    {'id': 'year', 'label': '年度'},
    {'id': 'all', 'label': '总榜'},
  ];  static const _rainbowColors = [


    AppColors.auroraRed, AppColors.auroraOrange, AppColors.auroraYellow, AppColors.auroraGreen, AppColors.auroraCyan, AppColors.auroraBlue, AppColors.auroraPurple
  ];

  LinearGradient _diagonalGradient(Size size) {
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(0.785398));
  }

  @override
  void initState() {
    super.initState();
    _fetchTopPosts();
  }

  double _calcHotValue(Map<String, dynamic> post) {
    final views = (post['views_count'] as num?)?.toDouble() ?? 0;
    final heat = (post['heat_count'] as num?)?.toDouble() ?? 0;
    final comments = (post['comments_count'] as num?)?.toDouble() ?? 0;
    final shares = (post['shares_count'] as num?)?.toDouble() ?? 0;
    final favorites = (post['favorites_count'] as num?)?.toDouble() ?? 0;
    return (views * 0.5) + (heat * 5) + (comments * 2) + (shares * 3) + (favorites * 2);
  }

  String _formatHotValue(double num) {
    if (num < 10000) return '${num.floor()}';
    final wan = num / 10000;
    if (wan < 10) {
      return wan % 1 == 0 ? '${wan.toInt()}W' : '${wan.toStringAsFixed(1)}W';
    }
    return '${wan.floor()}W';
  }

  Future<void> _fetchTopPosts() async {
    try {
      final res = await _supabase
          .from('posts')
          .select('id,title,views_count,heat_count,comments_count,shares_count,favorites_count,created_at')
          .eq('status', 'published')
          .order('heat_count', ascending: false)
          .limit(20);
      if (res.isNotEmpty) {
        final withHot = res.map((p) => {...p, 'hotValue': _calcHotValue(p)}).toList();
        withHot.sort((a, b) => (b['hotValue'] as double).compareTo(a['hotValue'] as double));
        final top10 = withHot.where((p) => (p['hotValue'] as double) > 0).take(10).toList();
        setState(() => _topPosts = top10.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _fetchHotPosts() async {
    setState(() => _loading = true);
    try {
      DateTime? startDate;
      final now = DateTime.now();
      switch (_activeTab) {
        case 'day':
          startDate = now.subtract(const Duration(hours: 24));
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = null;
      }

      var baseQuery = _supabase
          .from('posts')
          .select('id,title,views_count,heat_count,comments_count,shares_count,favorites_count,created_at')
          .eq('status', 'published');

      if (startDate != null) {
        baseQuery = baseQuery.gte('created_at', startDate.toIso8601String());
      }

      final res = await baseQuery
          .order('heat_count', ascending: false)
          .limit(50);
      if (res.isNotEmpty) {
        final withHot = res.map((p) => {...p, 'hotValue': _calcHotValue(p)}).toList();
        withHot.sort((a, b) => (b['hotValue'] as double).compareTo(a['hotValue'] as double));
        setState(() => _hotPosts = withHot.cast<Map<String, dynamic>>());
      } else {
        setState(() => _hotPosts = []);
      }
    } catch (_) {
      setState(() => _hotPosts = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showRankingModal() {
    _fetchHotPosts();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LayoutBuilder(builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          gradient: _diagonalGradient(size),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
          ),
          child: StatefulBuilder(
            builder: (ctx, setModalState) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.borderActive, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('热门排行', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _tabs.map((tab) {
                      final isActive = _activeTab == tab['id'];
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {});
                          setState(() => _activeTab = tab['id']!);
                          _fetchHotPosts();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isActive ? AppColors.hoverBg : Colors.white.withOpacity(0.03),
                          ),
                          child: Text(
                            tab['label'] as String,
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white60,
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.textSecondary))
                      : _hotPosts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_fire_department, color: AppColors.textPlaceholder, size: 48),
                                  const SizedBox(height: 8),
                                  Text('暂无热门内容', style: TextStyle(color: AppColors.textWeak)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _hotPosts.length,
                              itemBuilder: (ctx, index) => _buildModalPostItem(index, _hotPosts[index]),
                            ),
                ),
              ],
            ),
          ),
        ),
      );
      }),
    );
  }

  /// 弹窗内的排行条目（完整列表，无卡片边框）
  Widget _buildModalPostItem(int index, Map<String, dynamic> post) {
    final hotValue = post['hotValue'] as double;
    final title = post['title'] as String? ?? '无标题';

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        widget.onPostClick?.call(post['id'] as String);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _buildMedal(index),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            _buildHotValue(hotValue),
          ],
        ),
      ),
    );
  }

  /// 奖牌 + 梯形绶带（严格对齐网页版 HotRanking.tsx）
  Widget _buildMedal(int index) {
    return SizedBox(
      width: 22,
      height: 28,
      child: Stack(
        children: [
          // 绶带（顶部梯形）
          if (index < 3)
            Positioned(
              top: 0,
              left: 4, // (22-14)/2=4
              child: ClipPath(
                clipper: _RibbonClipper(),
                child: Container(
                  width: 14,
                  height: 11,
                  decoration: BoxDecoration(
                    gradient: index == 0
                        ? const LinearGradient(colors: [AppColors.auroraRed, AppColors.auroraOrange])
                        : index == 1
                            ? const LinearGradient(colors: [AppColors.auroraBlue, AppColors.auroraPurple])
                            : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,colors: [AppColors.auroraGreen, AppColors.auroraCyan]),
                  ),
                ),
              ),
            ),
          // 奖牌圆（底部居中）
          Positioned(
            bottom: 0,
            left: 2.5,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: index < 3
                    ? (index == 0
                        ? const LinearGradient(begin: Alignment(0, -0.33), end: Alignment(1, 1), colors: [AppColors.accentPink, AppColors.auroraRed, AppColors.auroraOrange])
                        : index == 1
                            ? const LinearGradient(begin: Alignment(0, -0.33), end: Alignment(1, 1), colors: [AppColors.auroraBlue, AppColors.auroraPurple, AppColors.auroraPurple])
                            : const LinearGradient(begin: Alignment(0, -0.33), end: Alignment(1, 1), colors: [AppColors.auroraGreen, AppColors.auroraCyan, AppColors.auroraGreen]))
                    : null,
                color: index >= 3 ? AppColors.borderColor : null,
                border: Border.all(color: AppColors.borderActive, width: 1.5),
                boxShadow: index < 3
                    ? [
                        BoxShadow(
                          color: index == 0
                              ? const AppColors.auroraRed.withOpacity(0.3)
                              : index == 1
                                  ? const AppColors.auroraPurple.withOpacity(0.25)
                                  : const AppColors.auroraCyan.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                        const BoxShadow(color: AppColors.textPlaceholder, blurRadius: 1, offset: Offset(0, 1)),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: index < 3 ? Colors.white : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    shadows: const [Shadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 热度值 — 七彩渐变文字
  Widget _buildHotValue(double hotValue) {
    return ShaderMask(
      shaderCallback: (bounds) => _diagonalGradient(bounds.size).createShader(bounds),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 12, color: AppColors.textPrimary),
          const SizedBox(width: 2),
          Text(
            _formatHotValue(hotValue),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_topPosts.isEmpty) return const SizedBox.shrink();
    final top3 = _topPosts.take(3).toList();
    return LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // 外层：七彩渐变边框
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: _diagonalGradient(size),
      ),
      child: Container(
        // 内层：实色 #050816（铁律）
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: const AppColors.bgColor.withOpacity(0.92),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            GestureDetector(
              onTap: _showRankingModal,
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => _diagonalGradient(bounds.size).createShader(bounds),
                    child: const Icon(Icons.local_fire_department, size: 18, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  ShaderMask(
                    shaderCallback: (bounds) => _diagonalGradient(bounds.size).createShader(bounds),
                    child: const Text('热点排行', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 16, color: AppColors.textWeak),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 排行条目（无单独边框，对齐网页版简洁列表）
            ...top3.asMap().entries.map((entry) {
              final index = entry.key;
              final post = entry.value;
              final hotValue = post['hotValue'] as double;
              final title = post['title'] as String? ?? '无标题';
              return GestureDetector(
                onTap: () => widget.onPostClick?.call(post['id'] as String),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _buildMedal(index),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildHotValue(hotValue),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
    });
  }
}
