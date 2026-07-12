import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/colors.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _supabase = Supabase.instance.client;

  String _phone = '';
  String _email = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email ?? '';
      });
      // Try to load profile for phone
      try {
        final resp = await _supabase
            .from('profiles')
            .select('phone')
            .eq('id', user.id)
            .maybeSingle();
        if (resp != null && resp['phone'] != null) {
          if (mounted) setState(() => _phone = resp['phone'] as String);
        }
      } catch (_) {}
    }
  }

  String get _maskedPhone {
    if (_phone.isEmpty) return '未绑定';
    if (_phone.length >= 7) {
      return '${_phone.substring(0, 3)}****${_phone.substring(_phone.length - 4)}';
    }
    return _phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.headerBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('账号与安全',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSecurityBanner(),
          const SizedBox(height: 24),
          _buildMenuItem(
            icon: Icons.smartphone_outlined,
            label: '手机号',
            value: _maskedPhone,
            onTap: () => _showPhoneModal(),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.mail_outline,
            label: '邮箱号',
            value: _email.isEmpty ? '未设置' : _email,
            onTap: () => _showEmailModal(),
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            icon: Icons.lock_outline,
            label: '登录密码',
            value: '已设置',
            onTap: () => _showPasswordModal(),
          ),
          const SizedBox(height: 12),
          _buildDeleteMenuItem(),
        ],
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0x14FFFFFF), // rgba(255,255,255,0.08)
            const Color(0x0AFFFFFF), // rgba(255,255,255,0.04)
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (rect) =>
                    AppColors.auroraGradient.createShader(rect),
                child: const Icon(Icons.shield_outlined,
                    color: AppColors.textPrimary, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                '安全保护已开启',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = AppColors.auroraGradient
                        .createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '您的账号正在受到 OpenFaith 加密盾的实时保护。建议定期修改密码并保持手机/邮箱可用。',
            style: TextStyle(
              fontSize: 12,
              color: Color.fromRGBO(255, 255, 255, 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.hoverBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textWeak, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteMenuItem() {
    return GestureDetector(
      onTap: () => _showDeleteModal(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.hoverBgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 16),
            const Expanded(
              child: Text('注销账号',
                  style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textPlaceholder, size: 20),
          ],
        ),
      ),
    );
  }

  // ========== Modals ==========

  void _showPhoneModal() {
    final phoneController = TextEditingController(text: _phone);
    final codeController = TextEditingController();
    int countdown = 0;

    void sendCode() {
      if (phoneController.text.length != 11 || countdown > 0) return;
      final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
          .toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('验证码已发送到手机：$code'),
            backgroundColor: AppColors.cardBg),
      );
      countdown = 60;
      // Trigger rebuild via setState on parent
      setState(() {});
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('绑定手机号',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '请输入手机号',
                  hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '请输入验证码',
                        hintStyle:
                            const TextStyle(color: AppColors.textPlaceholder),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderColor),
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        sendCode();
                        setModalState(() {});
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.hoverBg,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        countdown > 0 ? '${countdown}s' : '获取验证码',
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.auroraGradient,
                  ),
                  child: TextButton(
                    onPressed: () {
                      if (phoneController.text.length != 11 ||
                          codeController.text.length != 6) return;
                      setState(() => _phone = phoneController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('手机号绑定成功'),
                            backgroundColor: AppColors.success),
                      );
                      Navigator.pop(ctx);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('绑定',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmailModal() {
    final emailController = TextEditingController(text: _email);
    final codeController = TextEditingController();
    int countdown = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('修改邮箱',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '请输入新邮箱',
                  hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '请输入验证码',
                        hintStyle:
                            const TextStyle(color: AppColors.textPlaceholder),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderColor),
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        if (countdown > 0 ||
                            !emailController.text.contains('@')) return;
                        final code =
                            (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
                                .toString();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('验证码已发送到邮箱：$code'),
                              backgroundColor: AppColors.cardBg),
                        );
                        countdown = 60;
                        setModalState(() {});
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.hoverBg,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        countdown > 0 ? '${countdown}s' : '获取验证码',
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.auroraGradient,
                  ),
                  child: TextButton(
                    onPressed: () {
                      if (!emailController.text.contains('@') ||
                          codeController.text.length != 6) return;
                      setState(() => _email = emailController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('邮箱更新成功'),
                            backgroundColor: AppColors.success),
                      );
                      Navigator.pop(ctx);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('保存',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordModal() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final codeController = TextEditingController();
    int countdown = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('修改密码',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Verification code
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '请输入验证码',
                        hintStyle:
                            const TextStyle(color: AppColors.textPlaceholder),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderColor),
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        if (countdown > 0) return;
                        final code =
                            (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
                                .toString();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('验证码已发送到邮箱：$code'),
                              backgroundColor: AppColors.cardBg),
                        );
                        countdown = 60;
                        setModalState(() {});
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.hoverBg,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        countdown > 0 ? '${countdown}s' : '获取验证码',
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // New password
              TextField(
                controller: newPasswordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '请输入新密码',
                  hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Confirm password
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '请确认新密码',
                  hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppColors.auroraGradient,
                  ),
                  child: TextButton(
                    onPressed: () {
                      if (codeController.text.length != 6 ||
                          newPasswordController.text.length < 6 ||
                          newPasswordController.text !=
                              confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('请检查输入信息'),
                              backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('密码修改成功'),
                            backgroundColor: AppColors.success),
                      );
                      Navigator.pop(ctx);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('确认修改',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.overlayBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text('注销账号',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = AppColors.auroraGradient
                        .createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                )),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(ctx),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 7-day cooling period badge
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text('7天冷静期',
                      style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Text(
              '注销账号后，您的所有数据将被永久删除。点击确认后，账号将进入7天冷静期，期间登录将自动取消注销。超过7天未登录，账号将被永久注销。',
              style: TextStyle(
                fontSize: 14,
                color: Color.fromRGBO(255, 255, 255, 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.inputBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('取消',
                style: TextStyle(
                    color: AppColors.textWeak, fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.auroraGradient,
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('账号注销申请已提交，7天冷静期内登录将自动取消注销'),
                        backgroundColor: AppColors.warning),
                  );
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('确认注销',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
