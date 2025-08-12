import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app_colors.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController =
      TextEditingController(); // Changed from email to username
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper method to detect if input is email or phone
  bool _isEmail(String input) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(input);
  }

  bool _isPhoneNumber(String input) {
    // Iraqi phone number pattern: 07XXXXXXXXX or +9647XXXXXXXXX
    // Remove any spaces or dashes for validation
    String cleanInput = input.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^(\+964|0)(7[0-9]{9})$').hasMatch(cleanInput);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final username = _usernameController.text.trim().replaceAll(
      RegExp(r'[\s\-]'),
      '',
    );
    final password = _passwordController.text;

    bool success = false;
    String? errorMessage;

    try {
      final authProvider = context.read<AuthProvider>();

      debugPrint(
        '🔐 Login attempt: $username (Email: ${_isEmail(username)}, Phone: ${_isPhoneNumber(username)})',
      );

      if (_isEmail(username)) {
        // Use AWS Cognito for email authentication
        debugPrint('📧 Using AWS Cognito authentication for email');
        success = await authProvider.loginWithEmail(
          email: username,
          password: password,
        );
        if (!success) {
          errorMessage =
              authProvider.errorMessage ?? 'Incorrect username or password';
        }
      } else if (_isPhoneNumber(username)) {
        // Use legacy phone authentication
        debugPrint('📱 Using legacy phone authentication');
        success = await authProvider.login(phone: username, password: password);
        if (!success) {
          errorMessage =
              authProvider.errorMessage ?? 'Incorrect username or password';
        }
      } else {
        errorMessage = 'Please enter a valid email or phone number.';
      }

      debugPrint('✅ Login result: $success');
    } catch (e) {
      debugPrint('❌ Login error: $e');
      errorMessage = e.toString();
    }

    if (mounted) {
      if (success) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Login failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo and welcome text
                  const Icon(
                    Icons.delivery_dining,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'مرحباً بك في حاضر',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سجل دخولك للبدء في توصيل الطلبات',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email or Phone field
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني أو رقم الهاتف',
                      hintText: 'example@domain.com أو 07XX XXX XXXX',
                      prefixIcon: Icon(Icons.account_circle),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني أو رقم الهاتف';
                      }

                      // Clean input for validation
                      String cleanValue = value.trim().replaceAll(
                        RegExp(r'[\s\-]'),
                        '',
                      );

                      final isEmail = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      ).hasMatch(cleanValue);
                      final isPhone = RegExp(
                        r'^(\+964|0)(7[0-9]{9})$',
                      ).hasMatch(cleanValue);

                      if (!isEmail && !isPhone) {
                        return 'يرجى إدخال بريد إلكتروني صحيح أو رقم هاتف صحيح (مثال: 07XXXXXXXXX)';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال كلمة المرور';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  SizedBox(
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Forgot password link
                  TextButton(
                    onPressed: () {
                      context.push('/forgot-password');
                    },
                    child: const Text(
                      'نسيت كلمة المرور؟',
                      style: TextStyle(color: AppColors.primary, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Registration link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ليس لديك حساب؟ ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/register');
                        },
                        child: const Text(
                          'سجل الآن',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
