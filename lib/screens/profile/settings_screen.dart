import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
import '../../i18n/app_localizations.dart';
import 'account_security_screen.dart';
import 'display_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'language_settings_screen.dart';
import 'content_preferences_screen.dart';
import 'switch_account_screen.dart';
import '../sidebar_pages/privacy_policy_screen.dart';
import '../sidebar_pages/terms_of_service_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final int initialTab;

  const SettingsScreen({super.key, this.initialTab = 0});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Column(
        children: [
          // ── Header: transparent + backdrop blur + borderBottom ──
          _buildHeader(),
          // ── Scrollable content ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // ── 5 functional setting items (each independent rounded-xl card) ──
                _buildSettingItem(
                  icon: Icons.person_outline,
                  title: context.tr('settings_account_security'),
                  onTap: () => _navigateTo(const AccountSecurityScreen()),
                ),
                const SizedBox(height: 4), // space-y-1 ≈ 4px
                _buildSettingItem(
                  icon: Icons.text_fields_outlined,
                  title: context.tr('settings_display'),
                  onTap: () => _navigateTo(const DisplaySettingsScreen()),
                ),
                const SizedBox(height: 4),
                _buildSettingItem(
                  icon: Icons.notifications_outlined,
                  title: context.tr('settings_notification'),
                  onTap: () => _navigateTo(const NotificationSettingsScreen()),
                ),
                const SizedBox(height: 4),
                _buildSettingItem(
                  icon: Icons.language,
                  title: context.tr('settings_language'),
                  onTap: () => _navigateTo(const LanguageSettingsScreen()),
                ),
                const SizedBox(height: 4),
                _buildSettingItem(
                  icon: Icons.article_outlined,
                  title: context.tr('settings_content_preference'),
                  onTap: () => _navigateTo(const ContentPreferencesScreen()),
                ),

                // ── Divider ──
                const SizedBox(height: 24),
                Container(
                  height: 0.5,
                  color: AppColors.borderColor,
                ),
                const SizedBox(height: 24),

                // ── Account actions ──
                _buildSettingItem(
                  icon: Icons.people_outline,
                  title: context.tr('settings_switch_account'),
                  onTap: () => _navigateTo(const SwitchAccountScreen()),
                ),
                const SizedBox(height: 4),
                _buildSettingItem(
                  icon: Icons.logout,
                  title: context.tr('settings_logout'),
                  isDestructive: true,
                  onTap: _showLogoutDialog,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Header with blur effect
  // ═══════════════════════════════════════════
  Widget _buildHeader() {
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
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
                  context.tr('settings'),
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

  // ═══════════════════════════════════════════
  // Individual setting item card
  // ═══════════════════════════════════════════
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive
        ? AppColors.accentRed
        : AppColors.iconColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12), // rounded-xl
        ),
        child: Row(
          children: [
            // Icon
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 16), // gap-4
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDestructive ? AppColors.accentRed : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: isDestructive ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            // No chevron — web version has none
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Navigation
  // ═══════════════════════════════════════════
  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // ═══════════════════════════════════════════
  // Logout
  // ═══════════════════════════════════════════
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
        title: Text(
          context.tr('settings_logout'),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Text(
          context.tr('logout_confirm_content'),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('cancel'),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _performLogout();
            },
            child: Text(context.tr('confirm'),
                style: const TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      try {
        await _supabase.auth.signOut();
        debugPrint('[Auth] Supabase signOut success');
      } catch (e) {
        debugPrint('[Auth] Supabase signOut error (ignored): $e');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      debugPrint('[Auth] Logout completed');
    } catch (e) {
      debugPrint('[Auth] Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('logout_failed')}: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }
}
