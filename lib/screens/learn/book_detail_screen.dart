import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class Chapter {
  final String id;
  final String bookId;
  final int number;
  final String title;
  final String content;
  const Chapter({required this.id, required this.bookId, required this.number, required this.title, required this.content});
  factory Chapter.fromMap(Map<String, dynamic> m) => Chapter(
    id: m['id']?.toString() ?? '',
    bookId: m['book_id']?.toString() ?? '',
    number: (m['number'] as num?)?.toInt() ?? 0,
    title: m['title']?.toString() ?? '',
    content: m['content']?.toString() ?? '',
  );
}

enum ReaderTheme { dark, light, eyeProtect }

class BookDetailScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final String bookReligion;
  final String bookCategory;
  final String bookDescription;
  const BookDetailScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.bookReligion,
    required this.bookCategory,
    required this.bookDescription,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  List<Chapter> _chapters = [];
  bool _loading = true;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadChapters();
    _checkBookmark();
  }

  Future<void> _loadChapters() async {
    try {
      final data = await Supabase.instance.client
          .from('chapters')
          .select()
          .eq('book_id', widget.bookId)
          .order('number');
      if (data.isNotEmpty) {
        setState(() {
          _chapters = (data as List)
              .map((e) => Chapter.fromMap(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() { _loading = false; });
      }
    } catch (e) {
      debugPrint('loadChapters error: $e');
      setState(() { _loading = false; });
    }
  }

  Future<void> _checkBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarks') ?? [];
    setState(() => _isBookmarked = bookmarks.contains(widget.bookId));
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = prefs.getStringList('bookmarks') ?? [];
    if (_isBookmarked) {
      bookmarks.remove(widget.bookId);
    } else {
      bookmarks.add(widget.bookId);
    }
    await prefs.setStringList('bookmarks', bookmarks);
    setState(() => _isBookmarked = !_isBookmarked);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isBookmarked ? '已加入书架' : '已从书架移除'),
          backgroundColor: const Color(0xFF1A1F36),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.bookTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked ? const Color(0xFFFFD60A) : Colors.white70),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white70),
            onPressed: () => _showChapterList(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B949E)))
          : _chapters.isEmpty
              ? const Center(child: Text('暂无章节', style: TextStyle(color: Color(0xFF8B949E))))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookInfoCard(),
          const SizedBox(height: 20),
          _buildChapterListHeader(),
          const SizedBox(height: 12),
          ..._chapters.map((ch) => _buildChapterItem(ch)),
        ],
      ),
    );
  }

  Widget _buildBookInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4D6D), Color(0xFF9D4EDD)],
                    transform: GradientRotation(0.785398),
                  ),
                ),
                child: const Icon(Icons.menu_book, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.bookTitle,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${widget.bookReligion} \u00b7 ${widget.bookCategory}',
                        style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (widget.bookDescription.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(widget.bookDescription,
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.6)),
          ],
        ],
      ),
    );
  }

  Widget _buildChapterListHeader() {
    return Row(
      children: [
        const Text('章节目录', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${_chapters.length}', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 13)),
      ],
    );
  }

  Widget _buildChapterItem(Chapter chapter) {
    return GestureDetector(
      onTap: () => _openReader(chapter),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('${chapter.number}',
                    style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(chapter.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20),
          ],
        ),
      ),
    );
  }

  void _showChapterList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderColor)),
              ),
              child: Row(
                children: [
                  const Text('目录', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0x80FFFFFF), size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chapters.length,
                itemBuilder: (c, i) {
                  final ch = _chapters[i];
                  return ListTile(
                    title: Text(ch.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text('第${ch.number}章', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openReader(ch);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openReader(Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          bookId: widget.bookId,
          bookTitle: widget.bookTitle,
          chapters: _chapters,
          initialChapter: chapter,
        ),
      ),
    );
  }
}

// ====== Reader Screen ======
class ReaderScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final List<Chapter> chapters;
  final Chapter initialChapter;
  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.chapters,
    required this.initialChapter,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Chapter _currentChapter;
  late int _currentIndex;
  double _fontSize = 18;
  double _lineHeight = 1.8;
  ReaderTheme _theme = ReaderTheme.dark;
  final ScrollController _scrollController = ScrollController();

  static const Map<ReaderTheme, Color> _bgColors = {
    ReaderTheme.dark: Color(0xFF050816),
    ReaderTheme.light: Color(0xFFF5F5F5),
    ReaderTheme.eyeProtect: Color(0xFFC7EDCC),
  };

  static const Map<ReaderTheme, Color> _textColors = {
    ReaderTheme.dark: Colors.white,
    ReaderTheme.light: Color(0xFF333333),
    ReaderTheme.eyeProtect: Color(0xFF333333),
  };

  static const Map<ReaderTheme, String> _themeNames = {
    ReaderTheme.dark: '夜间',
    ReaderTheme.light: '日间',
    ReaderTheme.eyeProtect: '护眼',
  };

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.initialChapter;
    _currentIndex = widget.chapters.indexWhere((c) => c.id == widget.initialChapter.id);
    if (_currentIndex < 0) _currentIndex = 0;
    _loadSettings();
    _saveProgress();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('reader_font_size') ?? 18;
      _lineHeight = prefs.getDouble('reader_line_height') ?? 1.8;
      final themeStr = prefs.getString('reader_theme') ?? 'dark';
      _theme = ReaderTheme.values.firstWhere((t) => t.name == themeStr, orElse: () => ReaderTheme.dark);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_font_size', _fontSize);
    await prefs.setDouble('reader_line_height', _lineHeight);
    await prefs.setString('reader_theme', _theme.name);
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reading_progress_${widget.bookId}', jsonEncode({
      'chapterId': _currentChapter.id,
      'chapterIndex': _currentIndex,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    final history = prefs.getStringList('reading_history') ?? [];
    final entry = jsonEncode({
      'bookId': widget.bookId,
      'bookTitle': widget.bookTitle,
      'chapterId': _currentChapter.id,
      'chapterTitle': _currentChapter.title,
      'chapterIndex': _currentIndex,
      'timestamp': DateTime.now().toIso8601String(),
    });
    history.removeWhere((h) {
      try {
        final m = jsonDecode(h) as Map<String, dynamic>;
        return m['bookId'] == widget.bookId;
      } catch (_) { return false; }
    });
    history.insert(0, entry);
    if (history.length > 50) history.removeRange(50, history.length);
    await prefs.setStringList('reading_history', history);
  }

  void _goToChapter(int index) {
    if (index < 0 || index >= widget.chapters.length) return;
    setState(() {
      _currentIndex = index;
      _currentChapter = widget.chapters[index];
    });
    _scrollController.jumpTo(0);
    _saveProgress();
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('字号', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(children: [
                const Text('A', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _fontSize, min: 12, max: 32, divisions: 20,
                    activeColor: const Color(0xFF3A86FF),
                    inactiveColor: AppColors.borderColor,
                    onChanged: (v) => setModalState(() { setState(() => _fontSize = v); }),
                  ),
                ),
                const Text('A', style: TextStyle(color: Colors.white, fontSize: 20)),
                const SizedBox(width: 8),
                Text('${_fontSize.toInt()}', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 13)),
              ]),
              const SizedBox(height: 20),
              const Text('行距', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(children: [
                const Text('N', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _lineHeight, min: 1.2, max: 3.0, divisions: 18,
                    activeColor: const Color(0xFF3A86FF),
                    inactiveColor: AppColors.borderColor,
                    onChanged: (v) => setModalState(() { setState(() => _lineHeight = v); }),
                  ),
                ),
                const Text('W', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 12)),
                const SizedBox(width: 8),
                Text('${_lineHeight.toStringAsFixed(1)}', style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 13)),
              ]),
              const SizedBox(height: 20),
              const Text('主题', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(children: ReaderTheme.values.map((t) {
                final isActive = _theme == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _theme = t);
                      setModalState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _bgColors[t],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? const Color(0xFF3A86FF) : AppColors.borderColor,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(_themeNames[t]!,
                            style: TextStyle(color: _textColors[t], fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).then((_) => _saveSettings());
  }

  void _showChapterSidebar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(widget.bookTitle, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0x80FFFFFF), size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: widget.chapters.length,
                itemBuilder: (c, i) {
                  final ch = widget.chapters[i];
                  final isCurrent = ch.id == _currentChapter.id;
                  return ListTile(
                    dense: true,
                    title: Text(ch.title,
                        style: TextStyle(
                          color: isCurrent ? const Color(0xFF3A86FF) : Colors.white,
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        )),
                    onTap: () { Navigator.pop(ctx); _goToChapter(i); },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _smartParagraphs(String content) {
    final sentences = content.split(RegExp(r'(?<=[\u3002\uff01\uff1f.!?])'));
    final paragraphs = <String>[];
    var buffer = '';
    for (final s in sentences) {
      final trimmed = s.trim();
      if (trimmed.isEmpty) continue;
      buffer += trimmed;
      final count = buffer.split(RegExp(r'[\u3002\uff01\uff1f.!?]')).where((e) => e.trim().isNotEmpty).length;
      if (count >= 4) {
        paragraphs.add(buffer);
        buffer = '';
      }
    }
    if (buffer.isNotEmpty) paragraphs.add(buffer);
    return paragraphs;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColors[_theme]!;
    final textColor = _textColors[_theme]!;
    final paragraphs = _smartParagraphs(_currentChapter.content);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _currentChapter.title,
          style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.format_size, color: textColor.withOpacity(0.7)),
            onPressed: _showSettings,
          ),
          IconButton(
            icon: Icon(Icons.list, color: textColor.withOpacity(0.7)),
            onPressed: _showChapterSidebar,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentChapter.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: _fontSize + 4,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...paragraphs.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(p,
                          style: TextStyle(color: textColor, fontSize: _fontSize, height: _lineHeight)),
                    )),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: textColor.withOpacity(0.1))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _currentIndex > 0 ? () => _goToChapter(_currentIndex - 1) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chevron_left,
                                color: _currentIndex > 0 ? textColor.withOpacity(0.7) : textColor.withOpacity(0.2), size: 18),
                            Text('上一章',
                                style: TextStyle(
                                    color: _currentIndex > 0 ? textColor.withOpacity(0.7) : textColor.withOpacity(0.2),
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentIndex + 1}/${widget.chapters.length}',
                    style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _currentIndex < widget.chapters.length - 1 ? () => _goToChapter(_currentIndex + 1) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('下一章',
                                style: TextStyle(
                                    color: _currentIndex < widget.chapters.length - 1
                                        ? textColor.withOpacity(0.7)
                                        : textColor.withOpacity(0.2),
                                    fontSize: 13)),
                            Icon(Icons.chevron_right,
                                color: _currentIndex < widget.chapters.length - 1
                                    ? textColor.withOpacity(0.7)
                                    : textColor.withOpacity(0.2),
                                size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
