import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/colors.dart';
import '../../i18n/app_localizations.dart';
import 'book_detail_screen.dart';
import 'religion_detail_screen.dart';
import '../../widgets/religion_icon.dart';
import 'holidays_data.dart';
import '../../services/learn_data_cache.dart';
import '../../utils/api_cache.dart';

class Religion {
  final String id;
  final String name;
  final String followersScale;
  final String? type;
  final String? introduction;
  Religion({required this.id, required this.name, required this.followersScale, this.type, this.introduction});
  factory Religion.fromMap(Map<String, dynamic> m) => Religion(id: m['id']?.toString() ?? '', name: m['name']?.toString() ?? '', followersScale: m['followers_scale']?.toString() ?? '', type: m['type']?.toString(), introduction: m['introduction']?.toString());
}

class BookItem {
  final String id;
  final String title;
  final String religion;
  final String category;
  final String description;
  final String? status;
  final String? groupId;
  BookItem({required this.id, required this.title, required this.religion, required this.category, required this.description, this.status, this.groupId});
  factory BookItem.fromMap(Map<String, dynamic> m) => BookItem(id: m['id']?.toString() ?? '', title: m['title']?.toString() ?? '', religion: m['religion']?.toString() ?? '', category: m['category']?.toString() ?? '', description: m['description']?.toString() ?? '', status: m['status']?.toString(), groupId: m['group_id']?.toString());
}

class BookGroup {
  final String id;
  final String name;
  final String? parentId;
  final List<String> bookIds;
  final List<String> groupIds;
  final bool isPublished;
  BookGroup({required this.id, required this.name, this.parentId, required this.bookIds, required this.groupIds, required this.isPublished});
  factory BookGroup.fromMap(Map<String, dynamic> m) {
    List<String> parseList(dynamic v) => v is List ? v.map((e) => e.toString()).toList() : [];
    return BookGroup(id: m['id']?.toString() ?? '', name: m['name']?.toString() ?? '', parentId: m['parent_id']?.toString(), bookIds: parseList(m['book_ids']), groupIds: parseList(m['group_ids']), isPublished: m['is_published'] != false);
  }
}

const _rainbowColors = [
  AppColors.auroraRed, AppColors.auroraOrange, AppColors.auroraYellow,
  AppColors.auroraGreen, AppColors.auroraCyan, AppColors.auroraBlue, AppColors.auroraPurple,
];

LinearGradient _diagonalGradient(Size size) {
  return LinearGradient(colors: _rainbowColors, transform: GradientRotation(0.785398));
}


class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _libraryTabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Religion> _religions = [];
  List<BookItem> _books = [];
  List<BookGroup> _groups = [];
  Map<String, int> _chaptersMap = {};
  bool _loading = true;
  DateTime _currentDate = DateTime.now();
  DateTime? _selectedDate;
  List<String> _bookmarks = [];
  List<Map<String, dynamic>> _readingHistory = [];
  List<Map<String, dynamic>> _notes = [];
  Map<String, Map<String, dynamic>> _readingProgress = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _libraryTabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) setState(() {}); });
    _libraryTabController.addListener(() { if (!_libraryTabController.indexIsChanging) _loadLocalData(); });
    _loadData();
    _loadLocalData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _libraryTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // 优先使用预加载缓存（网页版 preloadLearnData 对齐）
      final cache = LearnDataCache();
      if (cache.isLoaded) {
        if (cache.religions.isNotEmpty) {
          _religions = cache.religions.map((e) => Religion.fromMap(e)).toList();
        }
        if (cache.bookGroups.isNotEmpty) {
          _groups = cache.bookGroups.map((e) => BookGroup.fromMap(e)).toList();
        }
        if (cache.books.isNotEmpty) {
          _books = cache.books.map((e) => BookItem.fromMap(e)).toList();
        }
        if (cache.chaptersMap.isNotEmpty) {
          _chaptersMap = Map<String, int>.from(cache.chaptersMap);
        }
        if (mounted) setState(() => _loading = false);
        return;
      }

      // 缓存未就绪，尝试 ApiCache 二级缓存
      final apiCache = ApiCache.instance;
      final cachedReligions = await apiCache.get<List<dynamic>>('learn:religions');
      final cachedGroups = await apiCache.get<List<dynamic>>('learn:book_groups');
      final cachedBooks = await apiCache.get<List<dynamic>>('learn:books');

      if (cachedReligions != null && cachedGroups != null && cachedBooks != null) {
        // Use disk-cached data
        _religions = cachedReligions.map((e) => Religion.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        _groups = cachedGroups.map((e) => BookGroup.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        _books = cachedBooks.map((e) => BookItem.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        if (mounted) setState(() => _loading = false);
        // Background refresh
        _fetchAndCacheLearnData(apiCache);
        return;
      }

      // 全部未命中，走网络请求
      await _fetchAndCacheLearnData(apiCache);
    } catch (e) { debugPrint('loadData error: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }


  /// Fetch learn data from network and cache via ApiCache (30-min TTL).
  Future<void> _fetchAndCacheLearnData(ApiCache apiCache) async {
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client.from('religions').select().eq('is_active', true).order('sort_order').order('name'),
        client.from('book_groups').select().order('created_at'),
        client.from('books').select().order('sort_order').order('title'),
        client.from('chapters').select('book_id').limit(1000),
      ]);

      const ttl = Duration(minutes: 30);
      if (results[0].isNotEmpty) {
        final data = results[0] as List;
        _religions = data.map((e) => Religion.fromMap(e as Map<String, dynamic>)).toList();
        await apiCache.set('learn:religions', data, ttl: ttl);
      }
      if (results[1].isNotEmpty) {
        final data = results[1] as List;
        _groups = data.map((e) => BookGroup.fromMap(e as Map<String, dynamic>)).toList();
        await apiCache.set('learn:book_groups', data, ttl: ttl);
      }
      if (results[2].isNotEmpty) {
        final data = results[2] as List;
        _books = data.map((e) => BookItem.fromMap(e as Map<String, dynamic>)).toList();
        await apiCache.set('learn:books', data, ttl: ttl);
      }
      if (results[3].isNotEmpty) {
        final chapters = results[3] as List;
        _chaptersMap = {};
        for (final ch in chapters) {
          final bookId = (ch as Map<String, dynamic>)['book_id']?.toString();
          if (bookId != null) _chaptersMap[bookId] = (_chaptersMap[bookId] ?? 0) + 1;
        }
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('loadData network error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarks') ?? [];
    final history = prefs.getStringList('reading_history') ?? [];
    final notesList = prefs.getStringList('reading_notes') ?? [];
    List<Map<String, dynamic>> parsedHistory = [];
    for (final h in history) { try { parsedHistory.add(jsonDecode(h) as Map<String, dynamic>); } catch (e) { debugPrint('解析阅读历史数据失败: $e'); } }
    List<Map<String, dynamic>> parsedNotes = [];
    for (final n in notesList) { try { parsedNotes.add(jsonDecode(n) as Map<String, dynamic>); } catch (e) { debugPrint('解析阅读笔记数据失败: $e'); } }
    Map<String, Map<String, dynamic>> progress = {};
    for (final bid in bookmarks) {
      final p = prefs.getString('reading_progress_$bid');
      if (p != null) { try { progress[bid] = jsonDecode(p) as Map<String, dynamic>; } catch (e) { debugPrint('解析阅读进度数据失败: $e'); } }
    }
    if (mounted) { setState(() { _bookmarks = bookmarks; _readingHistory = parsedHistory; _notes = parsedNotes; _readingProgress = progress; }); }
  }

  List<Religion> get _filteredReligions => _searchQuery.isEmpty ? _religions : _religions.where((r) => r.name.contains(_searchQuery)).toList();
  List<ReligiousHoliday> get _filteredHolidays => _searchQuery.isEmpty ? [] : religiousHolidays.where((h) => h.name.contains(_searchQuery) || h.religion.contains(_searchQuery)).toList();
  List<ReligiousHoliday> _getHolidaysForDate(int day) => religiousHolidays.where((h) => h.month == _currentDate.month && h.day == day).toList();
  List<ReligiousHoliday> get _monthHolidays => religiousHolidays.where((h) => h.month == _currentDate.month).toList();
  bool _isToday(int day) { final now = DateTime.now(); return day == now.day && _currentDate.month == now.month && _currentDate.year == now.year; }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [_buildHeader(), Expanded(child: TabBarView(controller: _tabController, children: [_buildEncyclopediaTab(), _buildLibraryTab(), _buildCalendarTab()])), _buildContributionFooter()])),
    );
  }

  // ========== HEADER ==========
  Widget _buildHeader() {
    String hint = [context.tr('learn_search_religions'), context.tr('learn_search_books'), context.tr('learn_search_holidays')][_tabController.index];
    return Container(
      // Sticky header: headerBg + border-bottom
      decoration: BoxDecoration(
        color: AppColors.headerBg,
        border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Column(children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const SizedBox(width: 12),
                Icon(Icons.search, color: AppColors.iconColorWeak, size: 18),
                const SizedBox(width: 8),
                Expanded(child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                )),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.iconColorWeak, size: 18),
                    onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 12),
              ]),
            ),
          ),
          // Main tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(),
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: EdgeInsets.zero,
              tabAlignment: TabAlignment.fill,
              tabs: [
                _buildTab(context.tr('learn_tab_encyclopedia'), Icons.menu_book, 0),
                _buildTab(context.tr('learn_tab_library'), Icons.library_books, 1),
                _buildTab(context.tr('learn_tab_calendar'), Icons.calendar_today, 2),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ========== MAIN TAB (七彩边框铁律) ==========
  Widget _buildTab(String label, IconData icon, int index) {
    return Tab(child: Builder(builder: (context) {
      final active = _tabController.index == index;
      // Outer: 1px gradient padding when active
      return Container(
        padding: active ? const EdgeInsets.all(1) : EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: active ? AppColors.auroraGradient : null,
        ),
        child: Container(
          // Inner: bgColor when active, transparent when not
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active ? AppColors.bgColor : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: active ? AppColors.textPrimary.withOpacity(0.95) : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(
                color: active ? AppColors.textPrimary.withOpacity(0.95) : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              )),
            ],
          ),
        ),
      );
    }));
  }

  // ========== ENCYCLOPEDIA TAB ==========
  Widget _buildEncyclopediaTab() {
    if (_searchQuery.isNotEmpty) return _buildSearchResults();
    if (_religions.isEmpty && !_loading) return Center(child: Text(context.tr('learn_no_data'), style: TextStyle(color: AppColors.textSecondary)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemCount: _filteredReligions.length,
        itemBuilder: (c, i) {
          final r = _filteredReligions[i];
          return GestureDetector(
            onTap: () {
              final holidays = religiousHolidays.where((h) => h.religion == r.name).toList();
              Navigator.push(context, MaterialPageRoute(builder: (_) => ReligionDetailScreen(
                religionId: r.id, religionName: r.name, followersScale: r.followersScale,
                type: r.type, introduction: r.introduction, holidays: holidays,
              )));
            },
            child: Container(
              // inputBg background + 10% white border + rounded-xl
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    // 宗教专属 CustomPaint 图标（对齐网页版 SVG）
                    ReligionIconWidget(name: r.name, size: 28),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    )),
                  ]),
                  const SizedBox(height: 6),
                  Expanded(child: Text(r.followersScale,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ========== SEARCH RESULTS ==========
  Widget _buildSearchResults() {
    final holidays = _filteredHolidays;
    if (holidays.isEmpty) return Center(child: Text(context.tr('learn_no_results'), style: TextStyle(color: AppColors.textSecondary)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: holidays.length,
      itemBuilder: (c, i) => _buildHolidayListItem(holidays[i]),
    );
  }

  // ========== LIBRARY TAB ==========
  Widget _buildLibraryTab() {
    if (_loading) return Center(child: CircularProgressIndicator(color: AppColors.textSecondary));
    return Column(children: [
      // Library sub-tabs
      Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLibSubTab(context.tr('learn_books'), Icons.library_books, 0),
            const SizedBox(width: 12),
            _buildLibSubTab(context.tr('learn_shelf'), Icons.bookmark, 1),
            const SizedBox(width: 12),
            _buildLibSubTab(context.tr('learn_notes'), Icons.edit_note, 2),
            const SizedBox(width: 12),
            _buildLibSubTab(context.tr('learn_history'), Icons.history, 3),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Expanded(child: TabBarView(
        controller: _libraryTabController,
        children: [_buildClassicsSubTab(), _buildShelfSubTab(), _buildNotesSubTab(), _buildHistorySubTab()],
      )),
    ]);
  }

  // ========== LIBRARY SUB-TAB (七彩边框铁律) ==========
  Widget _buildLibSubTab(String label, IconData icon, int index) {
    return GestureDetector(
      onTap: () => setState(() => _libraryTabController.index = index),
      child: Builder(builder: (context) {
        final active = _libraryTabController.index == index;
        return Container(
          // Outer: 1px gradient when active
          padding: active ? const EdgeInsets.all(1) : EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: active ? AppColors.auroraGradient : null,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              // Inner: bgColor when active, bgSecondary when not
              color: active ? AppColors.bgColor : AppColors.bgSecondary,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: active ? AppColors.textPrimary.withOpacity(0.95) : AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(
                  color: active ? AppColors.textPrimary.withOpacity(0.95) : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ========== CLASSICS SUB-TAB ==========
  Widget _buildClassicsSubTab() {
    final topLevel = _getTopLevelGroups();
    final ungrouped = _getUngroupedBooks();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...topLevel.map((g) {
            final children = _getChildGroups(g.id);
            final books = _getGroupBooks(g.id);
            final hasChildren = children.isNotEmpty || books.isNotEmpty;
            return GestureDetector(
              onTap: hasChildren ? () => _navigateIntoGroup(g) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.hoverBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.library_books, color: AppColors.textPrimary.withOpacity(0.7), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        Text([
                          if (children.isNotEmpty) '${children.length} sub',
                          if (children.isNotEmpty && books.isNotEmpty) ' \u00b7 ',
                          if (books.isNotEmpty) '${books.length} vol',
                        ].join(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    )),
                    if (hasChildren) Icon(Icons.chevron_right,
                      color: AppColors.textPlaceholder, size: 20),
                  ],
                ),
              ),
            );
          }),
          if (ungrouped.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(context.tr('learn_other_classics'), style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...ungrouped.map((b) => _buildBookCard(b)),
          ],
          if (topLevel.isEmpty && _books.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(context.tr('learn_no_books'), style: TextStyle(color: AppColors.textSecondary)))),
        ],
      ),
    );
  }

  // ========== SHELF SUB-TAB ==========
  Widget _buildShelfSubTab() {
    if (_bookmarks.isEmpty) return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bookmark_border, color: AppColors.textPlaceholder, size: 48),
        const SizedBox(height: 12),
        Text(context.tr('learn_shelf_empty'), style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 4),
        Text(context.tr('learn_add_from_library'), style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
      ],
    ));
    final bBooks = _books.where((b) => _bookmarks.contains(b.id)).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${context.tr('learn_my_shelf')} (${bBooks.length})', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...bBooks.map((book) {
            final progress = _readingProgress[book.id];
            final totalCh = _chaptersMap[book.id] ?? 0;
            int curIdx = 0;
            String chTitle = '';
            if (progress != null) {
              curIdx = (progress['chapterIndex'] as num?)?.toInt() ?? 0;
              chTitle = progress['chapterTitle']?.toString() ?? '';
            }
            final pct = totalCh > 0 ? (curIdx + 1) / totalCh : 0.0;
            return GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(
                  bookId: book.id, bookTitle: book.title, bookReligion: book.religion,
                  bookCategory: book.category, bookDescription: book.description,
                )));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.hoverBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.menu_book, color: AppColors.textPrimary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('${book.religion} \u00b7 ${book.category}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      )),
                      Icon(Icons.chevron_right, color: AppColors.textPlaceholder, size: 20),
                    ]),
                    if (totalCh > 0) ...[
                      const SizedBox(height: 10),
                      // Rainbow progress bar (matching web version)
                      LayoutBuilder(builder: (context, constraints) {
                        return Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: constraints.maxWidth * pct.clamp(0.0, 1.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(colors: [
                                  AppColors.auroraRed, AppColors.auroraOrange, AppColors.auroraYellow,
                                  AppColors.auroraGreen, AppColors.auroraCyan,
                                ]),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (chTitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('${context.tr('learn_reading')}: $chTitle', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ========== NOTES SUB-TAB (with left rainbow gradient bar like web) ==========
  Widget _buildNotesSubTab() {
    if (_notes.isEmpty) return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.edit_note, color: AppColors.textPlaceholder, size: 48),
        const SizedBox(height: 12),
        Text(context.tr('learn_no_notes'), style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    ));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (c, i) {
        final note = _notes[i];
        return GestureDetector(
          onTap: () {
            final bid = note['bookId']?.toString() ?? '';
            final book = _books.where((b) => b.id == bid).firstOrNull;
            if (book != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(
                bookId: book.id, bookTitle: book.title, bookReligion: book.religion,
                bookCategory: book.category, bookDescription: book.description,
              )));
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left rainbow gradient bar (like web insights)
                  Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _rainbowColors,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note['bookTitle']?.toString() ?? '',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                          if (note['chapterTitle'] != null) ...[
                            const SizedBox(height: 4),
                            Text(note['chapterTitle'].toString(),
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                          const SizedBox(height: 8),
                          Text(note['content']?.toString() ?? '',
                            style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7), fontSize: 13, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ========== HISTORY SUB-TAB ==========
  Widget _buildHistorySubTab() {
    if (_readingHistory.isEmpty) return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.history, color: AppColors.textPlaceholder, size: 48),
        const SizedBox(height: 12),
        Text(context.tr('learn_no_history'), style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    ));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _readingHistory.length,
      itemBuilder: (c, i) {
        final rec = _readingHistory[i];
        final bTitle = rec['bookTitle']?.toString() ?? '';
        final cTitle = rec['chapterTitle']?.toString() ?? '';
        final ts = rec['timestamp']?.toString() ?? '';
        return GestureDetector(
          onTap: () {
            final bid = rec['bookId']?.toString() ?? '';
            final book = _books.where((b) => b.id == bid).firstOrNull;
            if (book != null) Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(
              bookId: book.id, bookTitle: book.title, bookReligion: book.religion,
              bookCategory: book.category, bookDescription: book.description,
            )));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.hoverBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.menu_book, color: AppColors.textPrimary.withOpacity(0.7), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bTitle, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(cTitle.isNotEmpty ? '${context.tr('learn_reading')}: $cTitle' : '',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    if (ts.isNotEmpty) Text(_formatTs(ts),
                      style: TextStyle(color: AppColors.textWeak, fontSize: 11)),
                  ],
                )),
                Icon(Icons.chevron_right, color: AppColors.textPlaceholder, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTs(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Now';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.month}/${dt.day}';
    } catch (_) { return ''; }
  }

  List<BookGroup> _getTopLevelGroups() {
    final cids = <String>{};
    for (final g in _groups) { if (g.groupIds.isNotEmpty) cids.addAll(g.groupIds); }
    return _groups.where((g) => (g.groupIds.isNotEmpty && g.isPublished) || (!cids.contains(g.id) && g.isPublished)).toList();
  }

  List<BookGroup> _getChildGroups(String pid) {
    final p = _groups.where((g) => g.id == pid).firstOrNull;
    if (p == null || p.groupIds.isEmpty) return [];
    return _groups.where((g) => p.groupIds.contains(g.id) && g.isPublished).toList();
  }

  List<BookItem> _getGroupBooks(String gid) {
    final g = _groups.where((gr) => gr.id == gid).firstOrNull;
    final ids = (g?.bookIds ?? []).toSet();
    return _books.where((b) => ids.contains(b.id) || b.groupId == gid).toList();
  }

  List<BookItem> _getUngroupedBooks() {
    if (_groups.isEmpty) return _books;
    final ids = <String>{};
    for (final g in _groups) { ids.addAll(g.bookIds); }
    return _books.where((b) => (b.status == 'published' || b.status == null || b.status == '') && !ids.contains(b.id) && (b.groupId == null || b.groupId == '')).toList();
  }

  void _navigateIntoGroup(BookGroup group) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(
      group: group, allGroups: _groups, allBooks: _books, chaptersMap: _chaptersMap,
    )));
  }

  // ========== BOOK CARD ==========
  Widget _buildBookCard(BookItem book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(
          bookId: book.id, bookTitle: book.title, bookReligion: book.religion,
          bookCategory: book.category, bookDescription: book.description,
        )));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.hoverBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.menu_book, color: AppColors.textPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                Text([
                  book.category.isNotEmpty ? book.category : book.religion,
                  if (_chaptersMap.containsKey(book.id)) ' \u00b7 ${_chaptersMap[book.id]} ch',
                ].join(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            )),
            Icon(Icons.chevron_right, color: AppColors.textPlaceholder, size: 20),
          ],
        ),
      ),
    );
  }


  // ========== CONTRIBUTION FOOTER (参与共建) ==========
  Widget _buildContributionFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: GestureDetector(
        onTap: _showContributionDialog,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: AppColors.auroraGradient,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: AppColors.bgColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(Icons.volunteer_activism, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              const Text(
                '参与共建',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContributionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.auroraGradient,
                ),
                child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                '参与共建',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'OpenFaith 是一个开源项目，欢迎参与书籍整理、翻译、校对等工作。\n\n'
                '您可以通过以下方式参与：\n'
                '• 整理经典文献数字化\n'
                '• 翻译多语种版本\n'
                '• 校对已有内容\n'
                '• 贡献新的研究成果\n\n'
                '每一份贡献都将帮助更多人了解世界信仰文化。',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse('https://openfaithhub.com/#/support');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.auroraGradient,
                  ),
                  child: const Center(
                    child: Text(
                      '访问共建页面',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '关闭',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== CALENDAR TAB ==========
  Widget _buildCalendarTab() {
    if (_searchQuery.isNotEmpty) return _buildSearchResults();
    final year = _currentDate.year;
    final month = _currentDate.month;
    final firstDay = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final wk = (jsonDecode(context.tr('calendar_weekdays')) as List).cast<String>();
    final mn = (jsonDecode(context.tr('calendar_months')) as List).cast<String>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar card
          Container(
            decoration: BoxDecoration(
              color: AppColors.hoverBgLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              children: [
                // Month navigation header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: AppColors.textPrimary.withOpacity(0.7), size: 20),
                        onPressed: () => setState(() { _currentDate = DateTime(year, month - 1, 1); _selectedDate = null; }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _showYearPicker,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('$year', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_drop_down, color: AppColors.textPrimary, size: 20),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _showMonthPicker,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(mn[month - 1], style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_drop_down, color: AppColors.textPrimary, size: 20),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: AppColors.textPrimary.withOpacity(0.7), size: 20),
                        onPressed: () => setState(() { _currentDate = DateTime(year, month + 1, 1); _selectedDate = null; }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Weekday headers
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: wk.map((d) => Expanded(child: Center(
                      child: Text(d, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500)),
                    ))).toList(),
                  ),
                ),
                // Day grid
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                    itemCount: firstDay + daysInMonth,
                    itemBuilder: (c, index) {
                      if (index < firstDay) return const SizedBox.shrink();
                      final day = index - firstDay + 1;
                      final holidays = _getHolidaysForDate(day);
                      final hasH = holidays.isNotEmpty;
                      final isT = _isToday(day);
                      final isSel = _selectedDate != null && _selectedDate!.day == day && _selectedDate!.month == month;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = DateTime(year, month, day)),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final size = Size(constraints.maxWidth, constraints.maxHeight);
                          return Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isT ? null : isSel ? AppColors.hoverBg : hasH ? AppColors.hoverBgLight : null,
                              borderRadius: BorderRadius.circular(8),
                              border: isT ? null : isSel ? Border.all(color: AppColors.borderActive) : hasH ? Border.all(color: AppColors.borderSubtle) : null,
                              gradient: isT ? _diagonalGradient(size) : null,
                            ),
                            child: isT
                              ? Container(
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgColor,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: Center(child: Text('$day', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500))),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('$day', style: TextStyle(
                                      color: isSel || hasH ? Colors.white : AppColors.textPrimary.withOpacity(0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    )),
                                    if (hasH) Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        holidays.length > 3 ? 3 : holidays.length,
                                        (_) => Container(
                                          width: 4, height: 4,
                                          margin: const EdgeInsets.symmetric(horizontal: 1),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: AppColors.auroraGradient,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Selected date holidays
          if (_selectedDate != null) _buildSelectedDateHolidays(),
          const SizedBox(height: 8),
          Text(context.tr('learn_this_month'), style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (_monthHolidays.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.tr('learn_no_holidays'), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ))
          else
            ..._monthHolidays.map((h) => _buildHolidayListItem(h)),
        ],
      ),
    );
  }

  // ========== SELECTED DATE HOLIDAYS ==========
  Widget _buildSelectedDateHolidays() {
    final holidays = _getHolidaysForDate(_selectedDate!.day);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hoverBgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_selectedDate!.month}/${_selectedDate!.day}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          if (holidays.isEmpty)
            Text(context.tr('learn_none_today'), style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
          else
            ...holidays.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.auroraGradient,
                )),
                const SizedBox(width: 8),
                Text(h.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                const SizedBox(width: 6),
                Text('(${h.religion})', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            )),
        ],
      ),
    );
  }

  // ========== HOLIDAY LIST ITEM ==========
  Widget _buildHolidayListItem(ReligiousHoliday holiday) {
    return GestureDetector(
      onTap: () => _showHolidayDetail(holiday),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.hoverBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            // Day number with gradient
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.hoverBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Builder(builder: (context) {
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _rainbowColors,
                      ).createShader(bounds);
                    },
                    child: Text('${holiday.day}',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  );
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holiday.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(holiday.religion, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            )),
            Icon(Icons.chevron_right, color: AppColors.textPlaceholder, size: 20),
          ],
        ),
      ),
    );
  }

  // ========== HOLIDAY DETAIL DIALOG ==========
  void _showHolidayDetail(ReligiousHoliday holiday) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: _rainbowColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF050816),
            borderRadius: BorderRadius.circular(17),
          ),
          padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(holiday.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textPrimary.withOpacity(0.5), size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [
                Text(context.tr('learn_date'), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text('${holiday.month}/${holiday.day}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Text(context.tr('learn_religion_label'), style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(holiday.religion, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.hoverBgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(holiday.desc, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
              ),
              if (holiday.detail.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.hoverBgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('learn_detail'), style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text(holiday.detail, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7), fontSize: 13, height: 1.5)),
                    ],
                  ),
                ),
              ],
              if (holiday.yi.isNotEmpty || holiday.ji.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: [
                  if (holiday.yi.isNotEmpty) Expanded(child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.auroraGreen.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.auroraGreen.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('learn_yi'), style: TextStyle(color: AppColors.auroraGreen.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(holiday.yi, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7), fontSize: 13, height: 1.4)),
                      ],
                    ),
                  )),
                  if (holiday.yi.isNotEmpty && holiday.ji.isNotEmpty) const SizedBox(width: 8),
                  if (holiday.ji.isNotEmpty) Expanded(child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.auroraRed.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.auroraRed.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('learn_ji'), style: TextStyle(color: AppColors.auroraRed.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(holiday.ji, style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7), fontSize: 13, height: 1.4)),
                      ],
                    ),
                  )),
                ]),
              ],
            ],
          ),
        ),
      ),
    ),
    ));
  }

  // ========== YEAR PICKER ==========
  void _showYearPicker() {
    final cy = _currentDate.year;
    final years = List.generate(21, (i) => cy - 10 + i);
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('calendar_year'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (c, i) {
                  final y = years[i];
                  final sel = y == cy;
                  return GestureDetector(
                    onTap: () {
                      setState(() { _currentDate = DateTime(y, _currentDate.month, 1); _selectedDate = null; });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.hoverBg : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text('$y', style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 14))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }

  // ========== MONTH PICKER ==========
  void _showMonthPicker() {
    final mn = (jsonDecode(context.tr('calendar_months')) as List).cast<String>();
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('calendar_month'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: ListView.builder(
                itemCount: 12,
                itemBuilder: (c, i) {
                  final sel = i == _currentDate.month - 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() { _currentDate = DateTime(_currentDate.year, i + 1, 1); _selectedDate = null; });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.hoverBg : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: Text(mn[i], style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 14))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

// ========== GROUP DETAIL SCREEN ==========
class GroupDetailScreen extends StatelessWidget {
  final BookGroup group;
  final List<BookGroup> allGroups;
  final List<BookItem> allBooks;
  final Map<String, int> chaptersMap;
  const GroupDetailScreen({super.key, required this.group, required this.allGroups, required this.allBooks, required this.chaptersMap});

  @override
  Widget build(BuildContext context) {
    final childGroups = allGroups.where((g) => group.groupIds.contains(g.id) && g.isPublished).toList();
    final bookIds = group.bookIds.toSet();
    final groupBooks = allBooks.where((b) => bookIds.contains(b.id) || b.groupId == group.id).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text(group.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...childGroups.map((sg) {
              final sc = allGroups.where((g) => sg.groupIds.contains(g.id) && g.isPublished).toList();
              final sb = allBooks.where((b) => sg.bookIds.contains(b.id) || b.groupId == sg.id).toList();
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(
                  group: sg, allGroups: allGroups, allBooks: allBooks, chaptersMap: chaptersMap,
                ))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.hoverBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.folder, color: AppColors.textPrimary.withOpacity(0.7), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sg.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                          Text([
                            if (sc.isNotEmpty) '${sc.length} sub',
                            if (sc.isNotEmpty && sb.isNotEmpty) ' \u00b7 ',
                            if (sb.isNotEmpty) '${sb.length} vol',
                          ].join(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      )),
                      Icon(Icons.chevron_right, color: AppColors.textPlaceholder, size: 20),
                    ],
                  ),
                ),
              );
            }),
            if (groupBooks.isNotEmpty) ...[
              if (childGroups.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(context.tr('learn_books_title'), style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
              ],
              ...groupBooks.map((b) => GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(
                    bookId: b.id, bookTitle: b.title, bookReligion: b.religion,
                    bookCategory: b.category, bookDescription: b.description,
                  )));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.hoverBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.menu_book, color: AppColors.textPrimary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                          Text([
                            b.category.isNotEmpty ? b.category : b.religion,
                            if (chaptersMap.containsKey(b.id)) ' \u00b7 ${chaptersMap[b.id]} ch',
                          ].join(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      )),
                      Icon(Icons.chevron_right, color: AppColors.textPlaceholder, size: 20),
                    ],
                  ),
                ),
              )),
            ],
            if (childGroups.isEmpty && groupBooks.isEmpty)
              Center(child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.tr('learn_no_content'), style: TextStyle(color: AppColors.textSecondary)),
              )),
          ],
        ),
      ),
    );
  }
}
