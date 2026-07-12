import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'package:openfaith_app/widgets/aurora_button.dart';
import 'test_helper.dart';


/// Auth Pages Extended Golden Tests
/// Covers: login, register with more detail

// ─── Common Header ───
Widget _buildHeader(String title, {bool showBack = true}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    child: SafeArea(
      bottom: false,
      child: Row(
        children: [
          if (showBack) ...[
            const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 12),
          ],
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}

// ─── Glass Header (centered title) ───
Widget _buildGlassHeader(String title) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.headerBg,
      border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
    ),
    child: SafeArea(
      bottom: false,
      child: Center(
        child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}

// ─── Settings List Card ───
Widget _buildSettingsCard(IconData icon, String title, {bool destructive = false, String? subtitle, bool showArrow = true}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(
      children: [
        Icon(icon, color: destructive ? AppColors.error : AppColors.textSecondary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: destructive ? AppColors.error : Colors.white, fontSize: 15)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
              ],
            ],
          ),
        ),
        if (showArrow) const Icon(Icons.chevron_right, color: AppColors.textWeak, size: 20),
      ],
    ),
  );
}

// ─── Toggle Card ───
Widget _buildToggleCard(String title, bool enabled) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderColor, width: 0.5),
    ),
    child: Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15))),
        Switch(value: enabled, onChanged: (_) {}, activeColor: AppColors.auroraBlue),
      ],
    ),
  );
}

// ─── Search Bar ───
Widget _buildSearchBar() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.inputBg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.search, color: AppColors.textPlaceholder, size: 20),
        SizedBox(width: 8),
        Expanded(child: Text('搜索...', style: TextStyle(color: AppColors.textPlaceholder, fontSize: 14))),
      ],
    ),
  );
}

// ─── Input Field ───
Widget _buildInput(String hint, IconData icon, {bool obscure = false}) {
  return TextField(
    obscureText: obscure,
    enabled: false,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textPlaceholder),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.inputBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

// ─── Post Card ───
Widget _buildPostCard({
  required String authorName,
  required String avatarLetter,
  required List<Color> avatarGradient,
  required String faithTag,
  required String timeAgo,
  required String content,
  required int likes,
  required int comments,
  required int shares,
}) {
  return GlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: avatarGradient)),
                child: Center(child: Text(avatarLetter, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authorName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(gradient: AppColors.auroraGradientWithOpacity(0.3), borderRadius: BorderRadius.circular(6)),
                        child: Text(faithTag, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Text(timeAgo, style: const TextStyle(color: AppColors.textWeak, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          Row(children: [
            _actionIcon(Icons.favorite_border, '$likes'),
            const SizedBox(width: 24),
            _actionIcon(Icons.chat_bubble_outline, '$comments'),
            const SizedBox(width: 24),
            _actionIcon(Icons.share_outlined, '$shares'),
          ]),
        ],
      ),
    ),
  );
}

Widget _actionIcon(IconData icon, String count) {
  return Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: AppColors.iconColorWeak, size: 18),
    const SizedBox(width: 4),
    Text(count, style: const TextStyle(color: AppColors.textWeak, fontSize: 13)),
  ]);
}

// ─── Tab Bar ───
Widget _buildTabBar(List<String> tabs, int activeIndex) {
  return Container(
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5))),
    child: Row(
      children: List.generate(tabs.length, (i) {
        final isActive = i == activeIndex;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(border: isActive ? Border(bottom: BorderSide(color: AppColors.auroraBlue, width: 2)) : null),
            child: Center(child: Text(tabs[i], style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontSize: 15, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400))),
          ),
        );
      }),
    ),
  );
}

// ─── Bottom Nav ───
Widget _buildBottomNav(int activeIndex) {
  final items = [
    [Icons.home_outlined, Icons.home, '首页'],
    [Icons.explore_outlined, Icons.explore, '学习'],
    [null, null, null], // publish button
    [Icons.notifications_outlined, Icons.notifications, '消息'],
    [Icons.person_outline, Icons.person, '我的'],
  ];
  return Container(
    decoration: BoxDecoration(color: AppColors.navBg, border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5))),
    child: SafeArea(top: false, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8).copyWith(top: 2, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          if (item[0] == null) {
            return Transform.translate(offset: const Offset(0, -8), child: Container(
              width: 40, height: 40, padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.auroraColors)),
              child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bgSecondarySolid), child: const Center(child: Icon(Icons.add, color: Colors.white, size: 20))),
            ));
          }
          final idx = items.indexOf(item);
          final isActive = idx == activeIndex;
          return ConstrainedBox(constraints: const BoxConstraints(minWidth: 50), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(isActive ? item[1] as IconData : item[0] as IconData, size: 20, color: isActive ? Colors.white : AppColors.iconColorWeak),
              const SizedBox(height: 2),
              Text(item[2] as String, style: TextStyle(fontSize: 10, color: isActive ? AppColors.textPrimary : AppColors.iconColorWeak)),
            ]),
          ));
        }).toList(),
      ),
    )),
  );
}

// ─── Empty State ───
Widget _buildEmptyState(String title, String subtitle) {
  return Center(child: Padding(padding: const EdgeInsets.all(48), child: Column(children: [
    Icon(Icons.inbox_outlined, color: AppColors.textWeak, size: 48),
    const SizedBox(height: 16),
    Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    Text(subtitle, style: const TextStyle(color: AppColors.textWeak, fontSize: 13)),
  ])));
}


void main() {
  group('Auth Extended Golden Tests', () {

    testWidgets('Login page full render', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildLogin()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_login.png'));
    });

    testWidgets('Register page full render', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildRegister()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_register.png'));
    });
  });
}

Widget _buildLogin() {
  return Scaffold(
    backgroundColor: const Color(0xFF050816),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildLoginRainbowCard(
            borderRadius: 16,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Title
              Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: const Text('登录', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
              // Email input
              Text('邮箱', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              const SizedBox(height: 8),
              _buildLoginInput('请输入邮箱...'),
              const SizedBox(height: 20),
              // Password input
              Text('密码', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              const SizedBox(height: 8),
              _buildLoginInput('请输入密码...', obscure: true),
              const SizedBox(height: 20),
                // Remember me checkbox
                Row(children: [
                  Container(width: 16, height: 16, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.white, width: 0.8)),
                    child: const Icon(Icons.check, color: Colors.white, size: 14)),
                  const SizedBox(width: 8),
                  Text('记住登录状态（30天）', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
                ]),
                const SizedBox(height: 14),
                // Login button - rainbow gradient border + dark bg
                _buildLoginRainbowBtn('登录', height: 48),
                const SizedBox(height: 24),
                // Forgot password
                Center(child: Text('忘记密码？', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4)))),
                const SizedBox(height: 24),
                // Divider
                Container(height: 1, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 24),
                // Register section
                Center(child: Column(children: [
                  Text('还没有账号？', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), border: Border.all(color: Colors.white.withOpacity(0.15), width: 1)),
                    child: const Text('立即注册', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ])),
              ]),
            ),
          ),
        ),
      ),
    );
}

// ─── Login/Register Rainbow Border Helpers ───
Widget _buildLoginRainbowCard({required double borderRadius, required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(borderRadius), gradient: AppColors.auroraGradient),
    child: Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(borderRadius - 2), color: const Color(0xFF0A0E1F)),
      child: child,
    ),
  );
}

Widget _buildLoginInput(String hint, {bool obscure = false}) {
  return Container(
    height: 40,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      color: const Color(0xFF0A0E1F),
    ),
    child: TextField(
      enabled: false,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    ),
  );
}

Widget _buildLoginRainbowBtn(String label, {required double height}) {
  return Container(
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.auroraGradient),
    child: Container(
      height: height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFF0A0E1F)),
      child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
    ),
  );
}

Widget _buildRegister() {
  return Scaffold(
    backgroundColor: const Color(0xFF0a0a15),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "OpenFaith" title at top
              ShaderMask(
                shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Text('OpenFaith', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
              // Card with rainbow gradient border (2px)
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: AppColors.auroraGradient),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFF0A0E1F)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // "注册" title
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => AppColors.auroraGradient.createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: const Text('注册', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Email
                    _buildRegisterInput(label: '邮箱', hint: '请输入邮箱...'),
                    const SizedBox(height: 16),
                    // Password
                    _buildRegisterInput(label: '密码', hint: '请输入密码（至少8位）...', obscure: true),
                    const SizedBox(height: 16),
                    // Nickname
                    _buildRegisterInput(label: '昵称', hint: '请输入昵称...'),
                    const SizedBox(height: 16),
                    // Faith tag dropdown
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('身份标签 *', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                      const SizedBox(height: 4),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                          color: Colors.white.withOpacity(0.06),
                        ),
                        child: Row(children: [
                          Expanded(child: Text('请选择身份标签...', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14))),
                          Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.45), size: 18),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Age 13 checkbox
                    Row(children: [
                      Container(width: 16, height: 16, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.white, width: 0.8)),
                        child: const Icon(Icons.check, color: Colors.white, size: 14)),
                      const SizedBox(width: 6),
                      Expanded(child: Text('我已年满13周岁', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11))),
                    ]),
                    const SizedBox(height: 8),
                    // Terms checkbox
                    Row(children: [
                      Container(width: 16, height: 16, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.white, width: 0.8)),
                        child: const Icon(Icons.check, color: Colors.white, size: 14)),
                      const SizedBox(width: 6),
                      Expanded(child: Text('我已阅读并同意 隐私政策 和 用户协议', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11))),
                    ]),
                    const SizedBox(height: 14),
                    // Register button
                    _buildLoginRainbowBtn('获取验证码', height: 42),
                    const SizedBox(height: 16),
                    // Login link
                    Text('已有账号？', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.15), width: 1)),
                      child: const Text('立即登录', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildRegisterInput({required String label, required String hint, bool obscure = false}) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
    const SizedBox(height: 4),
    Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        color: Colors.white.withOpacity(0.06),
      ),
      child: TextField(
        enabled: false,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          isDense: true,
        ),
      ),
    ),
  ]);
}
