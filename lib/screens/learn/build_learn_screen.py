# -*- coding: utf-8 -*-
"""Generate the complete learn_screen.dart file"""
import os

target = r"C:\OpenFaith-Flutter\lib\screens\learn\learn_screen.dart"

content = r'''import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/colors.dart';
import 'book_detail_screen.dart';
import 'religion_detail_screen.dart';
import 'holidays_data.dart';

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
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client.from('religions').select().eq('is_active', true).order('sort_order').order('name'),
        client.from('book_groups').select().order('created_at'),
        client.from('books').select().order('sort_order').order('title'),
        client.from('chapters').select('book_id').limit(1000),
      ]);
      if (results[0].isNotEmpty) _religions = (results[0] as List).map((e) => Religion.fromMap(e as Map<String, dynamic>)).toList();
      if (results[1].isNotEmpty) _groups = (results[1] as List).map((e) => BookGroup.fromMap(e as Map<String, dynamic>)).toList();
      if (results[2].isNotEmpty) _books = (results[2] as List).map((e) => BookItem.fromMap(e as Map<String, dynamic>)).toList();
      if (results[3].isNotEmpty) {
        final chapters = results[3] as List;
        _chaptersMap = {};
        for (final ch in chapters) {
          final bookId = (ch as Map<String, dynamic>)['book_id']?.toString();
          if (bookId != null) _chaptersMap[bookId] = (_chaptersMap[bookId] ?? 0) + 1;
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
      body: SafeArea(
        child: Column(
          children: [_buildHeader(), Expanded(child: TabBarView(controller: _tabController, children: [_buildEncyclopediaTab(), _buildLibraryTab(), _buildCalendarTab()]))],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String hint = ['Search religions...', 'Search books...', 'Search holidays...'][_tabController.index];
    return Container(
      color: AppColors.background,
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(height: 40, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const SizedBox(width: 12), const Icon(Icons.search, color: Color(0xFF8B949E), size: 18), const SizedBox(width: 8),
              Expanded(child: TextField(controller: _searchController, style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFF8B949E), fontSize: 14), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
                onChanged: (v) => setState(() => _searchQuery = v))),
              if (_searchQuery.isNotEmpty) IconButton(icon: const Icon(Icons.close, color: Color(0xFF8B949E), size: 18), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 12),
            ]))),
        Container(margin: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(controller: _tabController, indicator: const BoxDecoration(), indicatorSize: TabBarIndicatorSize.label, labelPadding: EdgeInsets.zero, tabAlignment: TabAlignment.fill,
            tabs: [_buildTab('Religions', Icons.menu_book, 0), _buildTab('Library', Icons.library_books, 1), _buildTab('Calendar', Icons.calendar_today, 2)])),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildTab(String label, IconData icon, int index) {
    return Tab(child: Builder(builder: (context) {
      final active = _tabController.index == index;
      return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: active ? _rainbowGradient : null),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: active ? AppColors.background : Colors.transparent),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: active ? Colors.white : const Color(0xFF8B949E)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: active ? Colors.white : const Color(0xFF8B949E), fontSize: 13, fontWeight: FontWeight.w500)),
          ])));
    }));
  }

  // ====== Encyclopedia Tab ======
  Widget _buildEncyclopediaTab() {
    if (_searchQuery.isNotEmpty) return _buildSearchResults();
    if (_religions.isEmpty && !_loading) return const Center(child: Text('No data', style: TextStyle(color: Color(0xFF8B949E))));
    return SingleChildScrollView(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Religions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6),
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
              child: Container(decoration: BoxDecoration(color: const Color(0x0DFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5)),
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _rainbowGradient)),
                    const SizedBox(width: 8), Expanded(child: Text(r.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis))]),
                  const SizedBox(height: 6),
                  Expanded(child: Text(r.followersScale, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis)),
                ])));
          }),
      ]));
  }

  Widget _buildSearchResults() {
    final holidays = _filteredHolidays;
    if (holidays.isEmpty) return const Center(child: Text('No results', style: TextStyle(color: Color(0xFF8B949E))));
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: holidays.length,
      itemBuilder: (c, i) => _buildHolidayListItem(holidays[i]));
  }

  // ====== Library Tab (with sub-tabs) ======
  Widget _buildLibraryTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF8B949E)));
    return Column(children: [
      Container(margin: const EdgeInsets.symmetric(horizontal: 16),
        child: TabBar(controller: _libraryTabController, indicator: const BoxDecoration(), indicatorSize: TabBarIndicatorSize.label, labelPadding: EdgeInsets.zero, tabAlignment: TabAlignment.fill,
          tabs: [
            _buildLibSubTab('Books', Icons.library_books, 0),
            _buildLibSubTab('Shelf', Icons.bookmark, 1),
            _buildLibSubTab('Notes', Icons.edit_note, 2),
            _buildLibSubTab('History', Icons.history, 3),
          ])),
      const SizedBox(height: 8),
      Expanded(child: TabBarView(controller: _libraryTabController, children: [_buildClassicsSubTab(), _buildShelfSubTab(), _buildNotesSubTab(), _buildHistorySubTab()])),
    ]);
  }

  Widget _buildLibSubTab(String label, IconData icon, int index) {
    return Tab(child: Builder(builder: (context) {
      final active = _libraryTabController.index == index;
      return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: active ? const Color(0x14FFFFFF) : Colors.transparent),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: active ? Colors.white : const Color(0xFF8B949E)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: active ? Colors.white : const Color(0xFF8B949E), fontSize: 12, fontWeight: FontWeight.w500)),
        ]));
    }));
  }

  Widget _buildClassicsSubTab() {
    final topLevel = _getTopLevelGroups();
    final ungrouped = _getUngroupedBooks();
    return SingleChildScrollView(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...topLevel.map((g) {
          final children = _getChildGroups(g.id);
          final books = _getGroupBooks(g.id);
          final hasChildren = children.isNotEmpty || books.isNotEmpty;
          return Container(margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
            child: ListTile(
              leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.library_books, color: Color(0xB3FFFFFF), size: 24)),
              title: Text(g.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              subtitle: Text([if (children.isNotEmpty) '${children.length} sub', if (children.isNotEmpty && books.isNotEmpty) ' \u00b7 ', if (books.isNotEmpty) '${books.length} vol'].join(),
                style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
              trailing: hasChildren ? const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20) : null,
              onTap: hasChildren ? () => _navigateIntoGroup(g) : null));
        }),
        if (ungrouped.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Other Classics', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...ungrouped.map((b) => _buildBookCard(b)),
        ],
        if (topLevel.isEmpty && _books.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No books', style: TextStyle(color: Color(0xFF8B949E))))),
      ]));
  }

  Widget _buildShelfSubTab() {
    if (_bookmarks.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.bookmark_border, color: Color(0x4DFFFFFF), size: 48),
        SizedBox(height: 12),
        Text('Shelf is empty', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 14)),
        SizedBox(height: 4),
        Text('Add books from Library', style: TextStyle(color: Color(0x4DFFFFFF), fontSize: 12)),
      ]));
    }
    final bookmarkedBooks = _books.where((b) => _bookmarks.contains(b.id)).toList();
    return SingleChildScrollView(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('My Shelf (${bookmarkedBooks.length})', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...bookmarkedBooks.map((book) {
          final progress = _readingProgress[book.id];
          final totalCh = _chaptersMap[book.id] ?? 0;
          int curIdx = 0;
          String chTitle = '';
          if (progress != null) { curIdx = (progress['chapterIndex'] as num?)?.toInt() ?? 0; chTitle = progress['chapterTitle']?.toString() ?? ''; }
          final pct = totalCh > 0 ? (curIdx + 1) / totalCh : 0.0;
          return GestureDetector(
            onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id, bookTitle: book.title, bookReligion: book.religion, bookCategory: book.category, bookDescription: book.description))); },
            child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.menu_book, color: Colors.white, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(book.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text('${book.religion} \u00b7 ${book.category}', style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
                  ])),
                  const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20),
                ]),
                if (totalCh > 0) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _buildProgressBar(pct)),
                    const SizedBox(width: 8),
                    Text('${(pct * 100).toInt()}%', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 11)),
                  ]),
                  if (chTitle.isNotEmpty) ...[const SizedBox(height: 4), Text('Reading: $chTitle', style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 11))],
                ],
              ])));
        }),
      ]));
  }

  Widget _buildProgressBar(double value) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(height: 4, decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(2)),
        child: Align(alignment: Alignment.centerLeft,
          child: Container(width: constraints.maxWidth * value.clamp(0.0, 1.0),
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF3A86FF), Color(0xFF00E5FF)]), borderRadius: BorderRadius.circular(2)))));
    });
  }

  Widget _buildNotesSubTab() {
    if (_notes.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.edit_note, color: Color(0x4DFFFFFF), size: 48),
        SizedBox(height: 12),
        Text('No notes yet', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 14)),
      ]));
    }
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _notes.length,
      itemBuilder: (c, i) {
        final note = _notes[i];
        return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(note['bookTitle']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            if (note['chapterTitle'] != null) ...[const SizedBox(height: 4), Text(note['chapterTitle'].toString(), style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12))],
            const SizedBox(height: 8),
            Text(note['content']?.toString() ?? '', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.5)),
          ]));
      });
  }

  Widget _buildHistorySubTab() {
    if (_readingHistory.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.history, color: Color(0x4DFFFFFF), size: 48),
        SizedBox(height: 12),
        Text('No reading history', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 14)),
      ]));
    }
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _readingHistory.length,
      itemBuilder: (c, i) {
        final rec = _readingHistory[i];
        final bTitle = rec['bookTitle']?.toString() ?? '';
        final cTitle = rec['chapterTitle']?.toString() ?? '';
        final ts = rec['timestamp']?.toString() ?? '';
        return GestureDetector(
          onTap: () {
            final bid = rec['bookId']?.toString() ?? '';
            final book = _books.where((b) => b.id == bid).firstOrNull;
            if (book != null) { Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id, bookTitle: book.title, bookReligion: book.religion, bookCategory: book.category, bookDescription: book.description))); }
          },
          child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.menu_book, color: Color(0xB3FFFFFF), size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(bTitle, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Reading: $cTitle', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
                if (ts.isNotEmpty) Text(_formatTs(ts), style: const TextStyle(color: Color(0x4DFFFFFF), fontSize: 11)),
              ])),
              const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20),
            ])));
      });
  }

  String _formatTs(String iso) {
    try { final dt = DateTime.parse(iso); final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now'; if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago'; if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.month}/${dt.day}';
    } catch (_) { return ''; }
  }

  List<BookGroup> _getTopLevelGroups() {
    final childIds = <String>{};
    for (final g in _groups) { if (g.groupIds.isNotEmpty) childIds.addAll(g.groupIds); }
    return _groups.where((g) => (g.groupIds.isNotEmpty && g.isPublished) || (!childIds.contains(g.id) && g.isPublished)).toList();
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

  Widget _buildBookCard(BookItem book) {
    return GestureDetector(
      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id, bookTitle: book.title, bookReligion: book.religion, bookCategory: book.category, bookDescription: book.description))); },
      child: Container(margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
        child: ListTile(
          leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.menu_book, color: Colors.white, size: 24)),
          title: Text(book.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          subtitle: Text([book.category.isNotEmpty ? book.category : book.religion, if (_chaptersMap.containsKey(book.id)) ' \u00b7 ${_chaptersMap[book.id]} ch'].join(),
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20))));
  }

  // ====== Calendar Tab ======
  Widget _buildCalendarTab() {
    if (_searchQuery.isNotEmpty) return _buildSearchResults();
    final year = _currentDate.year; final month = _currentDate.month;
    final firstDay = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    const wk = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return SingleChildScrollView(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(decoration: BoxDecoration(color: const Color(0x08FFFFFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x14FFFFFF))),
          child: Column(children: [
            Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x14FFFFFF)))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white70, size: 20), onPressed: () => setState(() { _currentDate = DateTime(year, month - 1, 1); _selectedDate = null; }), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                const SizedBox(width: 16),
                GestureDetector(onTap: _showYearPicker, child: Row(mainAxisSize: MainAxisSize.min, children: [Text('$year', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20)])),
                const SizedBox(width: 8),
                GestureDetector(onTap: _showMonthPicker, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(_monthName(month), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20)])),
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white70, size: 20), onPressed: () => setState(() { _currentDate = DateTime(year, month + 1, 1); _selectedDate = null; }), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ])),
            Padding(padding: const EdgeInsets.all(8), child: Row(children: wk.map((d) => Expanded(child: Center(child: Text(d, style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12, fontWeight: FontWeight.w500))))).toList())),
            Padding(padding: const EdgeInsets.all(8),
              child: GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                itemCount: firstDay + daysInMonth,
                itemBuilder: (c, index) {
                  if (index < firstDay) return const SizedBox.shrink();
                  final day = index - firstDay + 1;
                  final holidays = _getHolidaysForDate(day);
                  final hasHoliday = holidays.isNotEmpty;
                  final isToday = _isToday(day);
                  final isSelected = _selectedDate != null && _selectedDate!.day == day && _selectedDate!.month == month;
                  return GestureDetector(onTap: () => setState(() => _selectedDate = DateTime(year, month, day)),
                    child: Container(margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isToday ? null : isSelected ? const Color(0x0FFFFFFF) : hasHoliday ? const Color(0x0AFFFFFF) : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday ? null : isSelected ? Border.all(color: const Color(0x26FFFFFF)) : hasHoliday ? Border.all(color: const Color(0x0FFFFFFF)) : null,
                        gradient: isToday ? _rainbowGradient : null),
                      child: isToday
                        ? Container(margin: const EdgeInsets.all(1), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(7)),
                            child: Center(child: Text('$day', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('$day', style: TextStyle(color: isSelected || hasHoliday ? Colors.white : const Color(0xB3FFFFFF), fontSize: 13, fontWeight: FontWeight.w500)),
                            if (hasHoliday) Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(holidays.length > 3 ? 3 : holidays.length, (_) => Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _rainbowGradient)))),
                          ])));
                })),
          ])),
        const SizedBox(height: 16),
        if (_selectedDate != null) _buildSelectedDateHolidays(),
        const SizedBox(height: 8),
        const Text('This Month', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (_monthHolidays.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No holidays this month', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 13))))
        else ..._monthHolidays.map((h) => _buildHolidayListItem(h)),
      ]));
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];

  Widget _buildSelectedDateHolidays() {
    final holidays = _getHolidaysForDate(_selectedDate!.day);
    return Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0x08FFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x14FFFFFF))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_selectedDate!.month}/${_selectedDate!.day}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (holidays.isEmpty) const Text('No holidays today', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 13))
        else ...holidays.map((h) => Padding(padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A), Color(0xFF70E000), Color(0xFF00E5FF)]))),
            const SizedBox(width: 8), Text(h.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(width: 6), Text('(${h.religion})', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
          ]))),
      ]));
  }

  Widget _buildHolidayListItem(ReligiousHoliday holiday) {
    return GestureDetector(onTap: () => _showHolidayDetail(holiday),
      child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x14FFFFFF))),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(8)),
            child: Center(child: ShaderMask(shaderCallback: (b) => _rainbowGradient.createShader(b), child: Text('${holiday.day}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(holiday.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            Text(holiday.religion, style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20),
        ])));
  }

  void _showHolidayDetail(ReligiousHoliday holiday) {
    showDialog(context: context,
      builder: (ctx) => Dialog(backgroundColor: const Color(0xFF0D1117), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85), padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(holiday.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close, color: Color(0x80FFFFFF), size: 20), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ]),
            const SizedBox(height: 12),
            Row(children: [const Text('Date: ', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13)), Text('${holiday.month}/${holiday.day}', style: const TextStyle(color: Colors.white, fontSize: 13))]),
            const SizedBox(height: 8),
            Row(children: [const Text('Religion: ', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13)), Text(holiday.religion, style: const TextStyle(color: Colors.white, fontSize: 13))]),
            const SizedBox(height: 12),
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x0FFFFFFF))),
              child: Text(holiday.desc, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5))),
            if (holiday.detail.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0x08FFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x0DFFFFFF))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Detail', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text(holiday.detail, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.5)),
                ])),
            ],
            if (holiday.yi.isNotEmpty || holiday.ji.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: [
                if (holiday.yi.isNotEmpty) Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0x0F70E000), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x2670E000))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Yi', style: TextStyle(color: Color(0xCC70E000), fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(holiday.yi, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.4)),
                  ]))),
                if (holiday.yi.isNotEmpty && holiday.ji.isNotEmpty) const SizedBox(width: 8),
                if (holiday.ji.isNotEmpty) Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0x0FFF4D6D), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x26FF4D6D))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Ji', style: TextStyle(color: Color(0xCCFF4D6D), fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(holiday.ji, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.4)),
                  ]))),
              ]),
            ],
          ])))));
  }

  void _showYearPicker() {
    final cy = _currentDate.year;
    final years = List.generate(21, (i) => cy - 10 + i);
    showDialog(context: context,
      builder: (ctx) => Dialog(backgroundColor: const Color(0xFF0D1117), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(width: 200, padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Select Year', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 240, child: ListView.builder(itemCount: years.length,
              itemBuilder: (c, i) { final y = years[i]; final sel = y == cy;
                return GestureDetector(onTap: () { setState(() { _currentDate = DateTime(y, _currentDate.month, 1); _selectedDate = null; }); Navigator.pop(ctx); },
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: sel ? const Color(0x14FFFFFF) : null, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text('$y', style: TextStyle(color: sel ? Colors.white : const Color(0x99FFFFFF), fontSize: 14)))));
              })),
          ]))));
  }

  void _showMonthPicker() {
    const mn = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    showDialog(context: context,
      builder: (ctx) => Dialog(backgroundColor: const Color(0xFF0D1117), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(width: 200, padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Select Month', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 320, child: ListView.builder(itemCount: 12,
              itemBuilder: (c, i) { final sel = i == _currentDate.month - 1;
                return GestureDetector(onTap: () { setState(() { _currentDate = DateTime(_currentDate.year, i + 1, 1); _selectedDate = null; }); Navigator.pop(ctx); },
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: sel ? const Color(0x14FFFFFF) : null, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(mn[i], style: TextStyle(color: sel ? Colors.white : const Color(0x99FFFFFF), fontSize: 14)))));
              })),
          ]))));
  }
}

// ====== Group Detail Screen ======
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
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(group.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ...childGroups.map((sg) {
            final sc = allGroups.where((g) => sg.groupIds.contains(g.id) && g.isPublished).toList();
            final sb = allBooks.where((b) => sg.bookIds.contains(b.id) || b.groupId == sg.id).toList();
            return Container(margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
              child: ListTile(
                leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.folder, color: Color(0xB3FFFFFF), size: 24)),
                title: Text(sg.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                subtitle: Text([if (sc.isNotEmpty) '${sc.length} sub', if (sc.isNotEmpty && sb.isNotEmpty) ' \u00b7 ', if (sb.isNotEmpty) '${sb.length} vol'].join(), style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupDetailScreen(group: sg, allGroups: allGroups, allBooks: allBooks, chaptersMap: chaptersMap)))));
          }),
          if (groupBooks.isNotEmpty) ...[
            if (childGroups.isNotEmpty) ...[const SizedBox(height: 8), const Text('Books', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 12)],
            ...groupBooks.map((b) => GestureDetector(
              onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: b.id, bookTitle: b.title, bookReligion: b.religion, bookCategory: b.category, bookDescription: b.description))); },
              child: Container(margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1F2937))),
                child: ListTile(
                  leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.menu_book, color: Colors.white, size: 24)),
                  title: Text(b.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  subtitle: Text([b.category.isNotEmpty ? b.category : b.religion, if (chaptersMap.containsKey(b.id)) ' \u00b7 ${chaptersMap[b.id]} ch'].join(), style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20))))),
          ],
          if (childGroups.isEmpty && groupBooks.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No content', style: TextStyle(color: Color(0xFF8B949E))))),
        ])),
    );
  }
}
'''

with open(target, "w", encoding="utf-8") as f:
    f.write(content)

print(f"Written {len(content)} bytes to learn_screen.dart")
