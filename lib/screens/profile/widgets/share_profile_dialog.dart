import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/colors.dart';
import '../../../theme/rainbow_widgets.dart';

/// 分享弹窗
class ShareProfileDialog extends StatelessWidget {
  final String shareUrl;
  final String nickname;

  const ShareProfileDialog({
    super.key,
    required this.shareUrl,
    required this.nickname,
  });

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shareUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('链接已复制到剪贴板'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部拖拽条
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // 标题
              const Text('分享主页',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              // 分享选项
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _shareItem(context, Icons.person, '分享给好友', () {
                      Navigator.pop(context);
                    }),
                    _shareItem(context, Icons.group, '分享到群聊', () {
                      Navigator.pop(context);
                    }),
                    _shareItem(context, Icons.share, '更多', () {
                      _copyLink(context);
                      Navigator.pop(context);
                    }),
                    _shareItem(context, Icons.link, '复制链接', () {
                      _copyLink(context);
                      Navigator.pop(context);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 提示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('点击"更多"可分享到微信、QQ、微博等应用',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              // 链接预览
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.link, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(shareUrl,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              // 取消按钮
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text('取消',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        RainbowBorder(
          borderWidth: 1,
          borderRadius: 30,
          child: Container(
            width: 52, height: 52,
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}
