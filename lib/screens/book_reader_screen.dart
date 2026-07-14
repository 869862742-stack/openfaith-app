import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 阅读器 - 支持 PDF 在线阅读和本地离线阅读
class BookReaderScreen extends StatefulWidget {
  final String bookId;
  final String title;
  final String? fileUrl;

  const BookReaderScreen({
    super.key,
    required this.bookId,
    required this.title,
    this.fileUrl,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  String _loadingMessage = '加载书籍中...';
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    // 优先检查本地文件（离线阅读）
    final localFile = await _getLocalBookPath();
    if (localFile != null && await File(localFile).exists()) {
      setState(() {
        _localFilePath = localFile;
        _loadingMessage = '打开本地缓存...';
      });
      return;
    }

    // 确定 fileUrl
    String? url = widget.fileUrl;
    if (url == null || url.isEmpty) {
      // 从 Supabase 查询
      setState(() => _loadingMessage = '获取书籍信息...');
      url = await _fetchFileUrlFromSupabase();
    }

    if (url != null && url.isNotEmpty) {
      setState(() => _loadingMessage = '正在下载书籍...');
      await _downloadAndCacheBook(url);
    } else {
      setState(() {
        _isLoading = false;
        _loadingMessage = '书籍文件不可用';
      });
    }
  }

  /// 从 Supabase books 表查询 file_url
  Future<String?> _fetchFileUrlFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('books')
          .select('file_url, title')
          .eq('id', widget.bookId)
          .limit(1);
      
      if (res != null && res.isNotEmpty) {
        final fileUrl = res[0]['file_url'] as String?;
        // 如果 title 也没传，从数据库取
        if (fileUrl != null) {
          debugPrint('[BookReader] Fetched file_url from Supabase: $fileUrl');
          return fileUrl;
        }
      }
      debugPrint('[BookReader] No file_url found for bookId: ${widget.bookId}');
      return null;
    } catch (e) {
      debugPrint('[BookReader] Supabase query error: $e');
      return null;
    }
  }

  Future<String?> _getLocalBookPath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final bookDir = Directory('${dir.path}/books');
      if (!await bookDir.exists()) return null;

      final files = await bookDir.list().toList();
      for (var file in files) {
        if (file.path.contains(widget.bookId)) {
          return file.path;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[BookReader] Error finding local file: $e');
      return null;
    }
  }

  Future<void> _downloadAndCacheBook(String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final bookDir = Directory('${dir.path}/books');
      if (!await bookDir.exists()) {
        await bookDir.create(recursive: true);
      }

      // 根据文件扩展名或URL推断文件名
      String extension = '.pdf';
      if (url.toLowerCase().contains('.epub')) {
        extension = '.epub';
      }
      final savePath = '${bookDir.path}/${widget.bookId}$extension';

      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            setState(() {
              _loadingMessage = '下载中 ${((received / total) * 100).toInt()}%';
            });
          }
        },
      );

      setState(() {
        _localFilePath = savePath;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadingMessage = '下载失败: $e';
      });
      debugPrint('[BookReader] Download error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF9D4EDD),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _loadingMessage,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : _localFilePath != null
              ? _buildPdfViewer()
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _loadingMessage,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _loadingMessage = '重新加载...';
                          });
                          _loadBook();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9D4EDD),
                        ),
                        child: const Text('重试', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        PDFView(
          filePath: _localFilePath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          fitPolicy: FitPolicy.BOTH,
          backgroundColor: const Color(0xFF050816),
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 0;
              _isLoading = false;
            });
          },
          onPageChanged: (page, total) {
            setState(() {
              _currentPage = page ?? 0;
              _totalPages = total ?? 0;
            });
          },
          onError: (error) {
            setState(() {
              _isLoading = false;
              _loadingMessage = 'PDF 渲染失败';
            });
            debugPrint('[BookReader] PDF error: $error');
          },
          onPageError: (page, error) {
            debugPrint('[BookReader] Page $page error: $error');
          },
        ),
      ],
    );
  }
}
