import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'book_reader_screen.dart';

/// 藏书阁 - 展示书籍列表，支持下载和在线阅读
class BookLibraryScreen extends StatefulWidget {
  const BookLibraryScreen({super.key});

  @override
  State<BookLibraryScreen> createState() => _BookLibraryScreenState();
}

class _BookLibraryScreenState extends State<BookLibraryScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;
  int _currentTab = 0;
  Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final response = await _supabase
          .from('books')
          .select('*')
          .order('created_at', ascending: false);
      setState(() {
        _books = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('[BookLibrary] Error: $e');
    }
  }

  Future<void> _downloadBook(Map<String, dynamic> book) async {
    final bookId = book['id'];
    final fileUrl = book['file_url'];
    if (fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('书籍文件不可用')));
      return;
    }
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('需要存储权限才能下载')));
      return;
    }
    setState(() => _downloadProgress[bookId] = 0);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final bookDir = Directory('${dir.path}/books');
      if (!await bookDir.exists()) await bookDir.create(recursive: true);
      final fileName = book['filename'] ?? '$bookId.pdf';
      final savePath = '${bookDir.path}/$fileName';
      await Dio().download(fileUrl, savePath, onReceiveProgress: (received, total) {
        setState(() => _downloadProgress[bookId] = received / total);
      });
      setState(() => _downloadProgress.remove(bookId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下载完成')));
    } catch (e) {
      setState(() => _downloadProgress.remove(bookId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下载失败: $e')));
    }
  }

  bool _isDownloaded(String bookId) => false; // TODO

  void _openBook(Map<String, dynamic> book) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => BookReaderScreen(
        bookId: book['id'],
        title: book['title'] ?? '',
        fileUrl: book['file_url'],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF050816),
        appBar: AppBar(
          backgroundColor: const Color(0xFF050816),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          title: const Text('藏书阁', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: const Color(0xFF9D4EDD),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            onTap: (index) => setState(() => _currentTab = index),
            tabs: const [
              Tab(text: '全部藏书'),
              Tab(text: '已下载'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookList(_books),
            _buildBookList(_books.where((b) => _isDownloaded(b['id'])).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList(List<Map<String, dynamic>> books) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(_currentTab == 0 ? '暂无藏书' : '暂无下载', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, mainAxisSpacing: 16, crossAxisSpacing: 12, childAspectRatio: 0.6,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) => _buildBookCard(books[index]),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    final title = book['title'] ?? '未知书名';
    final author = book['author'] ?? '未知作者';
    final coverUrl = book['cover_url'];
    final bookId = book['id'];
    final isDownloading = _downloadProgress.containsKey(bookId);
    final progress = _downloadProgress[bookId] ?? 0;

    return GestureDetector(
      onTap: () => _openBook(book),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFF0A0E21)),
                    child: coverUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: coverUrl, fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD), strokeWidth: 2)),
                              errorWidget: (context, url, error) => const Center(child: Icon(Icons.book, size: 40, color: Colors.white38)),
                            ),
                          )
                        : const Center(child: Icon(Icons.book, size: 40, color: Colors.white38)),
                  ),
                  if (isDownloading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black.withOpacity(0.7)),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 32, height: 32, child: CircularProgressIndicator(value: progress, color: const Color(0xFF9D4EDD), strokeWidth: 3)),
                              const SizedBox(height: 8),
                              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_isDownloaded(bookId))
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: const Color(0xFF9D4EDD), borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.download_done, size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(author, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
