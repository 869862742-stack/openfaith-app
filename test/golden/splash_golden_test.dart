import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openfaith_app/theme/app_colors.dart';
import 'test_helper.dart';

/// Splash Screen Golden Test
/// Covers: splash

void main() {
  group('Splash Golden Test', () {
    testWidgets('splash page renders correctly', (WidgetTester tester) async {
      await setupGoldenSurface(tester);
      await tester.pumpWidget(wrapForGoldenTest(_buildSplash()));
      await tester.pumpAndSettle();
      await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/page_splash.png'));
    });
  });
}

// ─── Splash Page ───
Widget _buildSplash() {
  return Scaffold(
    backgroundColor: AppColors.bgColor,
    body: Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgColor,
                AppColors.auroraBlue.withOpacity(0.08),
                AppColors.auroraPurple.withOpacity(0.05),
                AppColors.bgColor,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
        // Content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.auroraColors,
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.auroraBlue, AppColors.auroraPurple],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.self_improvement,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // App name
              const Text(
                'OpenFaith',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '信仰 · 连接 · 成长',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 64),
              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.auroraBlue.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom version text
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'v1.0.0',
              style: TextStyle(
                color: AppColors.textWeak,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
