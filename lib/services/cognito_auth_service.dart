import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// AWS Cognito authentication service for user registration and login
class CognitoAuthService {
  static String? _authToken;
  static String? get authToken => _authToken;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('cognito_auth_token');
  }

  Future<void> _saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cognito_auth_token', token);
  }

  Future<void> _clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cognito_auth_token');
  }

  bool get isAuthenticated => _authToken != null;

  /// Register with email
  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String city,
    required String vehicleType,
    required String licenseNumber,
    required String nationalId,
  }) async {
    debugPrint('🔧 CognitoAuthService.registerWithEmail called');
    debugPrint('   Email: $email');
    debugPrint('   Phone: $phone');
    debugPrint('   Name: $fullName');

    try {
      debugPrint('🔧 Building user attributes...');
      final userAttributes = <AuthUserAttributeKey, String>{
        AuthUserAttributeKey.email: email,
        AuthUserAttributeKey.phoneNumber: _formatPhoneNumber(phone),
        AuthUserAttributeKey.name: fullName,
        // Custom attributes for driver profile
        const CognitoUserAttributeKey.custom('city'): city,
        const CognitoUserAttributeKey.custom('vehicle_type'): vehicleType,
        const CognitoUserAttributeKey.custom('license_number'): licenseNumber,
        const CognitoUserAttributeKey.custom('national_id'): nationalId,
      };

      debugPrint('🔧 User attributes prepared: ${userAttributes.length} attributes');
      debugPrint('🔧 Formatted phone: ${_formatPhoneNumber(phone)}');

      debugPrint('🔧 User attributes prepared: ${userAttributes.length} attributes');
      debugPrint('🔧 Formatted phone: ${_formatPhoneNumber(phone)}');

      debugPrint('🔧 Calling Amplify.Auth.signUp...');
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(userAttributes: userAttributes),
      );

      debugPrint('🔧 Amplify.Auth.signUp completed');
      debugPrint('🔧 isSignUpComplete: ${result.isSignUpComplete}');
      debugPrint('🔧 userId: ${result.userId}');
      debugPrint('🔧 nextStep: ${result.nextStep.signUpStep.name}');

      if (result.isSignUpComplete) {
        debugPrint('🔧 Registration complete immediately');
        return {
          'success': true,
          'message': 'تم إنشاء الحساب بنجاح',
          'confirmation_required': false,
          'user_id': result.userId,
        };
      } else {
        debugPrint('🔧 Registration requires confirmation');
        return {
          'success': true,
          'message': 'تم إنشاء الحساب. يرجى التحقق من بريدك الإلكتروني',
          'confirmation_required': true,
          'user_id': result.userId,
          'next_step': result.nextStep.signUpStep.name,
        };
      }
    } on AuthException catch (e) {
      debugPrint('🔧 AuthException caught: ${e.message}');
      debugPrint('🔧 AuthException type: ${e.runtimeType}');
      debugPrint('🔧 Underlying exception: ${e.underlyingException}');
      return {
        'success': false,
        'message': _getArabicErrorMessage(e),
        'error': e.message,
        'error_code': e.underlyingException?.toString(),
      };
    } catch (e) {
      debugPrint('🔧 Generic exception caught: $e');
      debugPrint('🔧 Exception type: ${e.runtimeType}');
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع',
        'error': e.toString(),
      };
    }
  }

  /// Register with phone
  Future<Map<String, dynamic>> registerWithPhone({
    required String phone,
    required String password,
    required String fullName,
    required String city,
    required String vehicleType,
    required String licenseNumber,
    required String nationalId,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);

      final userAttributes = <AuthUserAttributeKey, String>{
        AuthUserAttributeKey.phoneNumber: formattedPhone,
        AuthUserAttributeKey.name: fullName,
        // Custom attributes for driver profile
        const CognitoUserAttributeKey.custom('city'): city,
        const CognitoUserAttributeKey.custom('vehicle_type'): vehicleType,
        const CognitoUserAttributeKey.custom('license_number'): licenseNumber,
        const CognitoUserAttributeKey.custom('national_id'): nationalId,
      };

      final result = await Amplify.Auth.signUp(
        username: formattedPhone,
        password: password,
        options: SignUpOptions(userAttributes: userAttributes),
      );

      if (result.isSignUpComplete) {
        return {
          'success': true,
          'message': 'تم التسجيل بنجاح',
          'phone_verification_required': false,
          'user_id': result.userId,
        };
      } else {
        return {
          'success': true,
          'message': 'تم إنشاء الحساب. يرجى التحقق من رسالة SMS',
          'phone_verification_required': true,
          'user_id': result.userId,
          'next_step': result.nextStep.signUpStep.name,
        };
      }
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _getArabicErrorMessage(e),
        'error': e.message,
        'error_code': e.underlyingException?.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع',
        'error': e.toString(),
      };
    }
  }

  /// Confirm email verification
  Future<bool> confirmEmail({
    required String email,
    required String verificationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: verificationCode,
      );
      return result.isSignUpComplete;
    } on AuthException catch (e) {
      safePrint('Error confirming email: ${e.message}');
      return false;
    }
  }

  /// Verify phone number
  Future<Map<String, dynamic>> verifyPhoneNumber({
    required String phone,
    required String verificationCode,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);
      final result = await Amplify.Auth.confirmSignUp(
        username: formattedPhone,
        confirmationCode: verificationCode,
      );

      return {
        'success': result.isSignUpComplete,
        'verified': result.isSignUpComplete,
        'message': result.isSignUpComplete
            ? 'تم التحقق من رقم الهاتف بنجاح'
            : 'رمز التحقق غير صحيح',
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'verified': false,
        'message': _getArabicErrorMessage(e),
      };
    }
  }

  /// Login with email
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (result.isSignedIn) {
        // Get user session token
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        if (session.isSignedIn) {
          final tokens = session.userPoolTokensResult.value;
          await _saveToken(tokens.accessToken.raw);
          return true;
        }
      }
      return false;
    } on AuthException catch (e) {
      safePrint('Login error: ${e.message}');
      return false;
    }
  }

  /// Login with phone
  Future<bool> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);
      final result = await Amplify.Auth.signIn(
        username: formattedPhone,
        password: password,
      );

      if (result.isSignedIn) {
        // Get user session token
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        if (session.isSignedIn) {
          final tokens = session.userPoolTokensResult.value;
          await _saveToken(tokens.accessToken.raw);
          return true;
        }
      }
      return false;
    } on AuthException catch (e) {
      safePrint('Login error: ${e.message}');
      return false;
    }
  }

  /// Login with email (detailed result)
  Future<Map<String, dynamic>> loginWithEmailDetailed({
    required String email,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (result.isSignedIn) {
        // Get user session token
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        if (session.isSignedIn) {
          final tokens = session.userPoolTokensResult.value;
          await _saveToken(tokens.accessToken.raw);
        }
        return {
          'success': true,
          'message': 'تم تسجيل الدخول بنجاح',
        };
      }

      return {
        'success': false,
        'message': 'مطلوب خطوة إضافية لإكمال تسجيل الدخول',
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _getArabicErrorMessage(e),
        'error': e.message,
        'error_code': e.underlyingException?.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع',
        'error': e.toString(),
      };
    }
  }

  /// Login with phone (detailed result)
  Future<Map<String, dynamic>> loginWithPhoneDetailed({
    required String phone,
    required String password,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);
      final result = await Amplify.Auth.signIn(
        username: formattedPhone,
        password: password,
      );

      if (result.isSignedIn) {
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        if (session.isSignedIn) {
          final tokens = session.userPoolTokensResult.value;
          await _saveToken(tokens.accessToken.raw);
        }
        return {
          'success': true,
          'message': 'تم تسجيل الدخول بنجاح',
        };
      }

      return {
        'success': false,
        'message': 'مطلوب خطوة إضافية لإكمال تسجيل الدخول',
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': _getArabicErrorMessage(e),
        'error': e.message,
        'error_code': e.underlyingException?.toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع',
        'error': e.toString(),
      };
    }
  }

  /// Get current authenticated user profile
  Future<Map<String, dynamic>> getCurrentDriver() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        return {'success': false, 'message': 'غير مصرح بالوصول'};
      }

      final user = await Amplify.Auth.getCurrentUser();
      final userAttributes = await Amplify.Auth.fetchUserAttributes();

      // Extract user attributes
      final attributeMap = <String, String>{};
      for (final attr in userAttributes) {
        attributeMap[attr.userAttributeKey.key] = attr.value;
      }

      return {
        'success': true,
        'data': {
          'id': user.userId,
          'username': user.username,
          'name': attributeMap['name'] ?? '',
          'email': attributeMap['email'] ?? '',
          'phone': attributeMap['phone_number'] ?? '',
          'city': attributeMap['custom:city'] ?? '',
          'vehicle_type': attributeMap['custom:vehicle_type'] ?? '',
          'license_number': attributeMap['custom:license_number'] ?? '',
          'national_id': attributeMap['custom:national_id'] ?? '',
          'email_verified': attributeMap['email_verified'] == 'true',
          'phone_verified': attributeMap['phone_number_verified'] == 'true',
          'status': 'active',
        },
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': _getArabicErrorMessage(e)};
    }
  }

  /// Reset password with email
  static Future<bool> resetPasswordEmail({required String email}) async {
    try {
      await Amplify.Auth.resetPassword(username: email);
      return true;
    } on AuthException catch (e) {
      safePrint('Password reset error: ${e.message}');
      return false;
    }
  }

  /// Reset password with phone
  Future<Map<String, dynamic>> resetPasswordPhone({
    required String phone,
  }) async {
    try {
      final formattedPhone = _formatPhoneNumber(phone);
      final result = await Amplify.Auth.resetPassword(username: formattedPhone);

      return {
        'success': true,
        'message': 'تم إرسال رمز إعادة التعيين',
        'next_step': result.nextStep.toString(),
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': _getArabicErrorMessage(e)};
    }
  }

  /// Confirm password reset
  static Future<bool> confirmPasswordReset({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
      return true;
    } on AuthException catch (e) {
      safePrint('Password reset confirmation error: ${e.message}');
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await Amplify.Auth.signOut();
      await _clearToken();
    } on AuthException catch (e) {
      safePrint('Logout error: ${e.message}');
      await _clearToken(); // Clear token anyway
    }
  }

  /// Resend confirmation code
  Future<Map<String, dynamic>> resendConfirmationCode({
    required String username,
  }) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: username);
      return {'success': true, 'message': 'تم إعادة إرسال رمز التحقق'};
    } on AuthException catch (e) {
      return {'success': false, 'message': _getArabicErrorMessage(e)};
    }
  }

  // Helper methods
  String _formatPhoneNumber(String phone) {
    // Convert Iraqi phone format to international format
    if (phone.startsWith('07')) {
      return '+964${phone.substring(1)}';
    } else if (phone.startsWith('7')) {
      return '+964$phone';
    } else if (!phone.startsWith('+')) {
      return '+964$phone';
    }
    return phone;
  }

  String _getArabicErrorMessage(AuthException e) {
    // Prefer specific exception types when available
    if (e is UsernameExistsException) {
      return 'يوجد حساب بهذا البريد الإلكتروني أو رقم الهاتف مسبقاً';
    }
    if (e is UserNotFoundException) {
      return 'المستخدم غير موجود';
    }
    // NotAuthorizedException isn't available as a concrete type in all builds; fall back to message matching below
    if (e is CodeMismatchException) {
      return 'رمز التحقق غير صحيح';
    }
    // CodeExpiredException and DeviceNotRememberedException may not be available; handle via message matching
    if (e is InvalidPasswordException) {
      return 'كلمة المرور لا تستوفي المتطلبات';
    }
    if (e is LimitExceededException) {
      return 'تم تجاوز عدد المحاولات المسموح. يرجى المحاولة لاحقاً';
    }
    if (e is TooManyFailedAttemptsException) {
      return 'محاولات عديدة فاشلة. الرجاء الانتظار';
    }
    if (e is InvalidParameterException) {
      return 'مدخلات غير صحيحة';
    }
    if (e is NetworkException) {
      return 'خطأ في الاتصال بالإنترنت';
    }

    // Fallback to message text heuristics
    final msg = e.message.toLowerCase();
    if (msg.contains('user already exists') || msg.contains('username exists')) {
      return 'يوجد حساب بهذا البريد الإلكتروني أو رقم الهاتف مسبقاً';
    }
    if (msg.contains('invalid password') ||
        msg.contains('password does not conform to policy')) {
      return 'كلمة المرور لا تتوافق مع السياسة المطلوبة';
    }
    if (msg.contains('invalid verification code') || msg.contains('code mismatch')) {
      return 'رمز التحقق غير صحيح';
    }
    if (msg.contains('expired code')) {
      return 'انتهت صلاحية رمز التحقق';
    }
    if (msg.contains('user not confirmed')) {
      return 'يرجى تأكيد حسابك أولاً';
    }
    if (msg.contains('user not found')) {
      return 'المستخدم غير موجود';
    }
    if (msg.contains('incorrect username or password') ||
        msg.contains('authentication failed') ||
        msg.contains('not authorized')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (msg.contains('too many requests') || msg.contains('limit exceeded')) {
      return 'تم تجاوز عدد المحاولات المسموح. يرجى المحاولة لاحقاً';
    }
    if (msg.contains('network')) {
      return 'خطأ في الاتصال بالإنترنت';
    }

    return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
  }

  // Validators (keep existing logic)
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidIraqiPhone(String phone) {
    return RegExp(r'^07[0-9]{9}$').hasMatch(phone);
  }

  static String normalizeIraqiPhone(String phone) {
    if (phone.startsWith('07')) return '+964${phone.substring(1)}';
    if (phone.startsWith('7')) return '+964$phone';
    return phone;
  }
}
