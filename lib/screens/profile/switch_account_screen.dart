import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SwitchAccountScreen extends StatefulWidget {
  const SwitchAccountScreen({super.key});

  @override
  State<SwitchAccountScreen> createState() => _SwitchAccountScreenState();
}

class _SwitchAccountScreenState extends State<SwitchAccountScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('user_id', session!.user.id)
            .maybeSingle();
        if (mounted) {
          setState(() {
            _profile = response as Map<String, dynamic>?;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('SwitchAccount fetch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _currentName => _profile?['username'] as String? ?? 'OpenFaith';
  String get _currentEmail => _profile?['email'] as String? ?? '未绑定邮箱';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('切换账号',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.auroraBlue))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('当前及已关联账号', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          _buildCurrentAccountCard(),
          const SizedBox(height: 24),
          _buildAddAccountButton(),
          const SizedBox(height: 24),
          _buildSecurityNotice(),
        ],
      ),
    );
  }

  Widget _buildCurrentAccountCard() {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [
          Color(0xFFFF4D6D), Color(0xFFFF9F1C), Color(0xFFFFD60A),
          Color(0xFF70E000), Color(0xFF00E5FF), Color(0xFF3A86FF), Color(0xFF9D4EDD),
        ]),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF3A86FF), Color(0xFF9D4EDD)]),
                ),
                child: Center(
                  child: Text(_currentName.isNotEmpty ? _currentName[0].toUpperCase() : 'O',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                bottom: -2, right: -2,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF70E000), Color(0xFF00E5FF)]),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(_currentName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(colors: [Color(0xFF3A86FF), Color(0xFF9D4EDD)]),
                    ),
                    child: const Text('CURRENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(_currentEmail, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAccountButton() {
    return GestureDetector(
      onTap: () {
        Supabase.instance.client.auth.signOut();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      },
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text('添加新账号', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.shield_outlined, color: AppColors.auroraBlue, size: 16),
          const SizedBox(width: 8),
          Text('账号安全提示', style: TextStyle(color: AppColors.auroraBlue, fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        Text('切换账号功能方便您在多个身份间快速跳转。请确保所有关联账号均为本人使用，以保护您的灵性成长数据与个人隐私。',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
      ]),
    );
  }
}
