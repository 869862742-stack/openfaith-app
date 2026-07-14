import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import 'book_reader_screen.dart';

/// 宗教藏书列表 - 显示某个宗教下的所有书籍
class ReligionBookListScreen extends StatefulWidget {
  final String religionId;
  final String religionName;

  const ReligionBookListScreen({
    super.key,
    required this.religionId,
    required this.religionName,
  });

  @override
  State<ReligionBookListScreen> createState() => _ReligionBookListScreenState();
}

class _ReligionBookListScreenState extends State<ReligionBookListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .eq('religion', widget.religionId)
          .order('sort_order')
          .order('title');

      if (mounted) {
        setState(() {
          _books = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ReligionBookList] Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.religionName,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : _books.isEmpty
              ? Center(
                  child: Text(
                    '该宗教暂无藏书',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return _buildBookCard(book);
                  },
                ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    final bookId = book['id']?.toString() ?? '';
    final title = book['title']?.toString() ?? '';
    final coverUrl = book['cover_url']?.toString();
    final category = book['category']?.toString() ?? '';
    final description = book['description']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppColors.auroraGradient,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          color: AppColors.bgColor,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BookReaderScreen(
                    bookId: bookId,
                    title: title,
                    fileUrl: book['file_url']?.toString() ?? '',
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 封面
                  if (coverUrl != null && coverUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: coverUrl,
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 80,
                          color: AppColors.bgSecondary,
                          child: const Icon(Icons.book, color: AppColors.purple),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 80,
                          color: AppColors.bgSecondary,
                          child: const Icon(Icons.book, color: AppColors.purple),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.bgSecondary,
                      ),
                      child: const Icon(Icons.book, color: AppColors.purple, size: 28),
                    ),
                  const SizedBox(width: 14),
                  // 书籍信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (category.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: AppColors.bgSecondary,
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
