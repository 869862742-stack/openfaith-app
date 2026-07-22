import 'package:flutter/material.dart';
import '../services/app_update_service.dart';
import '../theme/app_colors.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo update;
  const UpdateDialog({super.key, required this.update});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  String _status = 'info'; // 'info' | 'downloading' | 'error'
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    final service = AppUpdateService();
    service.onProgressUpdate = (progress) {
      if (mounted) {
        setState(() {
          _downloadProgress = progress;
        });
      }
    };
    service.onStatusChange = (status, {error}) {
      if (!mounted) return;
      setState(() {
        _status = status;
        if (status == 'error' && error != null) {
          _errorMessage = error;
          _isDownloading = false;
        }
        if (status == 'completed') {
          Navigator.of(context).pop();
        }
      });
    };
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _status = 'downloading';
      _downloadProgress = 0.0;
      _errorMessage = '';
    });

    await AppUpdateService().downloadAndInstall(widget.update);

    if (mounted) {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.borderColor, width: 0.5),
      ),
      title: Row(
        children: [
          Icon(
            _isDownloading ? Icons.downloading : Icons.system_update_alt,
            color: AppColors.auroraBlue,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _isDownloading
                  ? '正在下载更新'
                  : '发现新版本 v${widget.update.latestVersion}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: AppColors.borderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9D4EDD)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'v${widget.update.latestVersion}',
                  style: const TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '下载失败: $_errorMessage',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ] else ...[
            if (widget.update.changelog.isNotEmpty) ...[
              const Text(
                '更新内容',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: Text(
                    widget.update.changelog,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
      actions: [
        if (_isDownloading)
          TextButton(
            onPressed: () {
              AppUpdateService().cancelDownload();
              Navigator.pop(context);
            },
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.textWeak, fontSize: 14),
            ),
          )
        else ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '稍后提醒',
              style: TextStyle(color: AppColors.textWeak, fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: _startDownload,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9D4EDD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _errorMessage.isNotEmpty ? '重试' : '立即更新',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}
