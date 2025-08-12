import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_colors.dart';

class NewEmailVerificationScreen extends StatelessWidget {
  final String email;
  final bool fromSignup;

  const NewEmailVerificationScreen({
    super.key,
    required this.email,
    this.fromSignup = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('تحقق من البريد الإلكتروني', style: TextStyle(color: AppColors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/new-login'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              'تحقق من البريد الإلكتروني',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 10),
            Text(
              'تم إرسال رمز التحقق إلى: $email',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.go('/new-login'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('العودة لتسجيل الدخول', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
