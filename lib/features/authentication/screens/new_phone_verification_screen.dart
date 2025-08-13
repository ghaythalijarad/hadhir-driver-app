import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app_colors.dart';
import '../../../providers/riverpod/services_provider.dart';
import '../services/verification_throttle_service.dart';
import '../utils/identity_normalizer.dart';

class NewPhoneVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const NewPhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<NewPhoneVerificationScreen> createState() =>
      _NewPhoneVerificationScreenState();
}

class _NewPhoneVerificationScreenState
    extends ConsumerState<NewPhoneVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  late final String _normalizedPhone;

  @override
  void initState() {
    super.initState();
    _normalizedPhone = IdentityNormalizer.normalizeIraqiPhone(widget.phoneNumber);
    // Start initial cooldown when arriving (simulate first send already done)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verificationThrottleProvider.notifier).recordSend(_normalizedPhone);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _verificationCode {
    return _controllers.map((controller) => controller.text).join();
  }

  bool get _isCodeComplete {
    return _verificationCode.length == 6 && _verificationCode.replaceAll(RegExp(r'\D'), '').length == 6;
  }

  void _onCodeChanged(int index, String value) {
    setState(() {
      _errorMessage = null;
    });

    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all digits are entered
    if (_isCodeComplete) {
      _verifyCode();
    }
  }

  Future<void> _verifyCode() async {
    if (!_isCodeComplete) {
      setState(() {
        _errorMessage = 'يرجى إدخال الرمز كاملاً';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(newAuthServiceProvider);

    try {
      final result = await authService.verifyPhoneNumber(
        phone: widget.phoneNumber,
        verificationCode: _verificationCode,
      );

      if (result['success'] == true) {
        if (mounted) {
          // Navigate to main app
          context.go('/navigation');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'الرمز غير صحيح، يرجى المحاولة مرة أخرى';
          _clearCode();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التحقق. يرجى المحاولة مرة أخرى';
        _clearCode();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearCode() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  int get _resendCooldown {
    final throttle = ref.watch(verificationThrottleProvider);
    return throttle.identityState(_normalizedPhone).cooldownRemaining;
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() { _isResending = true; _errorMessage = null; });

    final authService = ref.read(newAuthServiceProvider);
    final notifier = ref.read(verificationThrottleProvider.notifier);
    notifier.setSending(_normalizedPhone, true);

    try {
      final result = await authService.sendPhoneVerification(phone: widget.phoneNumber);
      if (result['success'] == true) {
        notifier.recordSend(_normalizedPhone);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رمز التحقق الجديد'), backgroundColor: Colors.green));
        }
      } else {
        final msg = result['message'] ?? 'فشل في إرسال الرمز. يرجى المحاولة مرة أخرى';
        notifier.setError(_normalizedPhone, msg);
        setState(() { _errorMessage = msg; });
      }
    } catch (e) {
      notifier.setError(_normalizedPhone, 'حدث خطأ أثناء إرسال الرمز');
      setState(() { _errorMessage = 'حدث خطأ أثناء إرسال الرمز'; });
    } finally {
      notifier.setSending(_normalizedPhone, false);
      if (mounted) setState(() { _isResending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'تحقق من رقم الهاتف',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Phone icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android,
                size: 40,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'أدخل رمز التحقق',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              'تم إرسال رمز التحقق المكون من 6 أرقام إلى',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Phone number
            Text(
              widget.phoneNumber,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 40),

            // OTP Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(1),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.textSecondary.withAlpha(77)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.textSecondary.withAlpha(77)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) => _onCodeChanged(index, value),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 32),

            // Verify button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading || !_isCodeComplete ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textSecondary.withAlpha(77),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : Text(
                        'تأكيد',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Resend code
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'لم تستلم الرمز؟ ',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: _resendCooldown > 0 ? null : _resendCode,
                  child: Text(
                    _resendCooldown > 0
                        ? 'إعادة الإرسال خلال $_resendCooldownث'
                        : (_isResending ? 'جاري الإرسال...' : 'إعادة الإرسال'),
                    style: TextStyle(
                      color: _resendCooldown > 0 || _isResending
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
