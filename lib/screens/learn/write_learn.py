#!/usr/bin/env python3
# Script to write the complete learn_screen.dart file
import os

path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'learn_screen.dart')

parts = []

# Part 1
parts.append(r"""import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';
import 'book_detail_screen.dart';
import 'religion_detail_screen.dart';
import 'holidays_data.dart';

// ====== Data Models ======
class Religion {
  final String id;
  final String name;
  final String followersScale;
  final String? type;
  final String? introduction;
  Religion({required this.id, required this.name, required this.followersScale, this.type, this.introduction});
  factory Religion.fromMap(Map<String, dynamic> m) => Religion(
    id: m['id']?.toString() ?? '', name: m['name']?.toString() ?? '',
    followersScale: m['followers_scale']?.toString() ?? '',
    type: m['type']?.toString(), introduction: m['introduction']?.toString());
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
  factory BookItem.fromMap(Map<String, dynamic> m) => BookItem(
    id: m['id']?.toString() ?? '', title: m['title']?.toString() ?? '',
    religion: m['religion']?.toString() ?? '', category: m['category']?.toString() ?? '',
    description: m['description']?.toString() ?? '',
    status: m['status']?.toString(), groupId: m['group_id']?.toString());
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
    return BookGroup(id: m['id']?.toString() ?? '', name: m['name']?.toString() ?? '',
      parentId: m['parent_id']?.toString(), bookIds: parseList(m['book_ids']),
      groupIds: parseList(m['group_ids']), isPublished: m['is_published'] != false);
  }
}
""")

# Part 2 - Cache
parts.append(r"""
// ====== Cache (stale-while-revalidate) ======
const String _cachePrefix = 'learn_cache_';
const int _cacheTtlMs = 60 * 60 * 1000;

Future<T?> _getCache<T>(String key) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_cachePrefix$key');
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = decoded['timestamp'] as int;
      if (DateTime.now().millisecondsSinceEpoch - timestamp < _cacheTtlMs) {
        return decoded['data'] as T;
      }
    }
  } catch (_) {}
  return null;
}

Future<void> _setCache(String key, dynamic data) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachePrefix + key, jsonEncode({'data': data, 'timestamp': DateTime.now().millisecondsSinceEpoch}));
  } catch (_) {}
}

Future<List<dynamic>> _apiRequest(String endpoint, {bool useCache = true}) async {
  if (useCache) {
    final cached = await _getCache<List<dynamic>>(endpoint);
    if (cached != null) {
      _fetchFresh(endpoint).then((fresh) { if (fresh.isNotEmpty) _setCache(endpoint, fresh); }).catchError((_) => []);
      return cached;
    }
  }
  return _fetchFresh(endpoint);
}

Future<List<dynamic>> _fetchFresh(String endpoint) async {
  try {
    final client = Supabase.instance.client;
    final parts = endpoint.split('?');
    final table = parts[0];
    final params = parts.length > 1 ? Uri.splitQueryString(parts[1]) : <String, String>{};
    var query = client.from(table).select();
    if (params.containsKey('is_active') && params['is_active'] == 'eq.true') query = query.eq('is_active', true);
    if (params.containsKey('order')) {
      final op = params['order']!.split('.');
      if (op.length == 2) query = query.order(op[0], ascending: op[1] == 'asc');
    }
    if (params.containsKey('limit')) query = query.limit(int.parse(params['limit']!));
    final response = await query;
    final result = (response as List).cast<dynamic>();
    await _setCache(endpoint, result);
    return result;
  } catch (e) {
    debugPrint('API request failed: $e');
    return [];
  }
}

void preloadLearnData() {
  for (final ep in ['religions?is_active=eq.true&order=sort_order.asc', 'book_groups?order=created_at.asc', 'books?order=sort_order.asc', 'chapters?select=book_id&limit=1000']) {
    _fetchFresh(ep).catchError((_) => []);
  }
}
""")

# Part 3 - Rainbow gradient and main class
parts.append(r"""
const LinearGradient _rainbowGradient = LinearGradient(
  colors: [Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A), Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);

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
  String _contributionType = '';
  final TextEditingController _contributionSourceController = TextEditingController();
  final TextEditingController _contributionContentController = TextEditingController();
  bool _contributionSubmitting = false;

  List<String> get _contributionTypes {
    if (_tabController.index == 2) return ['节日修正', '缺失节日', '日期错误', '宜忌建议', '翻译修正', '其他内容建议'];
    return ['翻译修正', '缺失内容', '错别字', '排版错误', '神学术语建议', '更权威译本推荐', '公版版权信息', '其他内容建议'];
  }

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
    _contributionSourceController.dispose();
    _contributionContentController.dispose();
    super.dispose();
  }
""")

# Part 4 - Data loading
parts.append(r"""
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _apiRequest('religions?is_active=eq.true&order=sort_order.asc'),
        _apiRequest('book_groups?order=created_at.asc'),
        _apiRequest('books?order=sort_order.asc'),
        _apiRequest('chapters?select=book_id&limit=1000'),
      ]);
      if (results[0].isNotEmpty) _religions = (results[0]).map((e) => Religion.fromMap(e as Map<String, dynamic>)).toList();
      if (results[1].isNotEmpty) _groups = (results[1]).map((e) => BookGroup.fromMap(e as Map<String, dynamic>)).toList();
      if (results[2].isNotEmpty) _books = (results[2]).map((e) => BookItem.fromMap(e as Map<String, dynamic>)).toList();
      if (results[3].isNotEmpty) {
        final chapters = results[3];
        _chaptersMap = {};
        for (final ch in chapters) {
          final bookId = (ch as Map<String, dynamic>)['book_id']?.toString();
          if (bookId != null) _chaptersMap[bookId] = (_chaptersMap[bookId] ?? 0) + 1;
        }
        if (chapters.length == 1000) {
          try {
            final client = Supabase.instance.client;
            final batch2 = await client.from('chapters').select('book_id').limit(1000).offset(1000);
            for (final ch in batch2) {
              final bookId = (ch as Map<String, dynamic>)['book_id']?.toString();
              if (bookId != null) _chaptersMap[bookId] = (_chaptersMap[bookId] ?? 0) + 1;
            }
          } catch (_) {}
        }
      }
    } catch (e) { debugPrint('loadData error: $e'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarks') ?? [];
    final history = prefs.getStringList('reading_history') ?? [];
    final notesList = prefs.getStringList('reading_notes') ?? [];
    List<Map<String, dynamic>> parsedHistory = [];
    for (final h in history) { try { parsedHistory.add(jsonDecode(h) as Map<String, dynamic>); } catch (_) {} }
    List<Map<String, dynamic>> parsedNotes = [];
    for (final n in notesList) { try { parsedNotes.add(jsonDecode(n) as Map<String, dynamic>); } catch (_) {} }
    Map<String, Map<String, dynamic>> progress = {};
    for (final bid in bookmarks) {
      final p = prefs.getString('reading_progress_$bid');
      if (p != null) { try { progress[bid] = jsonDecode(p) as Map<String, dynamic>; } catch (_) {} }
    }
    if (mounted) setState(() { _bookmarks = bookmarks; _readingHistory = parsedHistory; _notes = parsedNotes; _readingProgress = progress; });
  }

  List<Religion> get _filteredReligions => _searchQuery.isEmpty ? _religions : _religions.where((r) => r.name.contains(_searchQuery)).toList();
  List<ReligiousHoliday> get _filteredHolidays => _searchQuery.isEmpty ? [] : religiousHolidays.where((h) => h.name.contains(_searchQuery) || h.religion.contains(_searchQuery)).toList();
  List<ReligiousHoliday> _getHolidaysForDate(int day) => religiousHolidays.where((h) => h.month == _currentDate.month && h.day == day).toList();
  List<ReligiousHoliday> get _monthHolidays => religiousHolidays.where((h) => h.month == _currentDate.month).toList();
  bool _isToday(int day) { final now = DateTime.now(); return day == now.day && _currentDate.month == now.month && _currentDate.year == now.year; }
""")

# Part 5 - Group utilities
parts.append(r"""
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group, allGroups: _groups, allBooks: _books, chaptersMap: _chaptersMap)));
  }
""")

# Part 6 - Build method and header
parts.append(r"""
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(children: [
        _buildHeader(),
        Expanded(child: Stack(children: [
          TabBarView(controller: _tabController, children: [_buildEncyclopediaTab(), _buildLibraryTab(), _buildCalendarTab()]),
          Positioned(left: 0, right: 0, bottom: 16, child: Center(child: _buildContributionFloatingButton())),
        ])),
      ])),
    );
  }

  Widget _buildHeader() {
    String hint = ['搜索宗教...', '搜索经典...', '搜索节日...'][_tabController.index];
    return Container(
      decoration: const BoxDecoration(color: AppColors.background, border: Border(bottom: BorderSide(color: Color(0x14FFFFFF), width: 0.5))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(height: 40, decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(30)),
            child: Row(children: [const SizedBox(width: 12), const Icon(Icons.search, color: Color(0xFF8B949E), size: 18), const SizedBox(width: 8),
              Expanded(child: TextField(controller: _searchController, style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFF8B949E), fontSize: 14), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
                onChanged: (v) => setState(() => _searchQuery = v))),
              if (_searchQuery.isNotEmpty) IconButton(icon: const Icon(Icons.close, color: Color(0xFF8B949E), size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 12)]))),
        Container(margin: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(controller: _tabController, indicator: const BoxDecoration(), indicatorSize: TabBarIndicatorSize.label, labelPadding: EdgeInsets.zero, tabAlignment: TabAlignment.fill,
            tabs: [_buildTab('百科', Icons.menu_book, 0), _buildTab('藏书', Icons.library_books, 1), _buildTab('日历', Icons.calendar_today, 2)])),
        const SizedBox(height: 8),
      ]));
  }

  Widget _buildTab(String label, IconData icon, int index) {
    return Tab(child: Builder(builder: (context) {
      final active = _tabController.index == index;
      if (active) {
        return Container(padding: const EdgeInsets.all(1), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: _rainbowGradient),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), color: AppColors.background),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])));
      }
      return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: const Color(0xFF8B949E)), const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13, fontWeight: FontWeight.w500))]));
    }));
  }
""")

# Part 7 - Encyclopedia tab
parts.append(r"""
  Widget _buildEncyclopediaTab() {
    if (_searchQuery.isNotEmpty) return _buildSearchResults();
    if (_religions.isEmpty && !_loading) return const Center(child: Text('暂无数据', style: TextStyle(color: Color(0xFF8B949E))));
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF8B949E)));
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('宗教', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6),
        itemCount: _filteredReligions.length,
        itemBuilder: (c, i) {
          final r = _filteredReligions[i];
          return GestureDetector(onTap: () {
            final holidays = religiousHolidays.where((h) => h.religion == r.name).toList();
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReligionDetailScreen(religionId: r.id, religionName: r.name, followersScale: r.followersScale, type: r.type, introduction: r.introduction, holidays: holidays)));
          }, child: Container(decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x1AFFFFFF), width: 1)),
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _rainbowGradient)), const SizedBox(width: 8),
                Expanded(child: Text(r.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis))]),
              const SizedBox(height: 6),
              Expanded(child: Text(r.followersScale, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis)),
            ])));
        }),
    ]));
  }

  Widget _buildSearchResults() {
    final holidays = _filteredHolidays;
    if (holidays.isEmpty) return const Center(child: Text('未找到相关节日', style: TextStyle(color: Color(0xFF8B949E))));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: holidays.length, itemBuilder: (c, i) => _buildHolidayListItem(holidays[i]));
  }
""")

# Part 8 - Library tab
parts.append(r"""
  Widget _buildLibraryTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF8B949E)));
    return Column(children: [
      Container(margin: const EdgeInsets.symmetric(horizontal: 16), child: TabBar(controller: _libraryTabController, indicator: const BoxDecoration(), indicatorSize: TabBarIndicatorSize.label, labelPadding: EdgeInsets.zero, tabAlignment: TabAlignment.fill,
        tabs: [_buildLibSubTab('经典藏书', Icons.library_books, 0), _buildLibSubTab('我的书架', Icons.bookmark, 1), _buildLibSubTab('我的感悟', Icons.edit_note, 2), _buildLibSubTab('阅读历史', Icons.history, 3)])),
      const SizedBox(height: 8),
      Expanded(child: TabBarView(controller: _libraryTabController, children: [_buildClassicsSubTab(), _buildShelfSubTab(), _buildNotesSubTab(), _buildHistorySubTab()])),
    ]);
  }

  Widget _buildLibSubTab(String label, IconData icon, int index) {
    return Tab(child: Builder(builder: (context) {
      final active = _libraryTabController.index == index;
      if (active) {
        return Container(padding: const EdgeInsets.all(1), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: _rainbowGradient),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: const Color(0xFF050816).withOpacity(0.92)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: Colors.white), const SizedBox(width: 4),
              Text(label, style: const TextStyle(color: Color(0xF2FFFFFF), fontSize: 12, fontWeight: FontWeight.w500))])));
      }
      return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x0DFFFFFF)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: const Color(0xFF8B949E)), const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12, fontWeight: FontWeight.w500))]));
    }));
  }

  Widget _buildClassicsSubTab() {
    final topLevel = _getTopLevelGroups(); final ungrouped = _getUngroupedBooks();
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...topLevel.map((g) {
        final children = _getChildGroups(g.id); final books = _getGroupBooks(g.id); final hasChildren = children.isNotEmpty || books.isNotEmpty;
        return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
          child: ListTile(leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.library_books, color: Color(0xB3FFFFFF), size: 24)),
            title: Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            subtitle: Text([if (children.isNotEmpty) '${children.length} 子分类', if (children.isNotEmpty && books.isNotEmpty) ' \u00b7 ', if (books.isNotEmpty) '${books.length} 册'].join(), style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
            trailing: hasChildren ? const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20) : null, onTap: hasChildren ? () => _navigateIntoGroup(g) : null));
      }),
      if (ungrouped.isNotEmpty) ...[const SizedBox(height: 8), const Text('其他经典', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 12), ...ungrouped.map((b) => _buildBookCard(b))],
      if (topLevel.isEmpty && _books.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('暂无经典', style: TextStyle(color: Color(0xFF8B949E))))),
    ]));
  }

  Widget _buildShelfSubTab() {
    if (_bookmarks.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bookmark_border, color: Color(0x4DFFFFFF), size: 48), SizedBox(height: 12), Text('书架为空', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 14)), SizedBox(height: 4), Text('从藏书库添加', style: TextStyle(color: Color(0x4DFFFFFF), fontSize: 12))]));
    final bBooks = _books.where((b) => _bookmarks.contains(b.id)).toList();
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('我的书架 (${bBooks.length})', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 12),
      ...bBooks.map((book) {
        final progress = _readingProgress[book.id]; final totalCh = _chaptersMap[book.id] ?? 0;
        int curIdx = 0; String chTitle = '';
        if (progress != null) { curIdx = (progress['chapterIndex'] as num?)?.toInt() ?? 0; chTitle = progress['chapterTitle']?.toString() ?? ''; }
        final pct = totalCh > 0 ? (curIdx + 1) / totalCh : 0.0;
        return GestureDetector(onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id, bookTitle: book.title, bookReligion: book.religion, bookCategory: book.category, bookDescription: book.description))); },
          child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.menu_book, color: Colors.white, size: 22)),
                const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(book.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)), const SizedBox(height: 2), Text('${book.religion} \u00b7 ${book.category}', style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12))])),
                const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20)]),
              if (totalCh > 0) ...[const SizedBox(height: 10), Row(children: [Expanded(child: _buildProgressBar(pct)), const SizedBox(width: 8), Text('${(pct * 100).toInt()}%', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 11))]),
                if (chTitle.isNotEmpty) ...[const SizedBox(height: 4), Text('阅读中: $chTitle', style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 11))]],
            ])));
      }),
    ]));
  }

  Widget _buildProgressBar(double value) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(2)),
        child: Align(alignment: Alignment.centerLeft, child: Container(width: constraints.maxWidth * value.clamp(0.0, 1.0), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3A86FF), Color(0xFF00E5FF)]), borderRadius: BorderRadius.circular(2)))));
    });
  }

  Widget _buildNotesSubTab() {
    if (_notes.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit_note, color: Color(0x4DFFFFFF), size: 48), SizedBox(height: 12), Text('暂无笔记', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 14))]));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _notes.length, itemBuilder: (c, i) {
      final note = _notes[i];
      return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(note['bookTitle']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          if (note['chapterTitle'] != null) ...[const SizedBox(height: 4), Text(note['chapterTitle'].toString(), style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12))],
          const SizedBox(height: 8), Text(note['content']?.toString() ?? '', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.5))]));
    });
  }
""")

# Part 9 - History tab with clear button
parts.append(r"""
  Widget _buildHistorySubTab() {
    if (_readingHistory.isEmpty) return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.history, color: Color(0x4DFFFFFF), size: 48), SizedBox(height: 12), Text('暂无阅读记录', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 14))]));
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        GestureDetector(onTap: _clearHistory, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x0DFFFFFF)),
          child: ShaderMask(shaderCallback: (b) => _rainbowGradient.createShader(b), child: const Text('清空记录', style: TextStyle(color: Colors.white, fontSize: 13))))),
      ])),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _readingHistory.length, itemBuilder: (c, i) {
        final rec = _readingHistory[i]; final bTitle = rec['bookTitle']?.toString() ?? ''; final cTitle = rec['chapterTitle']?.toString() ?? ''; final ts = rec['timestamp']?.toString() ?? '';
        return GestureDetector(onTap: () {
          final bid = rec['bookId']?.toString() ?? ''; final book = _books.where((b) => b.id == bid).firstOrNull;
          if (book != null) Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id, bookTitle: book.title, bookReligion: book.religion, bookCategory: book.category, bookDescription: book.description)));
        }, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
          child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.menu_book, color: Color(0xB3FFFFFF), size: 20)),
            const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(bTitle, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Text('阅读中: $cTitle', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12)), if (ts.isNotEmpty) Text(_formatTs(ts), style: const TextStyle(color: Color(0x4DFFFFFF), fontSize: 11))])),
            const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20)])));
      })),
    ]);
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF0D1117),
      title: const Text('确认清空', style: TextStyle(color: Colors.white)),
      content: const Text('确定要清空所有阅读记录吗？', style: TextStyle(color: Color(0xB3FFFFFF))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Color(0xFF8B949E)))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清空', style: TextStyle(color: Color(0xFFFF4D6D))))]));
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('reading_history');
      if (mounted) setState(() => _readingHistory = []);
    }
  }

  String _formatTs(String iso) {
    try { final dt = DateTime.parse(iso); final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return '刚刚'; if (diff.inHours < 1) return '${diff.inMinutes}分钟前'; if (diff.inDays < 1) return '${diff.inHours}小时前'; if (diff.inDays < 7) return '${diff.inDays}天前'; return '${dt.month}/${dt.day}';
    } catch (_) { return ''; }
  }

  Widget _buildBookCard(BookItem book) {
    return GestureDetector(onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id, bookTitle: book.title, bookReligion: book.religion, bookCategory: book.category, bookDescription: book.description))); },
      child: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
        child: ListTile(leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.menu_book, color: Colors.white, size: 24)),
          title: Text(book.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          subtitle: Text([book.category.isNotEmpty ? book.category : book.religion, if (_chaptersMap.containsKey(book.id)) ' \u00b7 ${_chaptersMap[book.id]} 章'].join(), style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20))));
  }
""")

# Part 10 - Calendar tab
parts.append(r"""
  Widget _buildCalendarTab() {
    if (_searchQuery.isNotEmpty) return _buildSearchResults();
    final year = _currentDate.year; final month = _currentDate.month; final firstDay = DateTime(year, month, 1).weekday % 7; final daysInMonth = DateTime(year, month + 1, 0).day;
    const wk = ['日','一','二','三','四','五','六']; const mn = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'];
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(decoration: BoxDecoration(color: const Color(0x08FFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x14FFFFFF))), child: Column(children: [
        Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x14FFFFFF)))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 20), onPressed: () => setState(() { _currentDate = DateTime(year, month - 1, 1); _selectedDate = null; }), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 16), GestureDetector(onTap: _showYearPicker, child: Row(mainAxisSize: MainAxisSize.min, children: [Text('$year', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20)])),
          const SizedBox(width: 16), GestureDetector(onTap: _showMonthPicker, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(mn[month-1], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20)])),
          const SizedBox(width: 16), IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 20), onPressed: () => setState(() { _currentDate = DateTime(year, month + 1, 1); _selectedDate = null; }), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ])),
        Padding(padding: const EdgeInsets.all(8), child: Row(children: wk.map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12, fontWeight: FontWeight.w500))))).toList())),
        Padding(padding: const EdgeInsets.all(8), child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7), itemCount: firstDay + daysInMonth,
          itemBuilder: (c, index) { if (index < firstDay) return const SizedBox.shrink(); final day = index - firstDay + 1; final holidays = _getHolidaysForDate(day); final hasH = holidays.isNotEmpty; final isT = _isToday(day); final isSel = _selectedDate != null && _selectedDate!.day == day && _selectedDate!.month == month;
            return GestureDetector(onTap: () => setState(() => _selectedDate = DateTime(year, month, day)), child: Container(margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: isT ? null : isSel ? const Color(0x0FFFFFFF) : hasH ? const Color(0x0AFFFFFF) : null, borderRadius: BorderRadius.circular(8), border: isT ? null : isSel ? Border.all(color: const Color(0x26FFFFFF)) : hasH ? Border.all(color: const Color(0x0FFFFFFF)) : null, gradient: isT ? _rainbowGradient : null),
              child: isT ? Container(margin: const EdgeInsets.all(1), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(7)), child: Center(child: Text('$day', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))))
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('$day', style: TextStyle(color: isSel || hasH ? Colors.white : const Color(0xB3FFFFFF), fontSize: 13, fontWeight: FontWeight.w500)), if (hasH) Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(holidays.length > 3 ? 3 : holidays.length, (_) => Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _rainbowGradient))))])));
          })),
      ])),
      const SizedBox(height: 16),
      if (_selectedDate != null) _buildSelectedDateHolidays(),
      const SizedBox(height: 8), const Text('本月节日', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)), const SizedBox(height: 12),
      if (_monthHolidays.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('本月暂无宗教节日', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 13)))) else ..._monthHolidays.map((h) => _buildHolidayListItem(h)),
    ]));
  }

  Widget _buildSelectedDateHolidays() {
    final holidays = _getHolidaysForDate(_selectedDate!.day);
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0x08FFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x14FFFFFF))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_selectedDate!.month}月${_selectedDate!.day}日', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)), const SizedBox(height: 8),
        if (holidays.isEmpty) const Text('今日无宗教节日', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 13)) else ...holidays.map((h) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A), Color(0xFF70E000), Color(0xFF00E5FF)]))), const SizedBox(width: 8), Text(h.name, style: const TextStyle(color: Colors.white, fontSize: 13)), const SizedBox(width: 6), Text('(${h.religion})', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12))]))),
      ]));
  }

  Widget _buildHolidayListItem(ReligiousHoliday holiday) {
    return GestureDetector(onTap: () => _showHolidayDetail(holiday), child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x14FFFFFF))),
      child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(8)), child: Center(child: ShaderMask(shaderCallback: (b) => _rainbowGradient.createShader(b), child: Text('${holiday.day}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))))), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(holiday.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)), Text(holiday.religion, style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12))])),
        const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20)])));
  }

  void _showHolidayDetail(ReligiousHoliday holiday) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) => Container(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(color: Color(0xFF0D1117), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(holiday.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.close, color: Color(0x80FFFFFF), size: 20), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints())]),
          const SizedBox(height: 12),
          Row(children: [const Text('日期: ', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13)), Text('${holiday.month}月${holiday.day}日', style: const TextStyle(color: Colors.white, fontSize: 13))]),
          const SizedBox(height: 8),
          Row(children: [const Text('宗教: ', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13)), Text(holiday.religion, style: const TextStyle(color: Colors.white, fontSize: 13))]),
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x0FFFFFFF))), child: Text(holiday.desc, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5))),
          if (holiday.detail.isNotEmpty) ...[const SizedBox(height: 12), Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0x08FFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x0DFFFFFF))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('详细介绍', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 8), Text(holiday.detail, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.5))]))],
          if (holiday.yi.isNotEmpty || holiday.ji.isNotEmpty) ...[const SizedBox(height: 12), Row(children: [
            if (holiday.yi.isNotEmpty) Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0x0F70E000), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x2670E000))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('宜', style: TextStyle(color: Color(0xCC70E000), fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(holiday.yi, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.4))]))),
            if (holiday.yi.isNotEmpty && holiday.ji.isNotEmpty) const SizedBox(width: 8),
            if (holiday.ji.isNotEmpty) Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0x0FFF4D6D), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x26FF4D6D))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('忌', style: TextStyle(color: Color(0xCCFF4D6D), fontSize: 12, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(holiday.ji, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.4))]))),
          ])],
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 16),
        ])))));
  }

  void _showYearPicker() {
    final cy = _currentDate.year; final years = List.generate(21, (i) => cy - 10 + i);
    showDialog(context: context, builder: (ctx) => Dialog(backgroundColor: const Color(0xFF0D1117), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(width: 200, padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('选择年份', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
        SizedBox(height: 240, child: ListView.builder(itemCount: years.length, itemBuilder: (c, i) { final y = years[i]; final sel = y == cy;
          return GestureDetector(onTap: () { setState(() { _currentDate = DateTime(y, _currentDate.month, 1); _selectedDate = null; }); Navigator.pop(ctx); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: sel ? const Color(0x14FFFFFF) : null, borderRadius: BorderRadius.circular(8)), child: Center(child: Text('$y', style: TextStyle(color: sel ? Colors.white : const Color(0x99FFFFFF), fontSize: 14)))));
        })),
      ]))));
  }

  void _showMonthPicker() {
    const mn = ['1月','2月','3月','4月','5月','6月','7月','8月','9月','10月','11月','12月'];
    showDialog(context: context, builder: (ctx) => Dialog(backgroundColor: const Color(0xFF0D1117), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(width: 200, padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('选择月份', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
        SizedBox(height: 320, child: ListView.builder(itemCount: 12, itemBuilder: (c, i) { final sel = i == _currentDate.month - 1;
          return GestureDetector(onTap: () { setState(() { _currentDate = DateTime(_currentDate.year, i + 1, 1); _selectedDate = null; }); Navigator.pop(ctx); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: sel ? const Color(0x14FFFFFF) : null, borderRadius: BorderRadius.circular(8)), child: Center(child: Text(mn[i], style: TextStyle(color: sel ? Colors.white : const Color(0x99FFFFFF), fontSize: 14)))));
        })),
      ]))));
  }
""")

# Part 11 - Contribution dialog
parts.append(r"""
  Widget _buildContributionFloatingButton() {
    return GestureDetector(onTap: _showContributionDialog,
      child: Container(padding: const EdgeInsets.all(1), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: _rainbowGradient),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(19), color: AppColors.background),
          child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.forum, size: 14, color: Colors.white), const SizedBox(width: 6),
            const Text('参与共建', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))]))));
  }

  void _showContributionDialog() {
    _contributionType = '';
    _contributionSourceController.clear();
    _contributionContentController.clear();
    final types = _contributionTypes;
    final sourceHint = _tabController.index == 2 ? '如：圣诞节 / 12月25日' : '如：创世记 第1章';
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Container(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(20)), border: Border(top: BorderSide(color: Color(0x1AFFFFFF)))),
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('参与共建', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close, color: Color(0x80FFFFFF), size: 22))]),
            const SizedBox(height: 8),
            const Text('你的每一条建议，都在帮助这份信仰内容变得更准确、更完整。', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12)),
            const SizedBox(height: 20),
            const Text('建议类型 *', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: types.map((type) {
              final isSelected = _contributionType == type;
              return GestureDetector(onTap: () => setModalState(() { _contributionType = type; }),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(color: isSelected ? const Color(0x1FFFFFFF) : const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? const Color(0x4DFFFFFF) : const Color(0x14FFFFFF))),
                  child: Text(type, style: TextStyle(color: isSelected ? Colors.white : const Color(0x80FFFFFF), fontSize: 12))));
            }).toList()),
            const SizedBox(height: 20),
            const Text('来源（选填，如书名/章节）', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
            const SizedBox(height: 8),
            Container(decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))),
              child: TextField(controller: _contributionSourceController, style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(hintText: sourceHint, hintStyle: const TextStyle(color: Color(0x4DFFFFFF), fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), isDense: true))),
            const SizedBox(height: 16),
            const Text('详细内容 *', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
            const SizedBox(height: 8),
            Container(decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x1AFFFFFF))),
              child: TextField(controller: _contributionContentController, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 4,
                decoration: const InputDecoration(hintText: '请描述你的建议...', hintStyle: TextStyle(color: Color(0x4DFFFFFF), fontSize: 14), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), isDense: true))),
            const SizedBox(height: 20),
            GestureDetector(onTap: _contributionSubmitting ? null : () => _submitContribution(ctx, setModalState),
              child: Opacity(opacity: _contributionSubmitting ? 0.6 : 1.0,
                child: Container(width: double.infinity, padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: _contributionSubmitting ? const LinearGradient(colors: [Color(0x1AFFFFFF), Color(0x1AFFFFFF)]) : _rainbowGradient),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: AppColors.background),
                    child: Center(child: _contributionSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0x80FFFFFF))) : const Text('提交建议', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))))))),
          ])),
        );
      }));
  }

  Future<void> _submitContribution(BuildContext dialogContext, void Function(void Function()) setModalState) async {
    if (_contributionType.isEmpty || _contributionContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择类型并填写内容'), backgroundColor: Color(0xFFEF4444)));
      return;
    }
    setModalState(() { _contributionSubmitting = true; });
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id ?? 'anonymous';
      final source = _contributionSourceController.text.trim();
      final content = _contributionContentController.text.trim();
      final description = source.isNotEmpty ? '[$source] $content' : content;
      await client.from('support_tickets').insert({'user_id': userId, 'subject': _contributionType, 'description': description, 'status': 'open', 'priority': 'normal'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('提交成功，感谢你的共建贡献！'), backgroundColor: Color(0xFF4CAF50)));
        Navigator.pop(dialogContext);
      }
    } catch (e) {
      debugPrint('submitContribution error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('提交失败，请检查网络'), backgroundColor: Color(0xFFEF4444)));
    } finally {
      if (mounted) setModalState(() { _contributionSubmitting = false; });
    }
  }
}
""")

# Part 12 - GroupDetailScreen
parts.append(r"""
class GroupDetailScreen extends StatelessWidget {
  final BookGroup group; final List<BookGroup> allGroups; final List<BookItem> allBooks; final Map<String, int> chaptersMap;
  const GroupDetailScreen({super.key, required this.group, required this.allGroups, required this.allBooks, required this.chaptersMap});
  @override
  Widget build(BuildContext context) {
    final childGroups = allGroups.where((g) => group.groupIds.contains(g.id) && g.isPublished).toList(); final bookIds = group.bookIds.toSet(); final groupBooks = allBooks.where((b) => bookIds.contains(b.id) || b.groupId == group.id).toList();
    return Scaffold(backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)), title: Text(group.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...childGroups.map((sg) { final sc = allGroups.where((g) => sg.groupIds.contains(g.id) && g.isPublished).toList(); final sb = allBooks.where((b) => sg.bookIds.contains(b.id) || b.groupId == sg.id).toList();
          return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
            child: ListTile(leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.folder, color: Color(0xB3FFFFFF), size: 24)),
              title: Text(sg.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              subtitle: Text([if (sc.isNotEmpty) '${sc.length} 子分类', if (sc.isNotEmpty && sb.isNotEmpty) ' \u00b7 ', if (sb.isNotEmpty) '${sb.length} 册'].join(), style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(group: sg, allGroups: allGroups, allBooks: allBooks, chaptersMap: chaptersMap)))));
        }),
        if (groupBooks.isNotEmpty) ...[if (childGroups.isNotEmpty) ...[const SizedBox(height: 8), const Text('书籍', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 12)],
          ...groupBooks.map((b) => GestureDetector(onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: b.id, bookTitle: b.title, bookReligion: b.religion, bookCategory: b.category, bookDescription: b.description))); },
            child: Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
              child: ListTile(leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.menu_book, color: Colors.white, size: 24)),
                title: Text(b.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                subtitle: Text([b.category.isNotEmpty ? b.category : b.religion, if (chaptersMap.containsKey(b.id)) ' \u00b7 ${chaptersMap[b.id]} 章'].join(), style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20)))))
        ],
        if (childGroups.isEmpty && groupBooks.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('暂无内容', style: TextStyle(color: Color(0xFF8B949E))))),
      ])),
    );
  }
}
""")

# Write all parts
content = ''.join(parts)
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Written {len(content)} chars to {path}")
print(f"File size: {os.path.getsize(path)} bytes")
