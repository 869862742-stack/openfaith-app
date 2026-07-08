import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
import 'book_detail_screen.dart';

class _ReligionBook {
  final String id;
  final String title;
  final String religion;
  final String category;
  final String description;
  _ReligionBook({required this.id, required this.title, required this.religion, required this.category, required this.description});
  factory _ReligionBook.fromMap(Map<String, dynamic> m) => _ReligionBook(
    id: m['id']?.toString() ?? '',
    title: m['title']?.toString() ?? '',
    religion: m['religion']?.toString() ?? '',
    category: m['category']?.toString() ?? '',
    description: m['description']?.toString() ?? '',
  );
}

class ReligionDetailScreen extends StatefulWidget {
  final String religionId;
  final String religionName;
  final String followersScale;
  final String? type;
  final String? introduction;
  final List<dynamic>? holidays;
  const ReligionDetailScreen({
    super.key,
    required this.religionId,
    required this.religionName,
    required this.followersScale,
    this.type,
    this.introduction,
    this.holidays,
  });

  @override
  State<ReligionDetailScreen> createState() => _ReligionDetailScreenState();
}

class _ReligionDetailScreenState extends State<ReligionDetailScreen> {
  List<_ReligionBook> _relatedBooks = [];
  Map<String, int> _chaptersMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final client = Supabase.instance.client;
      final booksData = await client
          .from('books')
          .select()
          .eq('religion', widget.religionName)
          .order('sort_order')
          .order('title');
      if (booksData.isNotEmpty) {
        _relatedBooks = (booksData as List)
            .map((e) => _ReligionBook.fromMap(e as Map<String, dynamic>))
            .toList();
      }
      if (_relatedBooks.isNotEmpty) {
        final bookIds = _relatedBooks.map((b) => b.id).toList();
        final chaptersData = await client
            .from('chapters')
            .select('book_id')
            .inFilter('book_id', bookIds)
            .limit(1000);
        if (chaptersData.isNotEmpty) {
          for (final ch in chaptersData as List) {
            final bookId = (ch as Map<String, dynamic>)['book_id']?.toString();
            if (bookId != null) _chaptersMap[bookId] = (_chaptersMap[bookId] ?? 0) + 1;
          }
        }
      }
    } catch (e) {
      debugPrint('loadReligionDetail error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
          widget.religionName,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B949E)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  if (widget.introduction != null && widget.introduction!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('简介',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _buildIntroCard(),
                  ],
                  if (_relatedBooks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(children: [
                      const Text('相关书籍',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${_relatedBooks.length}',
                          style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 13)),
                    ]),
                    const SizedBox(height: 12),
                    ..._relatedBooks.map((book) => _buildBookCard(book)),
                  ],
                  if (widget.holidays != null && widget.holidays!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(children: [
                      const Text('相关节日',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${widget.holidays!.length}',
                          style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 13)),
                    ]),
                    const SizedBox(height: 12),
                    ...widget.holidays!.map((h) => _buildHolidayItem(h)),
                  ],
                  if (_relatedBooks.isEmpty &&
                      (widget.holidays == null || widget.holidays!.isEmpty) &&
                      (widget.introduction == null || widget.introduction!.isEmpty))
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('暂无更多信息', style: TextStyle(color: Color(0xFF8B949E))),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A), Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  transform: GradientRotation(0.35),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.religionName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.people_outline, color: Color(0x80FFFFFF), size: 16),
            const SizedBox(width: 6),
            Text('信徒规模', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.followersScale,
                  style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          if (widget.type != null && widget.type!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.category_outlined, color: Color(0x80FFFFFF), size: 16),
              const SizedBox(width: 6),
              Text('类型', style: TextStyle(color: Color(0x66FFFFFF), fontSize: 12)),
              const SizedBox(width: 8),
              Text(widget.type!, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Text(widget.introduction!,
          style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, height: 1.7)),
    );
  }

  Widget _buildBookCard(_ReligionBook book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(
          bookId: book.id, bookTitle: book.title,
          bookReligion: book.religion, bookCategory: book.category,
          bookDescription: book.description,
        )));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.menu_book, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(book.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                [
                  book.category.isNotEmpty ? book.category : '',
                  if (_chaptersMap.containsKey(book.id)) '${_chaptersMap[book.id]} 章',
                ].where((e) => e.isNotEmpty).join(' \u00b7 '),
                style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
              ),
            ]),
          ),
          const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20),
        ]),
      ),
    );
  }

  Widget _buildHolidayItem(dynamic holiday) {
    final name = holiday.name?.toString() ?? '';
    final month = holiday.month?.toString() ?? '';
    final day = holiday.day?.toString() ?? '';
    final desc = holiday.desc?.toString() ?? '';
    return GestureDetector(
      onTap: () => _showHolidayDetail(holiday),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0x0FFFFFFF), borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A), Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  transform: GradientRotation(0.35),
                ).createShader(b),
                child: Text('$month/$day',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const Icon(Icons.chevron_right, color: Color(0x4DFFFFFF), size: 20),
        ]),
      ),
    );
  }

  void _showHolidayDetail(dynamic holiday) {
    final name = holiday.name?.toString() ?? '';
    final month = holiday.month?.toString() ?? '';
    final day = holiday.day?.toString() ?? '';
    final religion = holiday.religion?.toString() ?? '';
    final desc = holiday.desc?.toString() ?? '';
    final detail = holiday.detail?.toString() ?? '';
    final yi = holiday.yi?.toString() ?? '';
    final ji = holiday.ji?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.close, color: Color(0x80FFFFFF), size: 20),
                    onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Text('日期: ', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13)),
                Text('${month}月${day}日', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Text('宗教: ', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13)),
                Text(religion, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              Container(width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0x0AFFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x0FFFFFFF))),
                child: Text(desc, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5))),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(width: double.infinity, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0x08FFFFFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x0DFFFFFF))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('详情', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(detail, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.5)),
                  ])),
              ],
              if (yi.isNotEmpty || ji.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: [
                  if (yi.isNotEmpty) Expanded(child: Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0x0F70E000), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x2670E000))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('宜', style: TextStyle(color: Color(0xCC70E000), fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(yi, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.4)),
                    ]))),
                  if (yi.isNotEmpty && ji.isNotEmpty) const SizedBox(width: 8),
                  if (ji.isNotEmpty) Expanded(child: Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0x0FFF4D6D), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0x26FF4D6D))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('忌', style: TextStyle(color: Color(0xCCFF4D6D), fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(ji, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13, height: 1.4)),
                    ]))),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
