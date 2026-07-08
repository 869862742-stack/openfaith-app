import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../services/auth_service.dart';
import '../../navigation/bottom_nav.dart';

const LinearGradient _rainbowGradient = LinearGradient(
  colors: [
    Color(0xFFFF4D6D),
    Color(0xFFFF9F1C),
    Color(0xFFFFD60A),
    Color(0xFF70E000),
    Color(0xFF00E5FF),
    Color(0xFF3A86FF),
    Color(0xFF9D4EDD),
  ],
  transform: GradientRotation(0.125),
);

/// 七彩渐变文字（aurora-text 效果）
class _GradientText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  const _GradientText({
    required this.text,
    required this.fontSize,
    this.fontWeight = FontWeight.bold,
  });
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => _rainbowGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _emailCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String _selectedFaithTag = '';
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;
  bool _codeSent = false;
  String _pendingEmail = '';
  String? _focusedField;
  bool _isAbove13 = false;
  bool _agreedToTerms = false;

  static const List<String> _faithTags = [
    '基督教', '伊斯兰教', '犹太教', '佛教', '印度教', '道教', '锡克教',
    '巴哈伊教', '摩门教', '耶和华见证人', '琐罗亚斯德教', '诺斯底教',
    '卡拉巴教', '神道教', '耆那教', '德鲁兹教', '红巴教', '伏都教',
    '雅兹迪教', '曼达安教', '玛雅/阿兹特克', '毛利宗教', '天理教', '天道教',
    '高台教', '宗教研究者', '经文爱好者', '寻求者',
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nicknameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailCtrl.text.trim();
    final nickname = _nicknameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmCtrl.text;

    if (email.isEmpty) { setState(() => _error = '请输入邮箱'); return; }
    if (nickname.isEmpty) { setState(() => _error = '请输入昵称'); return; }
    if (_selectedFaithTag.isEmpty) { setState(() => _error = '请选择身份标签'); return; }
    if (password.length < 8) { setState(() => _error = '密码至少8位'); return; }
    if (password != confirmPassword) { setState(() => _error = '两次密码不一致'); return; }
    if (!_isAbove13) { setState(() => _error = '您必须年满13周岁才能注册'); return; }
    if (!_agreedToTerms) { setState(() => _error = '请阅读并同意隐私政策和服务条款'); return; }

    setState(() { _loading = true; _error = null; });
    try {
      await _authService.signUp(
        email, password,
        nickname: nickname,
        faithTag: _selectedFaithTag,
        username: email.split('@').first,
      );
      setState(() {
        _codeSent = true;
        _pendingEmail = email;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) { setState(() => _error = '请输入验证码'); return; }

    setState(() { _loading = true; _error = null; });
    try {
      await _authService.verifyOTP(_pendingEmail, code);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a15),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF050816), Color(0xFF0a0a15)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _GradientText(text: 'OpenFaith', fontSize: 30),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _rainbowGradient,
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFF4D6D).withOpacity(0.1), blurRadius: 30, spreadRadius: 0),
                          BoxShadow(color: const Color(0xFF3A86FF).withOpacity(0.08), blurRadius: 60, spreadRadius: 0),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFF050816).withOpacity(0.97),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _GradientText(text: '注册', fontSize: 20, fontWeight: FontWeight.w600),
                            const SizedBox(height: 24),

                            if (!_codeSent) _buildStep1Form() else _buildStep2Form(),

                            const SizedBox(height: 24),

                            if (!_codeSent) ...[
                              Text('已有账号？',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12), gradient: _rainbowGradient),
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFF050816).withOpacity(0.95),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  ),
                                  child: const Text('立即登录',
                                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInput(controller: _emailCtrl, label: '邮箱', hint: '请输入邮箱...', fieldKey: 'regEmail'),
        const SizedBox(height: 16),

        _buildInput(controller: _passwordCtrl, label: '密码', hint: '请输入密码（至少8位）...',
            obscure: _obscure1, fieldKey: 'regPassword',
            suffix: IconButton(
              icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.45), size: 20),
              onPressed: () => setState(() => _obscure1 = !_obscure1),
            )),
        const SizedBox(height: 16),

        _buildInput(controller: _nicknameCtrl, label: '昵称', hint: '请输入昵称...', fieldKey: 'regNickname'),
        const SizedBox(height: 16),

        _buildFaithTagDropdown(),
        const SizedBox(height: 16),

        Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: Checkbox(
                value: _isAbove13,
                onChanged: (v) { setState(() => _isAbove13 = v ?? false); _error = null; },
                activeColor: const Color(0xFF3A86FF),
                side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('我已年满13周岁',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (v) { setState(() => _agreedToTerms = v ?? false); _error = null; },
                activeColor: const Color(0xFF3A86FF),
                side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    children: [
                      const TextSpan(text: '我已阅读并同意'),
                      TextSpan(text: '隐私政策', style: TextStyle(color: const Color(0xFF3A86FF).withOpacity(0.8))),
                      const TextSpan(text: '和'),
                      TextSpan(text: '服务条款', style: TextStyle(color: const Color(0xFF3A86FF).withOpacity(0.8))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_error != null) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
            ),
            child: Text(_error!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ),
        ],

        _buildRegisterButton(),
      ],
    );
  }

  Widget _buildStep2Form() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _rainbowGradient,
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF050816),
            ),
            child: const Icon(Icons.email_outlined, color: Color(0xFF3A86FF), size: 32),
          ),
        ),
        const SizedBox(height: 16),

        const Text('验证码已发送',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('请输入发送至 $_pendingEmail 的6位验证码',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        const SizedBox(height: 24),

        _buildInput(controller: _codeCtrl, label: '验证码', hint: '请输入6位验证码',
            fieldKey: 'verifyCode', textAlign: TextAlign.center),
        const SizedBox(height: 16),

        if (_error != null) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
            ),
            child: Text(_error!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ),
        ],

        _buildVerifyButton(),
        const SizedBox(height: 16),

        TextButton(
          onPressed: () => setState(() { _codeSent = false; _error = null; }),
          child: Text('← 返回修改信息',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildFaithTagDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            children: [
              const TextSpan(text: '身份标签 '),
              TextSpan(text: '*', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showTagPicker(),
          child: Focus(
            onFocusChange: (hasFocus) {
              setState(() => _focusedField = hasFocus ? 'regTag' : null);
            },
            child: Container(
              padding: EdgeInsets.all(_focusedField == 'regTag' ? 2 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _focusedField == 'regTag' ? _rainbowGradient : null,
                border: _focusedField != 'regTag'
                    ? Border.all(color: Colors.white.withOpacity(0.12), width: 1)
                    : null,
              ),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_focusedField == 'regTag' ? 10 : 11),
                  color: _focusedField == 'regTag'
                      ? AppColors.background.withOpacity(0.9)
                      : Colors.white.withOpacity(0.06),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedFaithTag.isEmpty ? '请选择身份标签...' : _selectedFaithTag,
                        style: TextStyle(
                          color: _selectedFaithTag.isEmpty
                              ? Colors.white.withOpacity(0.35)
                              : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down,
                        color: Colors.white.withOpacity(0.45), size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050816).withOpacity(0.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选择身份标签',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _faithTags.length,
                  itemBuilder: (ctx, i) {
                    final tag = _faithTags[i];
                    final selected = tag == _selectedFaithTag;
                    return ListTile(
                      title: Text(tag,
                          style: TextStyle(color: selected ? Colors.white : Colors.white.withOpacity(0.8), fontSize: 14)),
                      trailing: selected
                          ? const Icon(Icons.check, color: Color(0xFF70E000), size: 20)
                          : null,
                      onTap: () {
                        setState(() => _selectedFaithTag = tag);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: _rainbowGradient),
      child: SizedBox(
        height: 44,
        child: TextButton(
          onPressed: _loading ? () {} : _handleRegister,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF050816).withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(_loading ? '发送中...' : '获取验证码',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: _rainbowGradient),
      child: SizedBox(
        height: 48,
        child: TextButton(
          onPressed: _loading ? () {} : _verifyCode,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF050816).withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(_loading ? '验证中...' : '完成注册',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    required String fieldKey,
    Widget? suffix,
    TextAlign textAlign = TextAlign.start,
  }) {
    final isFocused = _focusedField == fieldKey;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height: 4),
        Focus(
          onFocusChange: (hasFocus) {
            setState(() => _focusedField = hasFocus ? fieldKey : null);
          },
          child: Container(
            padding: EdgeInsets.all(isFocused ? 2 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isFocused ? _rainbowGradient : null,
              border: !isFocused
                  ? Border.all(color: Colors.white.withOpacity(0.12), width: 1)
                  : null,
              boxShadow: isFocused
                  ? [BoxShadow(color: const Color(0xFFFF4D6D).withOpacity(0.15), blurRadius: 12, spreadRadius: 0)]
                  : null,
            ),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isFocused ? 10 : 11),
                color: isFocused
                    ? AppColors.background.withOpacity(0.9)
                    : Colors.white.withOpacity(0.06),
              ),
              child: TextField(
                controller: controller,
                obscureText: obscure,
                textAlign: textAlign,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
                  suffixIcon: suffix,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
