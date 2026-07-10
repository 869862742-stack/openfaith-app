import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _downloadedCount = 0;
  int _resourceCount = 0;
  String _totalSize = '0 MB';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(isOnline: _isOnline, onBack: () => Navigator.pop(context)),
          ),
          // Stats bar
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
              ),
              child: Row(
                children: [
                  _buildStat('$_downloadedCount', '已下载书籍'),
                  _buildDivider(),
                  _buildStat('$_resourceCount', '笔记资源'),
                  _buildDivider(),
                  _buildStat(_totalSize, '占用空间'),
                ],
              ),
            ),
          ),
          // Tab bar
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.auroraBlue,
                indicatorWeight: 2,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textWeak,
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.menu_book, size: 16), SizedBox(width: 8), Text('离线书籍')])),
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.description, size: 16), SizedBox(width: 8), Text('笔记资源')])),
                ],
              ),
            ),
          ),
          // Tab content
          SliverFillRemaining(
            hasScrollBody: false,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBooksTab(),
                _buildResourcesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: 1,
      height: 32,
      color: AppColors.borderDefault,
    );
  }

  Widget _buildBooksTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, color: AppColors.textWeak, size: 48),
            const SizedBox(height: 12),
            const Text('暂无下载的书籍', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, color: AppColors.textWeak, size: 48),
            const SizedBox(height: 12),
            const Text('暂无笔记资源', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('从笔记中保存的图片和视频将显示在这里', style: TextStyle(color: AppColors.textWeak, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final bool isOnline;
  final VoidCallback onBack;

  _HeaderDelegate({required this.isOnline, required this.onBack});

  @override
  double get maxExtent => 56.0;

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) => oldDelegate.isOnline != isOnline;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: AppColors.headerBg,
            border: Border(bottom: BorderSide(color: AppColors.borderDefault, width: 1)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                ),
              ),
              const SizedBox(width: 4),
              const Text('我的下载', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              // Network status with aurora gradient text
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.auroraColors,
                  ).createShader(bounds);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isOnline ? Icons.wifi : Icons.wifi_off, color: AppColors.textPrimary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? '在线' : '离线',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
