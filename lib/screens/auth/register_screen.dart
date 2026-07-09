import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';
import '../../theme/colors.dart';
import '../../services/auth_service.dart';
import '../../navigation/bottom_nav.dart';
import '../../widgets/religion_icon.dart';
import '../sidebar_pages/privacy_policy_screen.dart';
import '../sidebar_pages/terms_of_service_screen.dart';

const _rainbowColors = [
  Color(0xFFFF4D6D),
  Color(0xFFFF9F1C),
  Color(0xFFFFD60A),
  Color(0xFF70E000),
  Color(0xFF00E5FF),
  Color(0xFF3A86FF),
  Color(0xFF9D4EDD),
];

LinearGradient _diagonalGradient() {
  return LinearGradient(colors: _rainbowColors, transform: GradientRotation(0.785398));
}

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
      shaderCallback: (bounds) => _diagonalGradient().createShader(bounds),
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

  // FocusNode for each input field - fixes unstable gradient border
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _nicknameFocus = FocusNode();
  final _codeFocus = FocusNode();

  String _selectedFaithTag = '';
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;
  bool _codeSent = false;
  String _pendingEmail = '';
  bool _isAbove13 = false;
  bool _agreedToTerms = false;

  static const List<String> _faithTags = [
    '基督教', '伊斯兰教', '犹太教', '佛教', '印度教', '道教', '锡克教',
    '巴哈伊教', '摩门教', '耶和华见证人', '琐罗亚斯德教', '诺斯替',
    '卡巴拉', '神道教', '耆那教', '德鲁兹教', '伏都教',
    '雅兹迪', '曼达安', '玛雅/阿兹特克', '毛利宗教', '天理教', '天道教',
    '高台教', '宗教研究者', '经文爱好者', '寻求者',
  ];

  @override
  void initState() {
    super.initState();
    // Add listeners so setState triggers on every focus change
    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _nicknameFocus.addListener(_onFocusChange);
    _codeFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_onFocusChange);
    _passwordFocus.removeListener(_onFocusChange);
    _nicknameFocus.removeListener(_onFocusChange);
    _codeFocus.removeListener(_onFocusChange);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nicknameFocus.dispose();
    _codeFocus.dispose();
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
    if (!_agreedToTerms) { setState(() => _error = '请阅读并同意隐私政策和用户协议'); return; }

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

  /// 七彩渐变勾选标记 Checkbox（细白框 + 粗渐变勾选标记）
  Widget _buildGradientCheckbox({required bool value}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white, width: 0.8),
      ),
      child: value
          ? ShaderMask(
              shaderCallback: (bounds) => _diagonalGradient().createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: const Icon(Icons.check, size: 14, color: Colors.white, weight: 900),
            )
          : null,
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _GradientText(text: 'Sign Up', fontSize: 24),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _diagonalGradient(),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFF4D6D).withOpacity(0.1), blurRadius: 30, spreadRadius: 0),
                          BoxShadow(color: const Color(0xFF3A86FF).withOpacity(0.08), blurRadius: 60, spreadRadius: 0),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFF050816).withOpacity(0.97),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_codeSent) _buildStep1Form() else _buildStep2Form(),

                            const SizedBox(height: 16),

                            if (!_codeSent) ...[
                              Text('已有账号？',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text('立即登录',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
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
        _buildInput(controller: _emailCtrl, label: '邮箱', hint: '请输入邮箱...', focusNode: _emailFocus),
        const SizedBox(height: 12),

        _buildInput(controller: _passwordCtrl, label: '密码', hint: '请输入密码（至少8位）...',
            obscure: _obscure1, focusNode: _passwordFocus,
            suffix: IconButton(
              icon: Icon(_obscure1 ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.45), size: 18),
              onPressed: () => setState(() => _obscure1 = !_obscure1),
            )),
        const SizedBox(height: 12),

        _buildInput(controller: _nicknameCtrl, label: '昵称', hint: '请输入昵称...', focusNode: _nicknameFocus),
        const SizedBox(height: 12),

        _buildFaithTagDropdown(),
        const SizedBox(height: 12),

        // 年满13周岁 checkbox
        GestureDetector(
          onTap: () { setState(() => _isAbove13 = !_isAbove13); _error = null; },
          child: Row(
            children: [
              _buildGradientCheckbox(value: _isAbove13),
              const SizedBox(width: 6),
              Expanded(
                child: Text('我已年满13周岁',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 同意条款 checkbox
        GestureDetector(
          onTap: () { setState(() => _agreedToTerms = !_agreedToTerms); _error = null; },
          child: Row(
            children: [
              _buildGradientCheckbox(value: _agreedToTerms),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                    children: [
                      const TextSpan(text: '我已阅读并同意 '),
                      TextSpan(
                        text: '隐私政策',
                        style: TextStyle(
                          color: const Color(0xFF3A86FF).withOpacity(0.8),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                        },
                      ),
                      const TextSpan(text: ' 和 '),
                      TextSpan(
                        text: '用户协议',
                        style: TextStyle(
                          color: const Color(0xFF3A86FF).withOpacity(0.8),
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_error != null) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
            ),
            child: Text(_error!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
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
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _diagonalGradient(),
          ),
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF050816),
            ),
            child: const Icon(Icons.email_outlined, color: Color(0xFF3A86FF), size: 28),
          ),
        ),
        const SizedBox(height: 12),

        const Text('验证码已发送',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('请输入发送至 $_pendingEmail 的6位验证码',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        const SizedBox(height: 16),

        _buildInput(controller: _codeCtrl, label: '验证码', hint: '请输入6位验证码',
            focusNode: _codeFocus, textAlign: TextAlign.center),
        const SizedBox(height: 12),

        if (_error != null) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
            ),
            child: Text(_error!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
          ),
        ],

        _buildVerifyButton(),
        const SizedBox(height: 12),

        TextButton(
          onPressed: () => setState(() { _codeSent = false; _error = null; }),
          child: Text('← 返回修改信息',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildFaithTagDropdown() {
    final isSelected = _selectedFaithTag.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            children: [
              const TextSpan(text: '身份标签 '),
              TextSpan(text: '*', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _showTagPicker(),
          child: Container(
            padding: EdgeInsets.all(isSelected ? 2 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isSelected ? _diagonalGradient() : null,
              border: !isSelected
                  ? Border.all(color: Colors.white.withOpacity(0.12), width: 1)
                  : null,
            ),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isSelected ? 10 : 11),
                color: isSelected
                    ? AppColors.background.withOpacity(0.9)
                    : Colors.white.withOpacity(0.06),
              ),
              child: Row(
                children: [
                  if (_selectedFaithTag.isNotEmpty) ...[
                    ReligionIconWidget(name: _selectedFaithTag, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      _selectedFaithTag.isEmpty ? '请选择身份标签...' : _selectedFaithTag,
                      style: TextStyle(
                        color: _selectedFaithTag.isEmpty
                            ? Colors.white.withOpacity(0.35)
                            : Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.45), size: 18),
                ],
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
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选择身份标签',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _faithTags.length,
                  itemBuilder: (ctx, i) {
                    final tag = _faithTags[i];
                    final selected = tag == _selectedFaithTag;
                    return ListTile(
                      leading: ReligionIconWidget(name: tag, size: 20),
                      title: Text(tag,
                          style: TextStyle(color: selected ? Colors.white : Colors.white.withOpacity(0.8), fontSize: 13)),
                      trailing: selected
                          ? const Icon(Icons.check, color: Color(0xFF70E000), size: 18)
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: _diagonalGradient(),
      ),
      child: SizedBox(
        height: 42,
        width: double.infinity,
        child: TextButton(
          onPressed: _loading ? () {} : _handleRegister,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF050816).withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(_loading ? '发送中...' : '获取验证码',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: _diagonalGradient(),
      ),
      child: SizedBox(
        height: 42,
        child: TextButton(
          onPressed: _loading ? () {} : _verifyCode,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF050816).withOpacity(0.95),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(_loading ? '验证中...' : '完成注册',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscure = false,
    required FocusNode focusNode,
    Widget? suffix,
    TextAlign textAlign = TextAlign.start,
  }) {
    final isFocused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isFocused ? _diagonalGradient() : null,
            border: !isFocused
                ? Border.all(color: Colors.white.withOpacity(0.12), width: 1)
                : null,
          ),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFF050816),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscure,
              textAlign: textAlign,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
                suffixIcon: suffix,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
        ),
      ],
    );
  }
}
