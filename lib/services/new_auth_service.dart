import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../config/app_config.dart';
import 'driver_websocket_service.dart';

/// Authentication service supporting both offline mock and AWS Cognito.
class NewAuthService {
  final DriverWebSocketService _webSocketService;

  static String? _authToken;
  static String? get authToken => _authToken;

  // In-memory mock user store (used when AWS is disabled)
  static final Map<String, Map<String, String>> _mockUsers = {
    'driver@example.com': {
      'password': 'password123',
      'name': 'Driver Email',
      'phone': '+9647700000000',
    },
    '+9647701234567': {
      'password': '123456',
      'name': 'Driver Phone',
      'email': 'phoneuser@example.com',
    },
  };

  NewAuthService({required DriverWebSocketService webSocketService})
    : _webSocketService = webSocketService;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('new_auth_token');

    // If AWS is enabled, sync token with current Amplify session status
    if (AppConfig.enableAWSIntegration) {
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        if (session.isSignedIn) {
          // Maintain a lightweight marker token; actual tokens are managed by Amplify
          await _saveToken(
            _authToken ?? 'cognito_${DateTime.now().millisecondsSinceEpoch}',
          );
          await _autoConnectWebSocket();
        }
      } catch (_) {
        // Ignore; remain logged out if session fetch fails
      }
    }
  }

  Future<void> _saveToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('new_auth_token', token);
  }

  Future<void> _clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('new_auth_token');
  }

  bool get isAuthenticated => _authToken != null;

  // Login with email
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (AppConfig.enableAWSIntegration) {
      try {
        final res = await Amplify.Auth.signIn(
          username: email,
          password: password,
        );
        if (res.isSignedIn) {
          await _saveToken('cognito_${DateTime.now().millisecondsSinceEpoch}');
          await _autoConnectWebSocket();
          return true;
        }
        // Handle next steps (e.g., MFA) as not supported in this flow
        return false;
      } on AuthException catch (e) {
        safePrint('Cognito signIn (email) failed: ${e.message}');
        return false;
      } catch (e) {
        safePrint('Cognito signIn (email) error: $e');
        return false;
      }
    }

    // Mock: offline
    await Future.delayed(const Duration(milliseconds: 400));
    final user = _mockUsers[email];
    if (user != null && user['password'] == password) {
      await _saveToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');
      await _autoConnectWebSocket();
      return true;
    }
    return false;
  }

  // Login with phone
  Future<bool> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    if (AppConfig.enableAWSIntegration) {
      try {
        final res = await Amplify.Auth.signIn(
          username: phone,
          password: password,
        );
        if (res.isSignedIn) {
          await _saveToken('cognito_${DateTime.now().millisecondsSinceEpoch}');
          await _autoConnectWebSocket();
          return true;
        }
        return false;
      } on AuthException catch (e) {
        safePrint('Cognito signIn (phone) failed: ${e.message}');
        return false;
      } catch (e) {
        safePrint('Cognito signIn (phone) error: $e');
        return false;
      }
    }

    // Mock: offline
    await Future.delayed(const Duration(milliseconds: 400));
    final user = _mockUsers[phone];
    if (user != null && user['password'] == password) {
      await _saveToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');
      await _autoConnectWebSocket();
      return true;
    }
    return false;
  }

  // Registration and other flows remain mock-only for now
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
    if (AppConfig.enableAWSIntegration) {
      try {
        final res = await Amplify.Auth.signUp(
          username: email,
          password: password,
          options: SignUpOptions(
            userAttributes: {
              CognitoUserAttributeKey.email: email,
              CognitoUserAttributeKey.phoneNumber: phone,
              CognitoUserAttributeKey.name: fullName,
            },
          ),
        );
        return {
          'success': true,
          'message': res.isSignUpComplete
              ? 'تم إنشاء الحساب'
              : 'تم إرسال رمز التحقق إلى بريدك/هاتفك',
          'confirmation_required': !res.isSignUpComplete,
        };
      } on AuthException catch (e) {
        return {
          'success': false,
          'message': e.message,
          'error': e.recoverySuggestion ?? 'AUTH_ERROR',
        };
      }
    }

    // Mock email registration
    await Future.delayed(const Duration(milliseconds: 500));
    if (_mockUsers.containsKey(email)) {
      return {
        'success': false,
        'message': 'يوجد حساب بهذا البريد الإلكتروني مسبقاً',
        'error': 'USERNAME_EXISTS',
      };
    }
    _mockUsers[email] = {
      'password': password,
      'name': fullName,
      'phone': phone,
    };
    return {
      'success': true,
      'message': 'تم إنشاء الحساب (وضع غير متصل)',
      'confirmation_required': false,
      'user_id': 'mock_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  Future<Map<String, dynamic>> registerWithPhone({
    required String phone,
    required String password,
    required String fullName,
    required String city,
    required String vehicleType,
    required String licenseNumber,
    required String nationalId,
  }) async {
    if (AppConfig.enableAWSIntegration) {
      try {
        final res = await Amplify.Auth.signUp(
          username: phone,
          password: password,
          options: SignUpOptions(
            userAttributes: {
              CognitoUserAttributeKey.phoneNumber: phone,
              CognitoUserAttributeKey.name: fullName,
            },
          ),
        );
        return {
          'success': true,
          'message': res.isSignUpComplete
              ? 'تم إنشاء الحساب'
              : 'تم إرسال رمز التحقق إلى هاتفك',
          'phone_verification_required': !res.isSignUpComplete,
        };
      } on AuthException catch (e) {
        return {
          'success': false,
          'message': e.message,
          'error': e.recoverySuggestion ?? 'AUTH_ERROR',
        };
      }
    }

    // Mock phone registration
    await Future.delayed(const Duration(milliseconds: 500));
    if (_mockUsers.containsKey(phone)) {
      return {
        'success': false,
        'message': 'رقم الهاتف مستخدم بالفعل',
        'error': 'PHONE_EXISTS',
      };
    }
    _mockUsers[phone] = {
      'password': password,
      'name': fullName,
      'email': 'mock_${DateTime.now().millisecondsSinceEpoch}@example.com',
    };
    return {
      'success': true,
      'message': 'تم التسجيل بنجاح (وضع غير متصل)',
      'phone_verification_required': false,
    };
  }

  Future<Map<String, dynamic>> sendPhoneVerification({
    required String phone,
  }) async {
    if (AppConfig.enableAWSIntegration) {
      // In Cognito, code is sent during signUp; resending can be done via resendSignUpCode
      try {
        await Amplify.Auth.resendSignUpCode(username: phone);
        return {
          'success': true,
          'message': 'تم إرسال رمز التحقق',
          'verification_id': 'cognito',
        };
      } on AuthException catch (e) {
        return {'success': false, 'message': e.message};
      }
    }

    // Mock sending phone verification
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'success': true,
      'message': 'تم إرسال رمز التحقق (رمز التطوير: 12345)',
      'verification_id': 'mock_ver_${DateTime.now().millisecondsSinceEpoch}',
      'dev_code': '12345',
    };
  }

  Future<Map<String, dynamic>> verifyPhoneNumber({
    required String phone,
    required String verificationCode,
  }) async {
    if (AppConfig.enableAWSIntegration) {
      try {
        final res = await Amplify.Auth.confirmSignUp(
          username: phone,
          confirmationCode: verificationCode,
        );
        return {
          'success': res.isSignUpComplete,
          'verified': res.isSignUpComplete,
          'message': res.isSignUpComplete
              ? 'تم التحقق من رقم الهاتف'
              : 'فشل التحقق',
        };
      } on AuthException catch (e) {
        return {'success': false, 'verified': false, 'message': e.message};
      }
    }

    // Mock verify phone number
    await Future.delayed(const Duration(milliseconds: 300));
    final ok = verificationCode == '12345';
    return {
      'success': ok,
      'verified': ok,
      'message': ok
          ? 'تم التحقق من رقم الهاتف'
          : 'رمز التحقق غير صحيح (استخدم 12345)',
    };
  }

  static Future<bool> resetPasswordEmail({required String email}) async {
    if (AppConfig.enableAWSIntegration) {
      try {
        await Amplify.Auth.resetPassword(username: email);
        return true;
      } on AuthException catch (e) {
        safePrint('resetPasswordEmail failed: ${e.message}');
        return false;
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  Future<Map<String, dynamic>> resetPasswordPhone({
    required String phone,
  }) async {
    if (AppConfig.enableAWSIntegration) {
      try {
        await Amplify.Auth.resetPassword(username: phone);
        return {
          'success': true,
          'message': 'تم إرسال رمز إعادة التعيين',
          'verification_id': 'cognito',
        };
      } on AuthException catch (e) {
        return {'success': false, 'message': e.message};
      }
    }

    // Mock reset via phone
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'success': true,
      'message': 'تم إرسال رمز إعادة التعيين (رمز التطوير: 12345)',
      'verification_id': 'mock_reset_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  static Future<bool> confirmPasswordReset({
    required String email,
    required String newPassword,
    required String confirmationCode,
  }) async {
    if (AppConfig.enableAWSIntegration) {
      try {
        await Amplify.Auth.confirmResetPassword(
          username: email,
          newPassword: newPassword,
          confirmationCode: confirmationCode,
        );
        return true;
      } on AuthException catch (e) {
        safePrint('confirmPasswordReset failed: ${e.message}');
        return false;
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
    return confirmationCode == '12345' && newPassword.length >= 6;
  }

  Future<Map<String, dynamic>> getCurrentDriver() async {
    if (!isAuthenticated) {
      return {'success': false, 'message': 'غير مصرح بالوصول'};
    }
    if (AppConfig.enableAWSIntegration) {
      try {
        final user = await Amplify.Auth.getCurrentUser();
        return {
          'success': true,
          'data': {
            'id': user.userId,
            'name': user.username,
            'phone': '',
            'city': 'Baghdad',
            'vehicle_type': 'motorcycle',
            'status': 'active',
          },
        };
      } catch (_) {
        // Fallback
      }
    }

    // Mock profile
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'success': true,
      'data': {
        'id': 'driver_123',
        'name': 'سائق حاضر',
        'phone': '+9647701234567',
        'city': 'Baghdad',
        'vehicle_type': 'motorcycle',
        'status': 'active',
      },
    };
  }

  Future<void> logout() async {
    if (AppConfig.enableAWSIntegration) {
      try {
        await Amplify.Auth.signOut();
      } catch (_) {}
    }
    await _clearToken();
    _webSocketService.disconnect();
  }

  Future<void> _autoConnectWebSocket() async {
    if (isAuthenticated) {
      try {
        await _webSocketService.connect(_authToken!);
      } catch (_) {}
    }
  }

  // Validators
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}\$').hasMatch(email);
  }

  static bool isValidIraqiPhone(String phone) {
    return RegExp(r'^07[0-9]{9}\$').hasMatch(phone);
  }

  static String normalizeIraqiPhone(String phone) {
    if (phone.startsWith('07')) return '+964${phone.substring(1)}';
    if (phone.startsWith('7')) return '+964$phone';
    return phone;
  }

  Future<bool> confirmEmail({
    required String email,
    required String verificationCode,
  }) async {
    if (AppConfig.enableAWSIntegration) {
      try {
        final res = await Amplify.Auth.confirmSignUp(
          username: email,
          confirmationCode: verificationCode,
        );
        return res.isSignUpComplete;
      } on AuthException catch (e) {
        safePrint('confirmEmail failed: ${e.message}');
        return false;
      }
    }
    await Future.delayed(const Duration(milliseconds: 300));
    return verificationCode == '12345';
  }
}
