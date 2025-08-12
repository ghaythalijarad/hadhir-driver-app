import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_colors.dart';
import '../../../providers/riverpod/services_provider.dart';
import '../../../services/cognito_auth_service.dart';
import '../../../services/new_auth_service.dart';

class NewForgotPasswordScreen extends ConsumerStatefulWidget {
  const NewForgotPasswordScreen({super.key});

  @override
  ConsumerState<NewForgotPasswordScreen> createState() =>
      _NewForgotPasswordScreenState();
}

class _NewForgotPasswordScreenState
    extends ConsumerState<NewForgotPasswordScreen> {
  String _resetMethod = 'email';
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false; // local loading state replaces provider watch

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSubmitting = true; });
    final service = ref.read(authServiceProvider);

    try {
      if (_resetMethod == 'email') {
        bool success = false;
        if (service is CognitoAuthService) {
          success = await CognitoAuthService.resetPasswordEmail(
            email: _emailController.text.trim(),
          );
        } else if (service is NewAuthService) {
          success = await NewAuthService.resetPasswordEmail(
            email: _emailController.text.trim(),
          );
        }
        if (success) {
          _showSuccessDialog('تم إرسال رابط / رمز إعادة التعيين إلى بريدك الإلكتروني');
        } else {
          _showErrorDialog('فشل في إرسال بريد إعادة التعيين');
        }
      } else {
        Map<String, dynamic> result = {'success': false};
        if (service is CognitoAuthService) {
          result = await service.resetPasswordPhone(
            phone: _phoneController.text.trim(),
          );
        } else if (service is NewAuthService) {
          result = await service.resetPasswordPhone(
            phone: _phoneController.text.trim(),
          );
        }
        if (result['success'] == true) {
          _showSuccessDialog(result['message'] ?? 'تم إرسال رمز إعادة التعيين');
        } else {
          _showErrorDialog(result['message'] ?? 'فشل في إرسال رمز إعادة التعيين');
        }
      }
    } catch (e) {
      _showErrorDialog('خطأ: $e');
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تم الإرسال', style: TextStyle(color: AppColors.success)),
        content: Text(message, style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login'); // updated route
            },
            child: Text('حسناً', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('خطأ', style: TextStyle(color: AppColors.error)),
        content: Text(message, style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('حسناً', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Removed authState watch
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('استعادة كلمة المرور', style: TextStyle(color: AppColors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/login'), // updated route
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'استعادة كلمة المرور',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 30),
                    
                    // Method toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _resetMethod = 'email'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _resetMethod == 'email' ? AppColors.primary : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                ),
                                child: Text(
                                  'البريد الإلكتروني',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _resetMethod == 'email' ? AppColors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _resetMethod = 'phone'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _resetMethod == 'phone' ? AppColors.primary : Colors.transparent,
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                                ),
                                child: Text(
                                  'رقم الهاتف',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _resetMethod == 'phone' ? AppColors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Input field
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_resetMethod == 'email')
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'البريد الإلكتروني',
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    !value.contains('@')) {
                                  return 'يرجى إدخال بريد إلكتروني صحيح';
                                }
                                return null;
                              },
                            )
                          else
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'رقم الهاتف',
                                prefixIcon: Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال رقم هاتف صحيح';
                                }
                                return null;
                              },
                            ),
                          const SizedBox(height: 20),
                          if (_isSubmitting)
                            const CircularProgressIndicator()
                          else
                            ElevatedButton(
                              onPressed: _handlePasswordReset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'إرسال',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
