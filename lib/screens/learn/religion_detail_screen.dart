import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
import 'book_detail_screen.dart';

// ===== 数据模型 =====

class _ReligionBook {
  final String id;
  final String title;
  final String religion;
  final String category;
  final String description;
  _ReligionBook({
    required this.id,
    required this.title,
    required this.religion,
    required this.category,
    required this.description,
  });
  factory _ReligionBook.fromMap(Map<String, dynamic> m) => _ReligionBook(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        religion: m['religion']?.toString() ?? '',
        category: m['category']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
      );
}

/// 宗教详情页 - 对齐网页版 ReligionDetail.tsx
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
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _religion;
  List<_ReligionBook> _relatedBooks = [];
  Map<String, int> _chaptersMap = {};
  bool _loading = true;

  // 共建弹窗状态
  bool _showContribution = false;
  String _contributionType = '';
  String _contributionContent = '';
  String _contributionSource = '';
  bool _contributionSubmitting = false;

  static const List<String> _contributionTypes = [
    '翻译修正',
    '缺失内容',
    '错别字',
    '排版错误',
    '神学术语建议',
    '更权威译本推荐',
    '公版版权信息',
    '其他内容建议',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final client = _supabase;

      // 获取完整宗教数据
      final religionRes = await client
          .from('religions')
          .select()
          .eq('id', widget.religionId)
          .limit(1);
      if (religionRes.isNotEmpty) {
        _religion = Map<String, dynamic>.from(religionRes[0]);
      }

      // 获取相关藏书
      final booksData = await client
          .from('books')
          .select()
          .eq('religion', widget.religionName)
          .eq('status', 'published')
          .order('sort_order')
          .order('title');
      if (booksData.isNotEmpty) {
        _relatedBooks = (booksData as List)
            .map((e) => _ReligionBook.fromMap(e as Map<String, dynamic>))
            .toList();
      }

      // 获取章节计数
      if (_relatedBooks.isNotEmpty) {
        final bookIds = _relatedBooks.map((b) => b.id).toList();
        final chaptersData = await client
            .from('chapters')
            .select('book_id')
            .inFilter('book_id', bookIds)
            .limit(1000);
        if (chaptersData.isNotEmpty) {
          for (final ch in chaptersData as List) {
            final bookId =
                (ch as Map<String, dynamic>)['book_id']?.toString();
            if (bookId != null) {
              _chaptersMap[bookId] = (_chaptersMap[bookId] ?? 0) + 1;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('loadReligionDetail error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== 内容解析工具 =====

  /// 解析换行分隔的内容
  List<String> _parseMultiLine(String? content) {
    if (content == null || content.isEmpty) return [];
    return content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  /// 解析管道分隔的节日内容
  List<List<String>> _parsePipeContent(String? content) {
    if (content == null || content.isEmpty) return [];
    return content.split('\n').map((line) {
      return line.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    }).where((parts) => parts.isNotEmpty).toList();
  }

  /// 解析结构化内容（子标题 + 项目列表）
  List<_Section> _parseStructuredContent(String? content) {
    if (content == null || content.isEmpty) return [];
    final lines = _parseMultiLine(content);
    final sections = <_Section>[];
    _Section? current;

    for (final line in lines) {
      final subTitleMatch =
          RegExp(r'^【([^】]+)】$|^([^：:\n]+)[：:]\s*$').firstMatch(line);
      if (subTitleMatch != null) {
        if (current != null) sections.add(current);
        current = _Section(
          title: (subTitleMatch.group(1) ?? subTitleMatch.group(2) ?? '').trim(),
          items: [],
        );
      } else if (current != null) {
        final colonIdx = _findColonIndex(line);
        if (colonIdx > 0) {
          current.items.add(_SectionItem(
            name: line.substring(0, colonIdx).trim(),
            desc: line.substring(colonIdx + 1).trim(),
          ));
        } else {
          if (current.items.isNotEmpty) {
            current.items.last.desc += ' $line';
          } else {
            current.items.add(_SectionItem(name: '', desc: line.trim()));
          }
        }
      } else {
        // 没有 section 时，尝试创建默认 section
        if (sections.isEmpty) {
          final colonIdx = _findColonIndex(line);
          if (colonIdx > 0) {
            final defaultSection = _Section(title: '', items: []);
            defaultSection.items.add(_SectionItem(
              name: line.substring(0, colonIdx).trim(),
              desc: line.substring(colonIdx + 1).trim(),
            ));
            sections.add(defaultSection);
          }
        }
      }
    }
    if (current != null) sections.add(current);
    return sections;
  }

  int _findColonIndex(String line) {
    final idx1 = line.indexOf('：');
    final idx2 = line.indexOf(':');
    if (idx1 >= 0 && idx2 >= 0) return idx1 < idx2 ? idx1 : idx2;
    return idx1 >= 0 ? idx1 : idx2;
  }

  // ===== UI 组件 =====

  /// 卡片标题（七彩渐变图标 + 文字）- 对齐网页版 CardTitle
  Widget _buildCardTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // 七彩渐变边框图标容器
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: AppColors.auroraGradient,
            ),
            padding: const EdgeInsets.all(1.5),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.cardBg,
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 通用卡片容器
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  /// 多行文本卡片
  Widget _buildMultiLineCard(IconData icon, String title, String? content) {
    final lines = _parseMultiLine(content);
    if (lines.isEmpty) return const SizedBox.shrink();

    return _buildCard(children: [
      _buildCardTitle(icon, title),
      ...lines.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          )),
    ]);
  }

  /// 基本信息行
  Widget _buildInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.hoverBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 核心信仰卡片（左侧七彩渐变边）
  Widget _buildCoreBeliefCard(String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(
            width: 4,
            color: AppColors.auroraCyan, // 简化为单色，因为 Border 不支持 gradient
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                '核心信仰',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 列表式卡片（适用于节日等）
  Widget _buildListCard(IconData icon, String title, String? content) {
    final items = _parsePipeContent(content);
    if (items.isEmpty) return const SizedBox.shrink();

    final isStructured = items.isNotEmpty && items[0].length > 1;

    if (isStructured) {
      return _buildCard(children: [
        _buildCardTitle(icon, title),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.hoverBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${idx + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.isNotEmpty)
                        Text(item[0],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                      if (item.length > 1 && item[1].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(item[1],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      if (item.length > 2 && item[2].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(item[2],
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                height: 1.5,
                              )),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ]);
    } else {
      return _buildCard(children: [
        _buildCardTitle(icon, title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((item) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.hoverBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ]);
    }
  }

  /// 结构化文本卡片（适用于教义等，带子标题 + 小圆点列表）
  Widget _buildStructuredCard(IconData icon, String title, String? content) {
    final sections = _parseStructuredContent(content);
    if (sections.isEmpty) return const SizedBox.shrink();

    final hasSubTitles = sections.any((s) => s.title.isNotEmpty);

    if (!hasSubTitles) {
      // 简单段落
      return _buildCard(children: [
        _buildCardTitle(icon, title),
        ...sections.expand((section) => section.items.map((item) {
              final text = item.name.isNotEmpty
                  ? '${item.name}：${item.desc}'
                  : item.desc;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(text,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.6)),
              );
            })),
      ]);
    }

    return _buildCard(children: [
      _buildCardTitle(icon, title),
      ...sections.expand((section) => [
            if (section.title.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.only(left: 12, top: 6, bottom: 6, right: 8),
                decoration: BoxDecoration(
                  color: AppColors.hoverBgLight,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                  border: const Border(
                    left: BorderSide(
                        color: Color(0x4DFFFFFF), width: 3),
                  ),
                ),
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            ...section.items.map((item) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8, left: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.hoverBg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.name.isNotEmpty)
                              Text(item.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  )),
                            Text(item.desc,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.6,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ]),
    ]);
  }

  /// 圣迹符号卡片（圣地 + 象征物）
  Widget _buildSacredSitesCard(String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    // 复用结构化卡片逻辑
    return _buildStructuredCard(Icons.place, '圣迹符号', content);
  }

  /// 仪式卡片（左侧竖条 + 右侧内容）
  Widget _buildRitualCard(IconData icon, String title, String? content) {
    final sections = _parseStructuredContent(content);
    if (sections.isEmpty) return const SizedBox.shrink();

    return _buildCard(children: [
      _buildCardTitle(icon, title),
      ...sections.asMap().entries.map((entry) {
        final sectionIdx = entry.key;
        final section = entry.value;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧：编号圆圈 + 竖线
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.hoverBg,
                    ),
                    child: Center(
                      child: Text(
                        '${sectionIdx + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (sectionIdx < sections.length - 1)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppColors.borderActive,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // 右侧：内容
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.title.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            section.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ...section.items.map((item) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSecondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.name.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                Text(
                                  item.desc,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ]);
  }

  /// 七彩渐变边框统计卡片（用于 header 区域）
  Widget _buildRainbowBorderStatCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(width: 2, color: Colors.transparent),
          gradient: AppColors.auroraGradient,
          backgroundBlendMode: BlendMode.srcOver,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.bgColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 11)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 简化版七彩渐变边框 - 真正对齐网页版 border-image 效果
  Widget _buildRainbowBorderCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.auroraGradient,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.bgColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 11)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 相关藏书卡片
  Widget _buildBookCard(_ReligionBook book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(
              bookId: book.id,
              bookTitle: book.title,
              bookReligion: book.religion,
              bookCategory: book.category,
              bookDescription: book.description,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(color: Color(0x4DFFFFFF), width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (book.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  book.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 星空点缀装饰
  Widget _buildStarfield() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _StarfieldPainter(),
        ),
      ),
    );
  }

  /// 节日列表项（旧版 holidays 对象兼容）
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
          color: AppColors.hoverBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.hoverBg,
                borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: ShaderMask(
                shaderCallback: (b) =>
                    AppColors.auroraGradient.createShader(b),
                child: Text('$month/$day',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: const TextStyle(
                          color: AppColors.iconColorWeak, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
          const Icon(Icons.chevron_right,
              color: Color(0x4DFFFFFF), size: 20),
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
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))),
                        IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.iconColorWeak, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints()),
                      ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    const Text('日期: ',
                        style: TextStyle(
                            color: AppColors.iconColorWeak, fontSize: 13)),
                    Text('${month}月${day}日',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('宗教: ',
                        style: TextStyle(
                            color: AppColors.iconColorWeak, fontSize: 13)),
                    Text(religion,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.hoverBg,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.hoverBg)),
                      child: Text(desc,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.5))),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppColors.hoverBgLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.borderSubtle)),
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('详情',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              Text(detail,
                                  style: const TextStyle(
                                      color:
                                          AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.5)),
                            ])),
                  ],
                  if (yi.isNotEmpty || ji.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      if (yi.isNotEmpty)
                        Expanded(
                            child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: AppColors.auroraGreen
                                        .withOpacity(0.06),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.auroraGreen
                                            .withOpacity(0.15))),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('宜',
                                          style: TextStyle(
                                              color: Color(
                                                  0xCC70E000),
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text(yi,
                                          style: const TextStyle(
                                              color: Color(
                                                  0xB3FFFFFF),
                                              fontSize: 13,
                                              height: 1.4)),
                                    ]))),
                      if (yi.isNotEmpty && ji.isNotEmpty)
                        const SizedBox(width: 8),
                      if (ji.isNotEmpty)
                        Expanded(
                            child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: AppColors.auroraRed
                                        .withOpacity(0.06),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.auroraRed
                                            .withOpacity(0.15))),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('忌',
                                          style: TextStyle(
                                              color: Color(
                                                  0xCCFF4D6D),
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text(ji,
                                          style: const TextStyle(
                                              color: Color(
                                                  0xB3FFFFFF),
                                              fontSize: 13,
                                              height: 1.4)),
                                    ]))),
                    ]),
                  ],
                ]),
          ),
        ),
      ),
    );
  }

  // ===== 共建弹窗 =====

  void _showContributionDialog() {
    setState(() => _showContribution = true);
  }

  void _closeContributionDialog() {
    setState(() {
      _showContribution = false;
      _contributionType = '';
      _contributionContent = '';
      _contributionSource = '';
    });
  }

  Future<void> _submitContribution() async {
    if (_contributionType.isEmpty || _contributionContent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择类型并填写内容')),
      );
      return;
    }
    setState(() => _contributionSubmitting = true);
    try {
      final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      await _supabase.from('support_tickets').insert({
        'user_id': userId,
        'subject': _contributionType,
        'description': _contributionSource.isNotEmpty
            ? '[$_contributionSource] $_contributionContent'
            : _contributionContent,
        'status': 'open',
        'priority': 'normal',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提交成功，感谢你的共建贡献！')),
      );
      _closeContributionDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提交失败，请稍后重试')),
      );
    }
    setState(() => _contributionSubmitting = false);
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享链接已复制')),
    );
  }

  // ===== Build =====

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0x4DFFFFFF)),
        ),
      );
    }

    // 从完整数据或构造参数中取值
    final religion = _religion ?? {};
    final name = religion['name']?.toString() ?? widget.religionName;
    final type = religion['type']?.toString() ?? widget.type;
    final followersScale =
        religion['followers_scale']?.toString() ?? widget.followersScale;
    final originPlace = religion['origin_place']?.toString();
    final originTime = religion['origin_time']?.toString();
    final distribution = religion['distribution']?.toString();
    final coreBelief = religion['core_belief']?.toString();
    final introduction = religion['introduction']?.toString() ?? widget.introduction;
    final history = religion['history']?.toString();
    final doctrines = religion['doctrines']?.toString();
    final classics = religion['classics']?.toString();
    final festivals = religion['festivals']?.toString();
    final rituals = religion['rituals']?.toString();
    final taboos = religion['taboos']?.toString();
    final sacredSites = religion['sacred_sites']?.toString();
    final famousFigures = religion['famous_figures']?.toString();

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Stack(
        children: [
          // 主内容
          CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // ===== Header - 星空背景 =====
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0A0F2E), AppColors.bgColor],
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildStarfield(),
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 16,
                          left: 16,
                          right: 16,
                          bottom: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 导航栏
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withOpacity(0.1),
                                    ),
                                    child: const Icon(Icons.arrow_back,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _handleShare,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withOpacity(0.1),
                                    ),
                                    child: Icon(Icons.share,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _showContributionDialog,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.white.withOpacity(0.1),
                                    ),
                                    child: Icon(Icons.chat_bubble,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 统计卡片 - 七彩渐变边框
                            Row(
                              children: [
                                if (type != null && type.isNotEmpty) ...[
                                  _buildRainbowBorderCard('宗教类型', type),
                                  const SizedBox(width: 12),
                                ],
                                if (followersScale.isNotEmpty)
                                  _buildRainbowBorderCard(
                                      '全球信徒', followersScale),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== 内容区域 =====
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 基本信息
                    _buildCard(children: [
                      _buildCardTitle(Icons.public, '基本信息'),
                      _buildInfoRow(
                          Icons.place, '起源地区', originPlace),
                      _buildInfoRow(
                          Icons.access_time, '起源时间', originTime),
                      _buildInfoRow(
                          Icons.public, '分布地区', distribution),
                    ]),
                    const SizedBox(height: 16),

                    // 核心信仰
                    _buildCoreBeliefCard(coreBelief),
                    if (coreBelief != null && coreBelief.isNotEmpty)
                      const SizedBox(height: 16),

                    // 简介
                    _buildMultiLineCard(Icons.menu_book, '简介', introduction),
                    if (introduction != null && introduction.isNotEmpty)
                      const SizedBox(height: 16),

                    // 历史发展
                    _buildMultiLineCard(
                        Icons.history, '历史发展', history),
                    if (history != null && history.isNotEmpty)
                      const SizedBox(height: 16),

                    // 主要教义
                    _buildMultiLineCard(
                        Icons.auto_awesome, '主要教义', doctrines),
                    if (doctrines != null && doctrines.isNotEmpty)
                      const SizedBox(height: 16),

                    // 经典著作
                    _buildMultiLineCard(
                        Icons.menu_book, '经典著作', classics),
                    if (classics != null && classics.isNotEmpty)
                      const SizedBox(height: 16),

                    // 主要节日
                    if (festivals != null && festivals.isNotEmpty) ...[
                      _buildListCard(Icons.star, '主要节日', festivals),
                      const SizedBox(height: 16),
                    ],

                    // 礼仪仪式
                    if (rituals != null && rituals.isNotEmpty) ...[
                      _buildRitualCard(
                          Icons.emoji_events, '礼仪仪式', rituals),
                      const SizedBox(height: 16),
                    ],

                    // 禁忌习俗
                    _buildMultiLineCard(
                        Icons.block, '禁忌习俗', taboos),
                    if (taboos != null && taboos.isNotEmpty)
                      const SizedBox(height: 16),

                    // 圣迹符号
                    if (sacredSites != null && sacredSites.isNotEmpty) ...[
                      _buildSacredSitesCard(sacredSites),
                      const SizedBox(height: 16),
                    ],

                    // 著名人物
                    _buildMultiLineCard(
                        Icons.people, '著名人物', famousFigures),
                    if (famousFigures != null && famousFigures.isNotEmpty)
                      const SizedBox(height: 16),

                    // 相关藏书
                    if (_relatedBooks.isNotEmpty) ...[
                      _buildCard(children: [
                        _buildCardTitle(Icons.menu_book, '相关藏书'),
                        ..._relatedBooks
                            .map((book) => _buildBookCard(book)),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    // 旧版 holidays 兼容
                    if (widget.holidays != null &&
                        widget.holidays!.isNotEmpty) ...[
                      _buildCard(children: [
                        _buildCardTitle(Icons.star, '相关节日'),
                        ...widget.holidays!
                            .map((h) => _buildHolidayItem(h)),
                      ]),
                      const SizedBox(height: 16),
                    ],

                    // 空状态
                    if (_relatedBooks.isEmpty &&
                        (widget.holidays == null ||
                            widget.holidays!.isEmpty) &&
                        (introduction == null || introduction.isEmpty) &&
                        (history == null || history.isEmpty) &&
                        (doctrines == null || doctrines.isEmpty) &&
                        (classics == null || classics.isEmpty) &&
                        (festivals == null || festivals.isEmpty) &&
                        (rituals == null || rituals.isEmpty) &&
                        (sacredSites == null || sacredSites.isEmpty) &&
                        (famousFigures == null || famousFigures.isEmpty))
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('暂无更多信息',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),

          // ===== 共建弹窗 =====
          if (_showContribution)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeContributionDialog,
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.height * 0.85,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgColor.withOpacity(0.98),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          border: Border.all(
                              color: AppColors.borderColor),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('参与共建',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.bold)),
                                  GestureDetector(
                                    onTap:
                                        _closeContributionDialog,
                                    child: const Icon(Icons.close,
                                        color: AppColors.iconColorWeak,
                                        size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '你的每一条建议，都在帮助这份信仰内容变得更准确、更完整。',
                                style: TextStyle(
                                    color: AppColors.textPlaceholder,
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 20),

                              // 建议类型
                              const Text('建议类型 *',
                                  style: TextStyle(
                                      color: AppColors.textWeak,
                                      fontSize: 12)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _contributionTypes
                                    .map((t) => GestureDetector(
                                          onTap: () => setState(
                                              () =>
                                                  _contributionType = t),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6),
                                            decoration: BoxDecoration(
                                              color:
                                                  _contributionType == t
                                                      ? const Color(
                                                          0x1FFFFFFF)
                                                      : AppColors
                                                          .inputBg,
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(16),
                                              border: Border.all(
                                                color:
                                                    _contributionType == t
                                                        ? AppColors
                                                            .borderActive
                                                        : AppColors
                                                            .borderColor,
                                              ),
                                            ),
                                            child: Text(t,
                                                style: TextStyle(
                                                  color:
                                                      _contributionType == t
                                                          ? Colors
                                                              .white
                                                          : AppColors
                                                              .textWeak,
                                                  fontSize: 12,
                                                )),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 20),

                              // 来源
                              const Text('来源（选填）',
                                  style: TextStyle(
                                      color: AppColors.textWeak,
                                      fontSize: 12)),
                              const SizedBox(height: 8),
                              TextField(
                                onChanged: (v) => setState(
                                    () => _contributionSource = v),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: '如：某章节、某段内容',
                                  hintStyle: const TextStyle(
                                      color: AppColors.textPlaceholder,
                                      fontSize: 14),
                                  filled: true,
                                  fillColor: AppColors.inputBg,
                                  contentPadding:
                                      const EdgeInsets.all(12),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: AppColors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: AppColors.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: AppColors
                                            .borderActive),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 详细内容
                              const Text('详细内容 *',
                                  style: TextStyle(
                                      color: AppColors.textWeak,
                                      fontSize: 12)),
                              const SizedBox(height: 8),
                              TextField(
                                onChanged: (v) => setState(
                                    () => _contributionContent = v),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14),
                                maxLines: 4,
                                decoration: InputDecoration(
                                  hintText: '请描述你的建议...',
                                  hintStyle: const TextStyle(
                                      color: AppColors.textPlaceholder,
                                      fontSize: 14),
                                  filled: true,
                                  fillColor: AppColors.inputBg,
                                  contentPadding:
                                      const EdgeInsets.all(12),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: AppColors.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: AppColors.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: AppColors
                                            .borderActive),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // 提交按钮（七彩渐变边框）
                              GestureDetector(
                                onTap: _contributionSubmitting
                                    ? null
                                    : _submitContribution,
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.all(1.5),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    gradient: _contributionSubmitting
                                        ? null
                                        : AppColors.auroraGradient,
                                    color: _contributionSubmitting
                                        ? AppColors.hoverBg
                                        : null,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets
                                        .symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      color: AppColors.bgColor
                                          .withOpacity(0.95),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _contributionSubmitting
                                            ? '提交中...'
                                            : '提交建议',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===== 内部数据类 =====

class _Section {
  final String title;
  final List<_SectionItem> items;
  _Section({required this.title, required this.items});
}

class _SectionItem {
  String name;
  String desc;
  _SectionItem({required this.name, required this.desc});
}

// ===== 星空绘制 =====

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = _seededRandom(42);
    final starColors = [
      AppColors.auroraRed,
      AppColors.auroraOrange,
      AppColors.auroraYellow,
      AppColors.auroraGreen,
      AppColors.auroraCyan,
      AppColors.auroraPurple,
      Colors.white.withOpacity(0.4),
      const Color(0xFFC8DCFF).withOpacity(0.4),
    ];

    for (int i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 1.0 + rng.nextDouble() * 1.0;
      final paint = Paint()..color = starColors[i % starColors.length];
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Random _seededRandom(int seed) {
  return Random(seed);
}
