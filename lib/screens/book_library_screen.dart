import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import 'religion_book_list_screen.dart';

/// 藏书阁 - 宗教分类列表（对齐网页版"经典藏书"）
/// 显示所有宗教及其藏书数量，点击跳转到该宗教的藏书列表
class BookLibraryScreen extends StatefulWidget {
  const BookLibraryScreen({super.key});

  @override
  State<BookLibraryScreen> createState() => _BookLibraryScreenState();
}

class _BookLibraryScreenState extends State<BookLibraryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _religions = [];
  Map<String, int> _bookCounts = {};
  Map<String, int> _groupCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 并行获取宗教、书籍、书组数据
      final results = await Future.wait([
        _supabase.from('religions').select().eq('is_active', true).order('sort_order').order('name'),
        _supabase.from('books').select('religion, id'),
        _supabase.from('book_groups').select('religion, id, parent_id'),
      ]);

      final religions = (results[0] as List).cast<Map<String, dynamic>>();
      final books = (results[1] as List).cast<Map<String, dynamic>>();
      final groups = (results[2] as List).cast<Map<String, dynamic>>();

      // 统计每个宗教的书籍数量
      final bookCounts = <String, int>{};
      for (final book in books) {
        final religion = book['religion']?.toString() ?? '';
        bookCounts[religion] = (bookCounts[religion] ?? 0) + 1;
      }

      // 统计每个宗教的顶级书组数量（parent_id 为空的）
      final groupCounts = <String, int>{};
      for (final group in groups) {
        if (group['parent_id'] == null) {
          final religion = group['religion']?.toString() ?? '';
          groupCounts[religion] = (groupCounts[religion] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _religions = religions;
          _bookCounts = bookCounts;
          _groupCounts = groupCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[BookLibrary] Error loading data: $e');
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
        title: const Text(
          '经典藏书',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : _religions.isEmpty
              ? Center(
                  child: Text(
                    '暂无藏书数据',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _religions.length,
                  itemBuilder: (context, index) {
                    final religion = _religions[index];
                    final religionId = religion['id']?.toString() ?? '';
                    final religionName = religion['name']?.toString() ?? '';
                    final bookCount = _bookCounts[religionId] ?? 0;
                    final groupCount = _groupCounts[religionId] ?? 0;

                    return _buildReligionCard(
                      religionId: religionId,
                      religionName: religionName,
                      bookCount: bookCount,
                      groupCount: groupCount,
                    );
                  },
                ),
    );
  }

  Widget _buildReligionCard({
    required String religionId,
    required String religionName,
    required int bookCount,
    required int groupCount,
  }) {
    // 构建副标题：X 卷 或 X 个子分类 · Y 卷
    String subtitle = '';
    if (groupCount > 0 && bookCount > 0) {
      subtitle = '$groupCount 个子分类 · $bookCount 卷';
    } else if (bookCount > 0) {
      subtitle = '$bookCount 卷';
    } else if (groupCount > 0) {
      subtitle = '$groupCount 个子分类';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      // 外层：1px 渐变边框
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: AppColors.auroraGradient,
      ),
      child: Container(
        // 内层：深色背景
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
                  builder: (_) => ReligionBookListScreen(
                    religionId: religionId,
                    religionName: religionName,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 书籍图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.bgSecondary,
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: AppColors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // 文字信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          religionName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 箭头
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textWeak,
                    size: 20,
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
