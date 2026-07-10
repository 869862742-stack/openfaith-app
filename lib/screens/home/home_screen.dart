import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
import '../../components/sidebar.dart';
import 'post_detail_screen.dart';
import '../profile/settings_screen.dart';
import '../sidebar_pages/history_screen.dart';
import '../sidebar_pages/downloads_screen.dart';
import '../sidebar_pages/covenant_screen.dart';
import '../sidebar_pages/scan_screen.dart';
import '../sidebar_pages/support_screen.dart';
import '../sidebar_pages/vip_screen.dart';
import '../sidebar_pages/gongjing_screen.dart';
import '../../widgets/hot_ranking.dart';
import '../profile/heating_records_screen.dart';
import '../../services/learn_data_cache.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // ==========================================================================
  // 状态变量 - 保留原有逻辑
  // ==========================================================================
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _allPosts = [];
  List<Map<String, dynamic>> _pinnedPosts = [];
  List<Map<String, dynamic>> _hotPosts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String _searchQuery = '';
  bool _showSidebar = false;
  int _currentTab = 0; // 0 = recommend, 1 = following, 2 = tags, 3 = gongjing
  List<String> _followingIds = [];
  List<String> _selectedTags = [];
  List<String> _availableTags = [];
  bool _isMuted = false;
  int _onlineCount = 0;
  List<Map<String, dynamic>> _rooms = [];
  bool _showHotRanking = false;
  StreamSubscription? _uniLinkSub;
  String? _pendingNoteId;
  String? _pendingCommentId;
  bool _checkedInToday = false;
  bool _checkinLoading = false;

  static const int _pageSize = 20;
  int _currentPage = 0;

  // Following tab pagination
  int _followingPage = 0;
  bool _followingHasMore = true;
  bool _loadingFollowingMore = false;
  static const int _followingPageSize = 30;

  // ==========================================================================
  // 七彩渐变常量（铁律）
  // ==========================================================================
  static const _auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.rainbowColors,
  );

  static const _auroraColors = AppColors.rainbowColors;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _scrollController.addListener(_onScroll);
    _checkMutedStatus();
    _fetchOnlineCount();
    _fetchAvailableTags();
    _checkTodayCheckin();
    _initDeepLink();
    // 延迟预加载学习页数据，与网页版 preloadLearnData() 对齐
    Future.delayed(const Duration(seconds: 1), () {
      LearnDataCache().preload();
    });
  }

  /// 初始化 Deep Link 监听
  void _initDeepLink() {
    // 处理冷启动 deep link
    try {
      getInitialUri().then((uri) {
        if (uri != null) _handleDeepLink(uri);
      });
    } catch (e) {
      debugPrint('[DeepLink] getInitialUri error: $e');
    }

    // 监听热启动 deep link
    _uniLinkSub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('[DeepLink] uriLinkStream error: $err');
    });
  }

  /// 解析 deep link 参数并导航
  void _handleDeepLink(Uri uri) {
    final noteId = uri.queryParameters['openNoteId'];
    final commentId = uri.queryParameters['openCommentId'];
    if (noteId == null || noteId.isEmpty) return;

    // 在已加载的帖子列表中查找
    final allItems = [..._pinnedPosts, ..._posts];
    final matchIndex = allItems.indexWhere((p) => p['id'] == noteId);

    if (matchIndex != -1) {
      _pendingNoteId = noteId;
      _pendingCommentId = commentId;
      final post = allItems[matchIndex];
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            post: post,
            highlightCommentId: commentId,
          ),
        ),
      );
    } else {
      // 帖子不在当前列表中，通过 API 加载
      _loadPostById(noteId, commentId);
    }
  }

  /// 通过 ID 加载帖子并打开详情
  Future<void> _loadPostById(String noteId, String? commentId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('*, profiles:user_id(nickname, username, avatar_url, faith_tag)')
          .eq('id', noteId)
          .maybeSingle();
      if (response != null && mounted) {
        _pendingNoteId = noteId;
        _pendingCommentId = commentId;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              post: Map<String, dynamic>.from(response),
              highlightCommentId: commentId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[DeepLink] loadPostById error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _uniLinkSub?.cancel();
    super.dispose();
  }

  // ==========================================================================
  // 数据加载逻辑 - 完全保留原有实现
  // ==========================================================================

  void _onScroll() {
    if (_currentTab == 1) {
      // Following tab: use dedicated pagination
      if (_loadingFollowingMore || !_followingHasMore) return;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _loadMoreFollowingPosts();
      }
      return;
    }
    if (_loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMorePosts();
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _currentPage = 0;
      _hasMore = true;
    });
    try {
      final results = await Future.wait<dynamic>([
        _supabase
            .from('posts')
            .select('*')
            .eq('status', 'published')
            .order('created_at', ascending: false)
            .limit(_pageSize),
        _supabase
            .from('posts')
            .select('*')
            .eq('status', 'published')
            .order('heat_count', ascending: false)
            .limit(3),
        _loadFollowingIds(),
      ]);

      final rawPosts = results[0] as List<dynamic>?;
      final rawHotPosts = results[1] as List<dynamic>?;
      final allPosts = rawPosts != null
          ? List<Map<String, dynamic>>.from(rawPosts)
          : <Map<String, dynamic>>[];
      final hotPosts = rawHotPosts != null
          ? List<Map<String, dynamic>>.from(rawHotPosts)
          : <Map<String, dynamic>>[];

      await _enrichWithProfiles(allPosts);
      await _enrichWithProfiles(hotPosts);

      final pinned = <Map<String, dynamic>>[];
      final normal = <Map<String, dynamic>>[];
      for (final post in allPosts) {
        if (post['pinned_status'] == 'active') {
          pinned.add(post);
        } else {
          normal.add(post);
        }
      }

      if (!mounted) return;
      setState(() {
        _allPosts = normal;
        _pinnedPosts = pinned;
        _hotPosts = hotPosts;
        _loading = false;
        _currentPage = 1;
        _hasMore = allPosts.length >= _pageSize;
      });

      _applyFilters();
    } catch (e) {
      debugPrint('加载帖子失败: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);

    try {
      final offset = _currentPage * _pageSize;
      final rawPosts = await _supabase
          .from('posts')
          .select('*')
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      final newPosts = rawPosts != null
          ? List<Map<String, dynamic>>.from(rawPosts)
          : <Map<String, dynamic>>[];

      if (newPosts.isEmpty) {
        if (!mounted) return;
        setState(() {
          _hasMore = false;
          _loadingMore = false;
        });
        return;
      }

      await _enrichWithProfiles(newPosts);

      final normal = <Map<String, dynamic>>[];
      for (final post in newPosts) {
        if (post['pinned_status'] != 'active') {
          normal.add(post);
        }
      }

      if (!mounted) return;
      setState(() {
        _allPosts = [..._allPosts, ...normal];
        _currentPage += 1;
        _hasMore = newPosts.length >= _pageSize;
        _loadingMore = false;
      });

      _applyFilters();
    } catch (e) {
      debugPrint('加载更多帖子失败: $e');
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _enrichWithProfiles(List<Map<String, dynamic>> posts) async {
    if (posts.isEmpty) return;
    final userIds = <String>{};
    for (final p in posts) {
      final uid = p['user_id'] as String?;
      if (uid != null && uid.isNotEmpty) userIds.add(uid);
    }
    if (userIds.isEmpty) return;

    try {
      final profiles = await _supabase
          .from('profiles')
          .select('user_id, nickname, username, avatar_url, faith_tag')
          .inFilter('user_id', userIds.toList());
      final profileMap = <String, Map<String, dynamic>>{};
      if (profiles != null) {
        for (final p in profiles) {
          final uid = p['user_id'] as String?;
          if (uid != null) {
            profileMap[uid] = Map<String, dynamic>.from(p as Map);
          }
        }
      }
      for (final post in posts) {
        final uid = post['user_id'] as String?;
        if (uid != null && profileMap.containsKey(uid)) {
          post['profiles'] = profileMap[uid];
        }
      }
    } catch (e) {
      debugPrint('Failed to load profiles: $e');
    }
  }

  Future<List<String>> _loadFollowingIds() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final follows = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', user.id)
          .eq('status', 'active');

      final ids = (follows ?? [])
          .map((f) => f['following_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() => _followingIds = ids);
      return ids;
    } catch (e) {
      debugPrint('加载关注列表失败: $e');
      return [];
    }
  }

  Future<void> _checkMutedStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _supabase
          .from('profiles')
          .select('is_muted')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null && res['is_muted'] == true) {
        if (!mounted) return;
        setState(() => _isMuted = true);
      }
    } catch (e) {
      debugPrint('检查禁言状态失败: $e');
    }
  }

  Future<void> _fetchOnlineCount() async {
    try {
      final fiveMinutesAgo = DateTime.now().toUtc().subtract(const Duration(minutes: 5)).toIso8601String();
      final res = await _supabase
          .from('profiles')
          .select('user_id')
          .gte('last_online_at', fiveMinutesAgo);
      final rooms = await _supabase
          .from('chat_rooms')
          .select('id,name')
          .eq('is_active', true)
          .limit(5);
      if (!mounted) return;
      setState(() {
        _onlineCount = (res as List?)?.length ?? 0;
        _rooms = List<Map<String, dynamic>>.from(rooms as List? ?? []);
      });
    } catch (e) {
      debugPrint('获取在线人数失败: $e');
    }
  }

  Future<void> _fetchAvailableTags() async {
    try {
      final res = await _supabase
          .from('posts')
          .select('tags')
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(100);
      final tagSet = <String>{};
      for (final row in (res as List? ?? [])) {
        final tags = row['tags'] as List<dynamic>?;
        if (tags != null) {
          for (final t in tags) {
            final tag = t.toString();
            if (!tag.startsWith('__') && !tag.startsWith('member_') &&
                !RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-').hasMatch(tag) &&
                tag.isNotEmpty) {
              tagSet.add(tag);
            }
          }
        }
      }
      if (!mounted) return;
      setState(() => _availableTags = tagSet.toList()..sort());
    } catch (e) {
      debugPrint('获取标签列表失败: $e');
    }
  }

  void _showTagFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            decoration: const BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('选择标签筛选', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                if (_selectedTags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 6, runSpacing: 6,
                      children: _selectedTags.map((tag) => GestureDetector(
                        onTap: () {
                          setModalState(() => _selectedTags.remove(tag));
                          setState(() {});
                          _applyFilters();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,colors: AppColors.rainbowColors),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(tag, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                            const SizedBox(width: 4),
                            const Icon(Icons.close, color: AppColors.textPrimary, size: 12),
                          ]),
                        ),
                      )).toList(),
                    ),
                  ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                _selectedTags.remove(tag);
                              } else {
                                _selectedTags.add(tag);
                              }
                            });
                            setState(() {});
                            _applyFilters();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: isSelected ? AppColors.rainbowEnd.withOpacity(0.2) : AppColors.hoverBg,
                              border: Border.all(
                                color: isSelected ? AppColors.rainbowEnd : AppColors.borderColor,
                              ),
                            ),
                            child: Text(tag, style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 13,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() => _selectedTags.clear());
                          setState(() {});
                          _applyFilters();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderActive),
                          ),
                          child: const Center(child: Text('清除', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,colors: AppColors.rainbowColors),
                          ),
                          child: const Center(child: Text('确定', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchFollowingPosts() async {
    if (_followingIds.isEmpty) {
      setState(() {
        _posts = [];
        _followingPage = 0;
        _followingHasMore = false;
      });
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final res = await _supabase
          .from('posts')
          .select('*')
          .inFilter('user_id', _followingIds)
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(_followingPageSize);
      final posts = List<Map<String, dynamic>>.from(res as List? ?? []);
      await _enrichWithProfiles(posts);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _followingPage = 1;
        _followingHasMore = posts.length >= _followingPageSize;
        _loadingMore = false;
      });
    } catch (e) {
      debugPrint('获取关注帖子失败: $e');
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadMoreFollowingPosts() async {
    if (_loadingFollowingMore || !_followingHasMore || _followingIds.isEmpty) return;
    setState(() => _loadingFollowingMore = true);
    try {
      final offset = _followingPage * _followingPageSize;
      final res = await _supabase
          .from('posts')
          .select('*')
          .inFilter('user_id', _followingIds)
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .range(offset, offset + _followingPageSize - 1);
      final newPosts = List<Map<String, dynamic>>.from(res as List? ?? []);
      if (newPosts.isEmpty) {
        if (!mounted) return;
        setState(() {
          _followingHasMore = false;
          _loadingFollowingMore = false;
        });
        return;
      }
      await _enrichWithProfiles(newPosts);
      if (!mounted) return;
      setState(() {
        _posts = [..._posts, ...newPosts];
        _followingPage += 1;
        _followingHasMore = newPosts.length >= _followingPageSize;
        _loadingFollowingMore = false;
      });
    } catch (e) {
      debugPrint('加载更多关注帖子失败: $e');
      if (!mounted) return;
      setState(() => _loadingFollowingMore = false);
    }
  }

  List<Map<String, dynamic>> _applyTagFilter(List<Map<String, dynamic>> posts) {
    if (_selectedTags.isEmpty) return posts;
    return posts.where((p) {
      final tags = (p['tags'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toSet() ??
          {};
      return _selectedTags.any((t) => tags.contains(t));
    }).toList();
  }

  void _applyFilters() {
    if (_currentTab == 1) return;

    List<Map<String, dynamic>> filtered = List.from(_allPosts);
    filtered = _applyTagFilter(filtered);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final title = (p['title'] as String? ?? '').toLowerCase();
        final content = (p['content'] as String? ?? '').toLowerCase();
        final tags = (p['tags'] as List<dynamic>?)
                ?.map((t) => t.toString().toLowerCase())
                .toList() ??
            [];
        return title.contains(q) ||
            content.contains(q) ||
            tags.any((t) => t.contains(q));
      }).toList();
    }

    setState(() => _posts = filtered);
  }

  void _switchTab(int index) {
    if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GongjingScreen()));
      return;
    }
    if (index == 2) {
      _showTagFilterDialog();
      return;
    }
    if (index == _currentTab) return;
    setState(() => _currentTab = index);

    if (index == 1) {
      _followingPage = 0;
      _followingHasMore = true;
      _fetchFollowingPosts();
    } else {
      _applyFilters();
    }
  }

  void _openPostDetail(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
      ),
    );
  }

  void _openSidebar() {
    setState(() => _showSidebar = true);
  }

  void _closeSidebar() {
    setState(() => _showSidebar = false);
  }

  void _handleSidebarMenuItem(String menuItemId) {
    if (!mounted) return;
    switch (menuItemId) {
      case 'settings':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        break;
      case 'history':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        break;
      case 'download':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
        break;
      case 'covenant':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CovenantScreen()));
        break;
      case 'scan':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
        break;
      case 'support':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
        break;
      case 'vip':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VipScreen()));
        break;
      case 'admin':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('管理后台功能开发中...'), backgroundColor: AppColors.cardBg, behavior: SnackBarBehavior.floating),
        );
        break;
    }
  }

  void _openSearchPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _SearchPage(
      allPosts: _allPosts,
      onPostTap: _openPostDetail,
    )));
  }

  String _formatHotValue(int num) {
    if (num < 10000) return '$num';
    final wan = num / 10000;
    if (wan < 10) return wan % 1 == 0 ? '${wan.toInt()}W' : '${wan.toStringAsFixed(1)}W';
    return '${wan.toInt()}W';
  }


  // ==========================================================================
  // 每日签到逻辑
  // ==========================================================================
  Future<void> _checkTodayCheckin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final resp = await _supabase
          .from('checkin_records')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', '${today}T00:00:00')
          .lte('created_at', '${today}T23:59:59')
          .limit(1);
      if (mounted) {
        setState(() => _checkedInToday = (resp as List).isNotEmpty);
      }
    } catch (e) {
      debugPrint('Check checkin error: $e');
    }
  }

  Future<void> _doCheckin() async {
    if (_checkedInToday || _checkinLoading) return;
    setState(() => _checkinLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('未登录');

      // Check VIP status for bonus
      bool isVip = false;
      try {
        final profile = await _supabase
            .from('profiles')
            .select('is_vip')
            .eq('user_id', user.id)
            .maybeSingle();
        isVip = profile?['is_vip'] == true;
      } catch (e) { debugPrint('检查VIP状态失败: $e'); }

      final points = isVip ? 10 : 2;

      // Insert checkin record
      await _supabase.from('checkin_records').insert({
        'user_id': user.id,
      });

      // 直接更新 hot_points
      final current = await _supabase
          .from('profiles')
          .select('hot_points')
          .eq('user_id', user.id)
          .maybeSingle();
      final currentPoints = (current?['hot_points'] as num?)?.toInt() ?? 0;
      await _supabase
          .from('profiles')
          .update({'hot_points': currentPoints + points})
          .eq('user_id', user.id);

      if (!mounted) return;
      setState(() {
        _checkedInToday = true;
        _checkinLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('签到成功！+$points 热点'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Checkin error: $e');
      if (!mounted) return;
      // Fallback: direct update if RPC doesn't exist
      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase.from('checkin_records').insert({
            'user_id': user.id,
          });
          // Direct update
          final current = await _supabase
              .from('profiles')
              .select('hot_points')
              .eq('user_id', user.id)
              .maybeSingle();
          final currentPoints = (current?['hot_points'] as num?)?.toInt() ?? 0;
          final isVip = current?['is_vip'] == true;
          final points = isVip ? 10 : 2;
          await _supabase
              .from('profiles')
              .update({'hot_points': currentPoints + points})
              .eq('user_id', user.id);
          if (!mounted) return;
          setState(() {
            _checkedInToday = true;
            _checkinLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('签到成功！+$points 热点'),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e2) {
        debugPrint('Checkin fallback error: $e2');
        if (!mounted) return;
        setState(() => _checkinLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('签到失败: $e2'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Widget _buildCheckinBanner() {
    if (_checkedInToday) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.auroraGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.auroraGreen.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.auroraGreen, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '今日已签到 ✓',
                  style: TextStyle(color: AppColors.auroraGreen, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HeatingRecordsScreen()));
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('查看记录', style: TextStyle(color: AppColors.auroraGreen, fontSize: 12)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, color: AppColors.auroraGreen, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GestureDetector(
        onTap: _checkinLoading ? null : _doCheckin,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _checkinLoading
                ? null
                : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.auroraOrange, AppColors.auroraRed],
                  ),
            color: _checkinLoading ? AppColors.cardBg : null,
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '每日签到，领取热点奖励 🔥',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              _checkinLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '签到',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // UI 构建 - 完全对齐网页版 Home.tsx 结构
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    // 计算当前显示的帖子列表
    final displayPosts = _currentTab == 1 ? _posts : _posts;
    final isEmpty = displayPosts.isEmpty && _pinnedPosts.isEmpty && !_loading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ====== 主内容区 ======
          Positioned.fill(
            child: Column(
              children: [
                // --- 禁言提示横幅（对齐网页版 mx-4 mt-2）---
                if (_isMuted)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '你的账号已被禁言，评论和发布功能暂时受限',
                              style: TextStyle(color: AppColors.warning, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // --- Sticky Header (毛玻璃效果) ---
                _buildStickyHeader(),

                // --- 每日签到提醒 ---
                if (_currentTab == 0)
                  _buildCheckinBanner(),

                // --- HotRanking ---
                if (_currentTab == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: HotRanking(
                      onPostClick: (postId) {
                        final idx = displayPosts.indexWhere((p) => p['id'] == postId);
                        if (idx >= 0) {
                          _openPostDetail(displayPosts[idx]);
                        }
                      },
                    ),
                  ),

                // --- 已选标签区 (对齐网页版 px-4 mb-2) ---
                if (_selectedTags.isNotEmpty && _currentTab == 2)
                  _buildSelectedTagsBar(),

                // --- 置顶轮播区 (对齐网页版 px-4 mb-3) ---
                if (_pinnedPosts.isNotEmpty && _currentTab == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildPinnedCarousel(),
                  ),

                // --- Main 内容区 (两列网格) ---
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.rainbowEnd),
                        )
                      : _buildMainContent(displayPosts, isEmpty),
                ),
              ],
            ),
          ),

          // ====== 侧边栏覆盖层 ======
          if (_showSidebar)
            Sidebar(
              onClose: _closeSidebar,
              onMenuItemTap: _handleSidebarMenuItem,
              key: const ValueKey('home_sidebar'),
            ),
        ],
      ),
      // ====== 底部导航（对齐网页版 BottomNav） ======
      // bottomNavigationBar removed - managed by BottomNavScreen
    );
  }

  // ==========================================================================
  // Sticky Header - 毛玻璃效果（对齐网页版 header sticky top-0 z-40）
  // ==========================================================================
  Widget _buildStickyHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            // 对齐网页版: backgroundColor: var(--header-bg) = rgba(5, 8, 22, 0.92)
            color: AppColors.headerBg,
            border: Border(
              bottom: BorderSide(color: AppColors.borderColor, width: 0.5),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 16,
            right: 16,
            bottom: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 第一行：汉堡菜单 + 搜索栏
              Row(
                children: [
                  // 汉堡菜单按钮（对齐网页版 p-2 -ml-2 rounded-xl）
                  GestureDetector(
                    onTap: _openSidebar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(left: -4),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 搜索栏
                  Expanded(child: _buildSearchBar()),
                ],
              ),
              const SizedBox(height: 8),
              // Channel Tabs
              _buildChannelTabs(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 搜索栏（对齐网页版 SearchBar: bg-secondary背景, 圆角30px）
  // ==========================================================================
  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: _openSearchPage,
      child: Container(
        height: 40,
        // 对齐网页版: backgroundColor: var(--bg-secondary) = rgba(15, 15, 35, 0.75)
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            // 对齐网页版: icon color = var(--icon-color) = white
            const Icon(Icons.search, color: AppColors.iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '搜索笔记、用户、话题、房间...',
                // 对齐网页版: placeholder = var(--text-placeholder) = rgba(255,255,255,0.35)
                style: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Channel Tabs（对齐网页版 ChannelTabs: 推荐/关注/标签/共境）
  // 选中态：七彩边框(1px) + bgColor内层
  // 未选中态：透明背景 + borderColor(8%白)border
  // ==========================================================================
  Widget _buildChannelTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // 对齐网页版: gap-2 = 8px
      child: Row(
        children: [
          _buildTabItem(0, '推荐'),
          const SizedBox(width: 8),
          _buildTabItem(1, '关注'),
          const SizedBox(width: 8),
          _buildTabItem(2, '标签'),
          const SizedBox(width: 8),
          _buildTabItem(3, '共境'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isActive = _currentTab == index;
    if (isActive) {
      // 选中态：七彩边框(1px) + bgColor内层（铁律）
      return GestureDetector(
        onTap: () => _switchTab(index),
        child: Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: _auroraGradient,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bgColor,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Text(
              label,
              // 对齐网页版: text color = var(--text-color) = white
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }
    // 未选中态：透明背景 + borderColor border（对齐网页版）
    return GestureDetector(
      onTap: () => _switchTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // 对齐网页版: border = 1px solid rgba(255,255,255,0.08) = AppColors.borderColor
          border: Border.all(color: AppColors.borderColor, width: 1),
        ),
        child: Text(
          label,
          // 对齐网页版: text color = rgba(255,255,255,0.5)
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 已选标签栏（对齐网页版 px-4 mb-2 flex items-center gap-2 flex-wrap）
  // ==========================================================================
  Widget _buildSelectedTagsBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Text(
            '已选标签：',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 4),
          ..._selectedTags.map((tag) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.rainbowEnd.withOpacity(0.1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tag, style: TextStyle(color: AppColors.rainbowEnd, fontSize: 11)),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedTags.remove(tag));
                      _applyFilters();
                    },
                    child: const Icon(Icons.close, color: AppColors.rainbowEnd, size: 10),
                  ),
                ],
              ),
            ),
          )),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedTags.clear();
                _currentTab = 0;
              });
              _applyFilters();
            },
            child: Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 置顶轮播区（对齐网页版七彩边框 + #050816 内层）
  // ==========================================================================
  Widget _buildPinnedCarousel() {
    return Container(
      // 外层 1px 七彩渐变边框（铁律）
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.auroraRed.withOpacity(0.3),
            AppColors.auroraOrange.withOpacity(0.3),
            AppColors.auroraYellow.withOpacity(0.3),
            AppColors.auroraGreen.withOpacity(0.3),
            AppColors.auroraCyan.withOpacity(0.3),
            AppColors.auroraBlue.withOpacity(0.3),
            AppColors.auroraPurple.withOpacity(0.3),
          ],
        ),
      ),
      child: Container(
        // 内层 #050816（铁律）
        decoration: BoxDecoration(
          color: AppColors.bgColor,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 置顶标题行
            Row(
              children: [
                const Icon(Icons.push_pin, size: 14, color: AppColors.auroraOrange),
                const SizedBox(width: 6),
                const Text(
                  '置顶',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.auroraOrange),
                ),
                const SizedBox(width: 4),
                Text(
                  '· 轮播展示',
                  style: TextStyle(fontSize: 10, color: AppColors.textPlaceholder),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 横向滚动卡片列表
            SizedBox(
              height: 135,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pinnedPosts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final post = _pinnedPosts[index];
                  final title = post['title'] as String? ?? post['content'] as String? ?? '置顶';
                  final coverImage = post['cover_image'] as String?;
                  final profile = post['profiles'] as Map<String, dynamic>?;
                  final nickname = _extractNickname(profile);
                  return GestureDetector(
                    onTap: () => _openPostDetail(post),
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppColors.hoverBgLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 封面图
                          SizedBox(
                            width: 140,
                            height: 100,
                            child: _buildCoverImage(coverImage),
                          ),
                          // 标题
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // 作者
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                            child: Text(
                              nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: AppColors.textPlaceholder, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // Main 内容区（对齐网页版 main px-4, 两列网格）
  // ==========================================================================
  Widget _buildMainContent(List<Map<String, dynamic>> displayPosts, bool isEmpty) {
    if (_currentTab == 3) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('共境', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('功能即将上线', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    if (isEmpty) {
      return const _EmptyView();
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: AppColors.rainbowEnd,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 4),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // 最后一个item显示加载指示器
                  if (index == displayPosts.length) {
                    return _buildLoadMoreIndicator();
                  }
                  return _buildPostCard(displayPosts[index]);
                },
                childCount: displayPosts.length + (_hasMore || _loadingMore ? 1 : 0),
              ),
            ),
          ),
          // 底部间距
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 帖子卡片（对齐网页版 PostCard.tsx 样式）
  // ==========================================================================
  Widget _buildPostCard(Map<String, dynamic> post) {
    final profile = post['profiles'] as Map<String, dynamic>?;
    final nickname = _extractNickname(profile);
    final avatarUrl = profile?['avatar_url'] as String?;
    final faithTag = profile?['faith_tag'] as String? ?? '寻求者';
    final coverImage = post['cover_image'] as String?;
    final title = post['title'] as String? ?? '';
    final content = post['content'] as String? ?? '';
    final commentCount = (post['comments_count'] as num?)?.toInt() ?? 0;
    final hotValue = (post['heat_count'] as num?)?.toInt() ?? 0;

    // 提取可见标签（过滤内部标签）
    final tags = (post['tags'] as List<dynamic>?)
            ?.map((t) => t.toString())
            .where((t) => !t.startsWith('__') &&
                !t.startsWith('member_') &&
                !RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-').hasMatch(t) &&
                t.isNotEmpty)
            .toList() ??
        [];
    final firstTag = tags.isNotEmpty ? tags.first : null;

    return GestureDetector(
      onTap: () => _openPostDetail(post),
      child: Container(
        // 对齐网页版: rounded-xl overflow-hidden, backgroundColor: var(--card-bg)
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 封面图区域 (对齐网页版 w-full object-cover maxHeight: 200px) ---
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SizedBox(
                width: double.infinity,
                child: _buildCoverImage(coverImage),
              ),
            ),
            // --- 文字内容区域 (对齐网页版 p-3)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题行 + 标签（对齐网页版 flex items-center gap-2 mb-1）
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          // 对齐网页版: text-sm font-medium text-white
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (firstTag != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.borderColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            firstTag,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  // 摘要（对齐网页版 text-xs line-clamp-1 mb-2）
                  if (content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // 对齐网页版: text-xs text-[var(--text-weak)] = 12px, AppColors.textWeak
                        style: const TextStyle(
                          color: AppColors.textWeak,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  // --- 底部信息行 (对齐网页版 flex items-center justify-between) ---
                  Row(
                    children: [
                      // 左侧：头像 + 昵称 + 信仰标签
                      Expanded(
                        child: Row(
                          children: [
                            _buildAvatar(avatarUrl),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                // 对齐网页版: text-xs text-[var(--text-secondary)] font-medium
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (faithTag.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.hoverBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  faithTag,
                                  // 对齐网页版: color: rgba(255,255,255,0.4)
                                  style: const TextStyle(
                                    color: Color.fromRGBO(255, 255, 255, 0.4),
                                    fontSize: 8,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 右侧：评论数 + 热度
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (commentCount > 0) ...[
                            // 对齐网页版: MessageCircle icon color = var(--text-placeholder)
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 12,
                              color: AppColors.textPlaceholder,
                            ),
                            const SizedBox(width: 2),
                            // 对齐网页版: text-[10px] text-[var(--text-weak)]
                            Text(
                              '$commentCount',
                              style: const TextStyle(
                                color: AppColors.textWeak,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // 热度 - 七彩渐变图标+文字（对齐网页版 GradientFlame + aurora text）
                          ShaderMask(
                            shaderCallback: (bounds) => _auroraGradient.createShader(bounds),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_fire_department, color: AppColors.textPrimary, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  _formatHotValue(hotValue),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  // ==========================================================================
  // 辅助方法
  // ==========================================================================

  String _extractNickname(Map<String, dynamic>? profile) {
    final raw = profile?['nickname'] ?? profile?['username'] ?? '';
    if (raw.toString().startsWith('member_') ||
        (raw.toString().contains('-') && raw.toString().length > 20)) {
      return '匿名';
    }
    return raw.toString().isEmpty ? '匿名' : raw.toString();
  }

  Widget _buildCoverImage(String? coverImage) {
    if (coverImage == null || coverImage.isEmpty) {
      return _buildCoverPlaceholder();
    }
    if (coverImage.startsWith('data:image/')) {
      try {
        final base64Data = coverImage.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => _buildCoverPlaceholder(),
        );
      } catch (e) {
        return _buildCoverPlaceholder();
      }
    }
    if (coverImage.startsWith('http://') || coverImage.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: coverImage,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.inputBg,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.rainbowEnd,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildCoverPlaceholder(),
      );
    }
    return _buildCoverPlaceholder();
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cardBg, AppColors.bgColor],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_fire_department,
          color: AppColors.borderColor,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    return ClipOval(
      child: CircleAvatar(
        radius: 10,
        backgroundColor: AppColors.cardBg,
        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
            ? CachedNetworkImageProvider(avatarUrl)
            : null,
        child: (avatarUrl == null || avatarUrl.isEmpty)
            ? const Icon(Icons.person, size: 12, color: AppColors.textPlaceholder)
            : null,
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return SizedBox(
      height: 80,
      child: Center(
        child: _loadingMore
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.rainbowEnd,
              )
            : Text(
                _hasMore ? '' : '没有更多了',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
      ),
    );
  }
}

// =============================================================================
// 空状态视图
// =============================================================================
class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Text(
          '还没有动态',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text(
          '下拉刷新看看',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

// =============================================================================
// 独立搜索页面 - 保留原有实现
// =============================================================================
class _SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> allPosts;
  final void Function(Map<String, dynamic>) onPostTap;

  const _SearchPage({required this.allPosts, required this.onPostTap});

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final _controller = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _userResults = [];
  bool _searching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String query) async {
    if (query.isEmpty) {
      setState(() { _results = []; _userResults = []; _hasSearched = false; });
      return;
    }
    setState(() => _searching = true);
    try {
      final postsRes = await _supabase
          .from('posts')
          .select('id, title, content, cover_image, user_id, heat_count, comments_count')
          .eq('status', 'published')
          .or('title.ilike.%$query%,content.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(20);
      final posts = List<Map<String, dynamic>>.from(postsRes as List? ?? []);

      final usersRes = await _supabase
          .from('profiles')
          .select('user_id, username, nickname, avatar_url, faith_tag')
          .or('username.ilike.%$query%,nickname.ilike.%$query%')
          .limit(10);
      final users = List<Map<String, dynamic>>.from(usersRes as List? ?? []);

      if (!mounted) return;
      setState(() {
        _results = posts;
        _userResults = users;
        _searching = false;
        _hasSearched = true;
      });
    } catch (e) {
      debugPrint('搜索失败: $e');
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.borderColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: '搜索笔记、用户、话题...',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: _doSearch,
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _controller.clear();
                    _doSearch('');
                  },
                ),
            ],
          ),
        ),
      ),
      body: _searching
          ? const Center(child: CircularProgressIndicator(color: AppColors.rainbowEnd))
          : !_hasSearched
              ? const Center(
                  child: Text('输入关键词开始搜索',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_userResults.isNotEmpty) ...[
                      const Text('用户', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ..._userResults.map((u) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: (u['avatar_url'] != null && (u['avatar_url'] as String).isNotEmpty)
                                  ? CachedNetworkImageProvider(u['avatar_url'])
                                  : null,
                              child: (u['avatar_url'] == null || (u['avatar_url'] as String).isEmpty)
                                  ? const Icon(Icons.person, color: AppColors.textPlaceholder)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(u['nickname'] ?? u['username'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                              if (u['faith_tag'] != null) Text(u['faith_tag'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                            ]),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],
                    if (_results.isNotEmpty) ...[
                      const Text('笔记', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ..._results.map((post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onPostTap(post);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(post['title'] ?? '无标题',
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              if ((post['content'] ?? '').toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(post['content'] as String,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.local_fire_department, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 2),
                                Text('${post['heat_count'] ?? 0}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                const SizedBox(width: 8),
                                const Icon(Icons.comment_outlined, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 2),
                                Text('${post['comments_count'] ?? 0}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                              ]),
                            ]),
                          ),
                        ),
                      )),
                    ],
                    if (_results.isEmpty && _userResults.isEmpty && _hasSearched)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('未找到相关内容', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        ),
                      ),
                  ],
                ),
    );
  }
}
