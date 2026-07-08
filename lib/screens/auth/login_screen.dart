import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  String? _error;
  bool _loading = false;

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? true;
    if (mounted) setState(() => _rememberMe = remember);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }  static const _rainbowColors = [


    Color(0xFFFF4D6D),


    Color(0xFFFF9F1C),


    Color(0xFFFFD60A),


    Color(0xFF70E000),


    Color(0xFF00E5FF),


    Color(0xFF3A86FF),


    Color(0xFF9D4EDD),
  ];

  LinearGradient _diagonalGradient(Size size) {
    final angle = size.height > 0 && size.width > 0 ? atan2(size.width, size.height) : 0.785;
    return LinearGradient(colors: _rainbowColors, transform: GradientRotation(angle));
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = '请输入邮箱和密码');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);
      if (_rememberMe) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await prefs.setString('user_id', user.id);
          await prefs.setString('user_token', user.id);
        }
      } else {
        await prefs.remove('user_id');
        await prefs.remove('user_token');
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    final emailFocusNode = FocusNode();
    final codeFocusNode = FocusNode();
    final newPwdFocusNode = FocusNode();
    int step = 0;
    String? errorMsg;
    bool resetting = false;
    StateSetter? dialogSetter;

    emailFocusNode.addListener(() { if (dialogSetter != null) dialogSetter!(() {}); });
    codeFocusNode.addListener(() { if (dialogSetter != null) dialogSetter!(() {}); });
    newPwdFocusNode.addListener(() { if (dialogSetter != null) dialogSetter!(() {}); });

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          dialogSetter = setDialogState;
          return Dialog(
            backgroundColor: const Color(0xFF161B2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 标题
                  Text(
                    step == 0 ? '找回密码' : step == 1 ? '输入验证码' : '设置新密码',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 错误提示
                  if (errorMsg != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Text(errorMsg!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Step 0: 输入邮箱
                  if (step == 0) ...[
                    _buildWebInput(
                      controller: emailCtrl,
                      focusNode: emailFocusNode,
                      hint: '请输入注册邮箱',
                    ),
                    const SizedBox(height: 16),
                    // 七彩渐变边框按钮
                    _rainbowBorderBox(
                      borderRadius: 10,
                      child: SizedBox(
                        height: 46,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: resetting ? null : () async {
                              setDialogState(() {
                                errorMsg = null;
                                resetting = true;
                              });
                              try {
                                if (emailCtrl.text.trim().isEmpty || !emailCtrl.text.contains('@')) {
                                  setDialogState(() { errorMsg = '请输入有效的邮箱地址'; resetting = false; });
                                  return;
                                }
                                await _authService.sendPasswordReset(emailCtrl.text.trim());
                                setDialogState(() { step = 1; resetting = false; });
                              } catch (e) {
                                setDialogState(() {
                                  errorMsg = e.toString().replaceAll('Exception: ', '');
                                  resetting = false;
                                });
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                resetting ? '发送中...' : '发送验证码',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 辅助文字
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Text(
                        '验证码将发送至您的注册邮箱，有效期60秒',
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  // Step 1: 输入验证码
                  if (step == 1) ...[
                    Text(
                      '验证码已发送至 ${emailCtrl.text}',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    _buildWebInput(
                      controller: codeCtrl,
                      focusNode: codeFocusNode,
                      hint: '请输入6位验证码',
                    ),
                    const SizedBox(height: 16),
                    _rainbowBorderBox(
                      borderRadius: 10,
                      child: SizedBox(
                        height: 46,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: resetting ? null : () async {
                              setDialogState(() {
                                errorMsg = null;
                                resetting = true;
                              });
                              try {
                                if (codeCtrl.text.trim().length < 4) {
                                  setDialogState(() { errorMsg = '请输入验证码'; resetting = false; });
                                  return;
                                }
                                await _authService.verifyResetOTP(emailCtrl.text.trim(), codeCtrl.text.trim());
                                setDialogState(() { step = 2; resetting = false; });
                              } catch (e) {
                                setDialogState(() {
                                  errorMsg = e.toString().replaceAll('Exception: ', '');
                                  resetting = false;
                                });
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                resetting ? '验证中...' : '验证',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  // Step 2: 设置新密码
                  if (step == 2) ...[
                    _buildWebInput(
                      controller: newPwdCtrl,
                      focusNode: newPwdFocusNode,
                      hint: '请输入新密码（至少6个字符）',
                      obscure: true,
                    ),
                    const SizedBox(height: 16),
                    _rainbowBorderBox(
                      borderRadius: 10,
                      child: SizedBox(
                        height: 46,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: resetting ? null : () async {
                              setDialogState(() {
                                errorMsg = null;
                                resetting = true;
                              });
                              try {
                                if (newPwdCtrl.text.length < 6) {
                                  setDialogState(() { errorMsg = '密码至少需要6个字符'; resetting = false; });
                                  return;
                                }
                                await _authService.updatePassword(newPwdCtrl.text);
                                if (!mounted) return;
                                Navigator.pop(dialogCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('密码重置成功，请重新登录'), backgroundColor: AppColors.inputBg),
                                );
                              } catch (e) {
                                setDialogState(() {
                                  errorMsg = e.toString().replaceAll('Exception: ', '');
                                  resetting = false;
                                });
                              }
                            },
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                resetting ? '重置中...' : '重置密码',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // 取消按钮
                  InkWell(
                    onTap: () => Navigator.pop(dialogCtx),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 网页版风格输入框（无label，placeholder风格，聚焦时彩虹边框）
  Widget _buildWebInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    bool obscure = false,
  }) {
    final isFocused = focusNode.hasFocus;
    return LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Container(
      height: 46,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: isFocused ? _diagonalGradient(size) : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color: const Color(0xFF1A1F35),
          border: isFocused ? null : Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            isDense: true,
          ),
          onTapOutside: (event) => focusNode.unfocus(),
        ),
      ),
    );
    });
  }

  // 七彩渐变边框包裹器（外层1px渐变+内层黑底）
  Widget _rainbowBorderBox({required Widget child, double borderRadius = 8}) {
    return LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: _diagonalGradient(size),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius - 1),
          color: const Color(0xFF050816),
        ),
        child: child,
      ),
    );
    });
  }

  Widget _buildInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    bool obscure = false,
  }) {
    final isFocused = focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        // 七彩渐变边框包裹器（聚焦时显示彩虹边框，padding始终1px避免尺寸跳动）
        LayoutBuilder(builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Container(
          height: 36,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: isFocused ? _diagonalGradient(size) : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: const Color(0xFF050816),
              border: isFocused ? null : Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscure,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              onTapOutside: (event) => focusNode.unfocus(),
            ),
          ),
        );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildInput(controller: _emailController, focusNode: _emailFocusNode, label: '邮箱', hint: '请输入邮箱...'),
        const SizedBox(height: 12),
        _buildInput(controller: _passwordController, focusNode: _passwordFocusNode, label: '密码', hint: '请输入密码...', obscure: true),
        const SizedBox(height: 12),
        // 记住我 - 小对勾 + 七彩渐变边框（无填充色）
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              _rainbowBorderBox(
                borderRadius: 3,
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: _rememberMe
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text('记住我（30天）', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
        ],
        const SizedBox(height: 14),
        // 登录按钮 - 七彩渐变边框 + 黑底（无渐变填充）
        _rainbowBorderBox(
          borderRadius: 8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _loading ? null : _login,
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                height: 36,
                child: Center(
                  child: _loading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('登录', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: _showForgotPassword,
            child: Text('忘记密码？', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
          ),
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: Colors.white.withOpacity(0.06)),
        const SizedBox(height: 14),
        Center(
          child: Column(
            children: [
              Text('还没有账号？', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
              const SizedBox(height: 6),
              // 注册按钮 - 七彩渐变边框 + 黑底（无渐变填充）
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                child: _rainbowBorderBox(
                  borderRadius: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: const Text('立即注册', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // 卡片 - 七彩渐变边框 + 黑底
    final card = LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: _diagonalGradient(size)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: const Color(0xFF050816)),
        child: cardContent,
      ),
    );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF050816),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(width: 240, child: card),
        ),
      ),
    );
  }
}
