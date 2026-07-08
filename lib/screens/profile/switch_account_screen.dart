import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class SwitchAccountScreen extends StatelessWidget {
  const SwitchAccountScreen({super.key});

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
        title: const Text('切换账号',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz,
                color: AppColors.textMuted, size: 64),
            SizedBox(height: 16),
            Text('切换账号',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('功能开发中',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
