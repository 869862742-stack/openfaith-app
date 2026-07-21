import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../../theme/app_colors.dart';
import '../../i18n/app_localizations.dart';
import '../sidebar_pages/privacy_policy_screen.dart';
import '../sidebar_pages/terms_of_service_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = '';
  String _buildNumber = '';
  bool _checkingUpdate = false;
  String _updateMessage = '';
  String _patchVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
    _loadPatchVersion();
  }

  Future<void> _loadVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _loadPatchVersion() async {
    try {
      final patcher = ShorebirdUpdater();
      final status = await patcher.checkForUpdate();
      if (mounted) {
        setState(() {
          _patchVersion = status == UpdateStatus.outdated ? '有更新可用' : '已是最新';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              title: context.tr('about_title'),
              onBack: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.auroraRed,
                        width: 1.5,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        color: AppColors.bgColor,
                      ),
                      padding: const EdgeInsets.all(1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.auroraGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: AppColors.bgColor,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Text(
                                'OF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'OpenFaith',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version $_appVersion ($_buildNumber)',
                    style: TextStyle(
                      color: AppColors.textWeak,
                      fontSize: 13,
                    ),
                  ),
                  if (_patchVersion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '补丁: $_patchVersion',
                      style: TextStyle(
                        color: _patchVersion.contains('最新')
                            ? AppColors.auroraGreen
                            : AppColors.auroraYellow,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 0.5,
              color: AppColors.borderColor,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: context.tr('about_feature_intro'),
                    onTap: _showFeatureIntro,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.system_update_outlined,
                    title: context.tr('about_version_update'),
                    trailing: _checkingUpdate
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    onTap: _checkForUpdate,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.download_outlined,
                    title: context.tr('about_download_apk'),
                    onTap: _openGithubRelease,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 0.5,
              color: AppColors.borderColor,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: context.tr('about_privacy_policy'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen()),
                    ),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: context.tr('about_terms_of_service'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TermsOfServiceScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Text(
                    'Copyright 2025-2026 OpenFaith. All Rights Reserved.',
                    style: TextStyle(
                      color: AppColors.textPlaceholder,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'openfaithhub.com',
                    style: TextStyle(
                      color: AppColors.textPlaceholder,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_updateMessage.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Text(
                    _updateMessage,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.iconColor, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(
                Icons.chevron_right,
                color: AppColors.textWeak,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 0.5,
      color: AppColors.borderColor,
    );
  }

  void _showFeatureIntro() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
        title: Text(
          context.tr('about_feature_intro'),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Text(
            context.tr('about_feature_content'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.8,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              context.tr('confirm'),
              style: const TextStyle(color: AppColors.auroraBlue),
            ),
          ),
        ],
      ),
    );
  }

  /// 检查更新：先检查 version.json（APP 版本），再检查 Shorebird 补丁
  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;
    setState(() {
      _checkingUpdate = true;
      _updateMessage = '';
    });

    try {
      // Step 1: 检查 version.json（APP 版本更新）
      final versionChecked = await _checkVersionJson();
      if (versionChecked) {
        // 有新版本，已弹窗提示，结束
        if (mounted) {
          setState(() {
            _checkingUpdate = false;
          });
        }
        return;
      }

      // Step 2: APP 已是最新，检查 Shorebird 补丁
      try {
        final patcher = ShorebirdUpdater();
        final status = await patcher.checkForUpdate();

        if (status == UpdateStatus.outdated) {
          if (mounted) {
            setState(() {
              _updateMessage = '发现新补丁版本！\n\n正在下载更新补丁...\n下载完成后重启APP即可生效。';
              _checkingUpdate = false;
            });
          }
          await patcher.update();
          if (mounted) {
            setState(() {
              _updateMessage = '补丁已下载完成！\n\n请重启APP以应用更新。';
            });
          }
          return;
        }
      } catch (e) {
        debugPrint('[About] Shorebird check error: $e');
      }

      // Step 3: 都已是最新
      if (mounted) {
        setState(() {
          _updateMessage = '当前已是最新版本 ($_appVersion)\n\n补丁状态: 已是最新';
          _checkingUpdate = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _updateMessage = '检查更新失败: $e\n\n请稍后重试，或前往 GitHub Releases 手动下载最新版本。';
          _checkingUpdate = false;
        });
      }
    }
  }

  /// 检查 version.json 是否有新版本
  /// 返回 true 表示有新版本（已弹窗），false 表示已是最新或检查失败
  Future<bool> _checkVersionJson() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://openfaithhub.com/version.json',
        options: Options(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode != 200 || response.data == null) {
        debugPrint('[About] Failed to fetch version.json: ${response.statusCode}');
        return false;
      }

      final Map<String, dynamic> data;
      if (response.data is String) {
        data = json.decode(response.data as String) as Map<String, dynamic>;
      } else if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      } else {
        debugPrint('[About] Unexpected response format');
        return false;
      }

      final latestVersion = data['latestVersion'] as String? ?? '';
      final downloadUrl = data['downloadUrl'] as String? ?? '';
      final fallbackUrl = data['fallbackUrl'] as String? ?? '';
      final changelog = data['changelog'] as String? ?? '';

      if (latestVersion.isEmpty) {
        debugPrint('[About] Invalid version data');
        return false;
      }

      // 比较版本号
      if (_isNewerVersion(_appVersion, latestVersion)) {
        debugPrint('[About] New version available: $latestVersion (current: $_appVersion)');
        if (mounted) {
          _showUpdateDialog(
            latestVersion: latestVersion,
            currentVersion: _appVersion,
            downloadUrl: downloadUrl,
            fallbackUrl: fallbackUrl,
            changelog: changelog,
          );
        }
        return true;
      } else {
        debugPrint('[About] APP version up to date: $_appVersion');
        return false;
      }
    } catch (e) {
      debugPrint('[About] version.json check error: $e');
      return false;
    }
  }

  /// 比较语义化版本号，判断 remote 是否比 current 更新
  bool _isNewerVersion(String current, String remote) {
    try {
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = currentParts.length > remoteParts.length
          ? currentParts.length
          : remoteParts.length;
      while (currentParts.length < maxLen) {
        currentParts.add(0);
      }
      while (remoteParts.length < maxLen) {
        remoteParts.add(0);
      }

      for (int i = 0; i < maxLen; i++) {
        if (remoteParts[i] > currentParts[i]) return true;
        if (remoteParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint('[About] Version compare error: $e');
      return false;
    }
  }

  /// 显示版本更新弹窗
  void _showUpdateDialog({
    required String latestVersion,
    required String currentVersion,
    required String downloadUrl,
    required String fallbackUrl,
    required String changelog,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.borderColor, width: 0.5),
          ),
          title: Row(
            children: [
              const Icon(Icons.system_update_alt, color: AppColors.auroraBlue, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '发现新版本 v$latestVersion',
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
              Text(
                '当前版本: v$currentVersion',
                style: const TextStyle(
                  color: AppColors.textWeak,
                  fontSize: 13,
                ),
              ),
              if (changelog.isNotEmpty) ...[
                const SizedBox(height: 12),
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
                      changelog,
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                '稍后再说',
                style: TextStyle(color: AppColors.textWeak, fontSize: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openDownloadUrl(downloadUrl, fallbackUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D4EDD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('立即下载', style: TextStyle(fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  /// 打开下载链接
  Future<void> _openDownloadUrl(String downloadUrl, String fallbackUrl) async {
    String url = downloadUrl;
    if (url.isEmpty && fallbackUrl.isNotEmpty) {
      url = fallbackUrl;
    }
    if (url.isEmpty) {
      // 兜底到默认下载页
      url = 'https://openfaithhub.com/download';
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[About] Failed to open download URL: $e');
    }
  }

  Future<void> _openGithubRelease() async {
    final url = Uri.parse(
        'https://github.com/869862742-stack/openfaith-app/releases');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final VoidCallback onBack;

  _SliverAppBarDelegate({required this.title, required this.onBack});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.headerBg,
            border: Border(
              bottom: BorderSide(color: AppColors.borderColor, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
