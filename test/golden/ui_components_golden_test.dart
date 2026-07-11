import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'package:openfaith_app/widgets/rainbow_border.dart';
import 'package:openfaith_app/widgets/glass_card.dart';
import 'package:openfaith_app/widgets/aurora_button.dart';

void main() {
  group('UI Component Golden Tests', () {
    
    testWidgets('RainbowBorder renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: RainbowBorder(
                child: Container(
                  width: 300,
                  height: 200,
                  color: AppColors.cardBg,
                  child: const Center(
                    child: Text('Rainbow Border', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_rainbow_border.png'));
    });

    testWidgets('GlassCard renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: GlassCard(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(24),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Glass Card', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Text('This is a glass card component', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_glass_card.png'));
    });

    testWidgets('Login form layout renders correctly', (WidgetTester tester) async {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: Scaffold(
            backgroundColor: AppColors.bgColor,
            body: Center(
              child: SingleChildScrollView(
                child: GlassCard(
                  borderRadius: 24,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('OpenFaith', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('开启你的信仰之旅', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        const SizedBox(height: 32),
                        TextField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '邮箱',
                            hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                            filled: true,
                            fillColor: AppColors.inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '密码',
                            hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                            filled: true,
                            fillColor: AppColors.inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.auroraGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('登录', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_login_form.png'));
    });

    testWidgets('Bottom navigation bar renders correctly', (WidgetTester tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(scaffoldBackgroundColor: AppColors.bgColor),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              backgroundColor: AppColors.bgColor,
              body: const Center(child: Text('Content', style: TextStyle(color: Colors.white))),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: AppColors.navBg,
                  border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8).copyWith(top: 2, bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.home_outlined, Icons.home, '首页', selectedIndex, setState),
                        _buildNavItem(1, Icons.explore_outlined, Icons.explore, '学习', selectedIndex, setState),
                        _buildPublishButton(),
                        _buildNavItem(2, Icons.notifications_outlined, Icons.notifications, '消息', selectedIndex, setState),
                        _buildNavItem(3, Icons.person_outline, Icons.person, '我的', selectedIndex, setState),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/component_bottom_nav.png'));
    });
  });
}

Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, int selectedIndex, Function setState) {
  final isSelected = selectedIndex == index;
  return GestureDetector(
    onTap: () => setState(() {}),
    behavior: HitTestBehavior.opaque,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, size: 20, color: isSelected ? Colors.white : AppColors.iconColorWeak),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.textPrimary : AppColors.iconColorWeak)),
          ],
        ),
      ),
    ),
  );
}

Widget _buildPublishButton() {
  return Transform.translate(
    offset: const Offset(0, -8),
    child: Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(1.5),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.auroraColors)),
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bgSecondarySolid),
        child: const Center(child: Icon(Icons.add, color: Colors.white, size: 20)),
      ),
    ),
  );
}
