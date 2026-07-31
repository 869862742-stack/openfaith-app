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
  bool _isDownloading = false;
  bool _isInstalling = false;
  String _status = 'info';
  String _errorMessage = '';
  double _progress = 0.0;
  int? _receivedBytes;
  int? _totalBytes;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    final service = AppUpdateService();
    service.onStatusChange = (status, {error}) {
      if (!mounted) return;
      setState(() {
        _status = status;
        if (status == 'error' && error != null) {
          _errorMessage = error;
          _isDownloading = false;
        }
        if (status == 'installing') {
          _isInstalling = true;
          _isDownloading = false;
        }
        if (status == 'completed') {
          // 安装界面已弹出，关闭对话框
          Navigator.of(context).pop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('正在安装更新，请按提示完成安装'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
        if (status == 'cancelled') {
          _isDownloading = false;
        }
      });
    };

    service.onProgressUpdate = (progress, {receivedBytes, totalBytes}) {
      if (!mounted) return;
      setState(() {
        _progress = progress.clamp(0.0, 1.0);
        _receivedBytes = receivedBytes;
        _totalBytes = totalBytes;
      });
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _status = 'downloading';
      _errorMessage = '';
      _progress = 0.0;
    });

    await AppUpdateService().downloadAndInstall(widget.update);

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _isInstalling = false;
      });
    }
  }

  void _cancelDownload() {
    AppUpdateService().cancelDownload();
    setState(() {
      _isDownloading = false;
      _progress = 0.0;
    });
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
            _isInstalling ? Icons.install_desktop : 
            _isDownloading ? Icons.downloading : Icons.system_update_alt,
            color: AppColors.auroraBlue,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _isInstalling ? '正在安装' :
              _isDownloading ? '正在下载' :
              '发现新版本 v${widget.update.latestVersion}',
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
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.borderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9D4EDD)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            // 进度文字
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _totalBytes != null
                      ? '${_formatBytes(_receivedBytes ?? 0)} / ${_formatBytes(_totalBytes!)}'
                      : _receivedBytes != null
                          ? '${_formatBytes(_receivedBytes!)} 下载中...'
                          : '连接中...',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '错误: $_errorMessage',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
          ] else if (_isInstalling) ...[
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9D4EDD)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '下载完成，正在启动安装程序...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
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
              if (widget.update.size.isNotEmpty)
                Text(
                  '安装包大小: ${widget.update.size}',
                  style: const TextStyle(
                    color: AppColors.textWeak,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
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
            onPressed: _cancelDownload,
            child: const Text(
              '取消下载',
              style: TextStyle(color: AppColors.textWeak, fontSize: 14),
            ),
          )
        else if (_isInstalling)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '关闭',
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
