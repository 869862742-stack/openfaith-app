import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();

  final List<_Category> _categories = [
    _Category('圣经研读', Icons.menu_book, AppColors.auroraPurple),
    _Category('祷告指南', Icons.self_improvement, AppColors.auroraGreen),
    _Category('灵修日记', Icons.edit_note, AppColors.auroraOrange),
    _Category('教会动态', Icons.church, AppColors.auroraBlue),
    _Category('诗歌赞美', Icons.music_note, AppColors.auroraRed),
    _Category('团契生活', Icons.groups, AppColors.auroraYellow),
  ];

  final List<_HotTopic> _hotTopics = [
    _HotTopic('每日灵修：诗篇23篇', '今天默想耶和华是我的牧者...', 128, 32),
    _HotTopic('新约圣经读书计划', '一起读完使徒行传，每日打卡分享', 86, 15),
    _HotTopic('祷告墙', '为彼此代祷，见证神的恩典', 234, 67),
    _HotTopic('信仰问答', '关于信仰的疑问，在这里找到答案', 156, 43),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // 毛玻璃 Header
            _glassHeader(),
            // 内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // 搜索框
                    _searchBar(),
                    const SizedBox(height: 24),
                    // 分类浏览
                    const Text(
                      '分类浏览',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children:
                          _categories.map((cat) => _buildCategoryCard(cat)).toList(),
                    ),
                    const SizedBox(height: 24),
                    // 热门话题
                    const Text(
                      '热门话题',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._hotTopics.map((topic) => _buildHotTopicCard(topic)),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.headerBg,
            border: Border(
              bottom: BorderSide(color: AppColors.borderDefault, width: 1),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '发现',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.iconColorWeak,
                  size: 22,
                ),
                onPressed: () {},
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: AppColors.textWeak,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: '搜索内容、用户、话题...',
                hintStyle: const TextStyle(
                  color: AppColors.textPlaceholder,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onTapOutside: (event) => FocusScope.of(context).unfocus(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_Category cat) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cat.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, color: cat.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              cat.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotTopicCard(_HotTopic topic) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '热门话题',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            topic.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            topic.desc,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.textWeak,
              ),
              const SizedBox(width: 4),
              Text(
                '${topic.participants}人参与',
                style: const TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: AppColors.textWeak,
              ),
              const SizedBox(width: 4),
              Text(
                '${topic.posts}条动态',
                style: const TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _Category {
  final String name;
  final IconData icon;
  final Color color;
  _Category(this.name, this.icon, this.color);
}

class _HotTopic {
  final String title;
  final String desc;
  final int participants;
  final int posts;
  _HotTopic(this.title, this.desc, this.participants, this.posts);
}
