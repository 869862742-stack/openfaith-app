import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('\u8bbe\u7f6e',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ---- \u7b2c\u4e00\u7ec4\uff1a\u529f\u80fd\u8bbe\u7f6e\u9875 ----
          _buildSettingsCard([
            _buildListTile(
              icon: Icons.lock_outline,
              title: '\u8d26\u53f7\u5b89\u5168',
              onTap: () => _navigateTo(const AccountSecurityScreen()),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.display_settings_outlined,
              title: '\u663e\u793a\u8bbe\u7f6e',
              onTap: () => _navigateTo(const DisplaySettingsScreen()),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.notifications_outlined,
              title: '\u901a\u77e5\u8bbe\u7f6e',
              onTap: () => _navigateTo(const NotificationSettingsScreen()),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.language,
              title: '\u8bed\u8a00\u8bbe\u7f6e',
              onTap: () => _navigateTo(const LanguageSettingsScreen()),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.tune_outlined,
              title: '\u5185\u5bb9\u504f\u597d',
              onTap: () => _navigateTo(const ContentPreferencesScreen()),
            ),
          ]),
          const SizedBox(height: 24),

          // ---- \u7b2c\u4e8c\u7ec4\uff1a\u5173\u4e8e\u4e0e\u6cd5\u5f8b ----
          _buildSettingsCard([
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              title: '\u9690\u79c1\u653f\u7b56',
              onTap: () => _navigateTo(const PrivacyPolicyScreen()),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.description_outlined,
              title: '\u670d\u52a1\u6761\u6b3e',
              onTap: () => _navigateTo(const TermsOfServiceScreen()),
            ),
          ]),
          const SizedBox(height: 24),

          // ---- \u7b2c\u4e09\u7ec4\uff1a\u8d26\u53f7\u64cd\u4f5c ----
          _buildSettingsCard([
            _buildListTile(
              icon: Icons.swap_horiz,
              title: '\u5207\u6362\u8d26\u53f7',
              onTap: () => _navigateTo(const SwitchAccountScreen()),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.logout,
              title: '\u9000\u51fa\u767b\u5f55',
              isDestructive: true,
              onTap: _showLogoutDialog,
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---- \u5bfc\u822a ----
  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // ---- \u9000\u51fa\u767b\u5f55 ----
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '\u9000\u51fa\u767b\u5f55',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          '\u786e\u5b9a\u8981\u9000\u51fa\u767b\u5f55\u5417\uff1f',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('\u53d6\u6d88',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _performLogout();
            },
            child: const Text('\u786e\u5b9a',
                style: TextStyle(color: AppColors.accentRed)),
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
            content: Text('\u9000\u51fa\u767b\u5f55\u5931\u8d25: $e'),
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

  // ---- UI \u7ec4\u4ef6 ----
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: isDestructive ? AppColors.accentRed : AppColors.textSecondary,
          size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.accentRed : Colors.white,
          fontSize: 15,
          fontWeight: isDestructive ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDestructive
            ? AppColors.accentRed.withOpacity(0.6)
            : AppColors.textMuted,
        size: 20,
      ),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 28,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
          height: 0.5, color: AppColors.borderColor.withOpacity(0.5)),
    );
  }
}
