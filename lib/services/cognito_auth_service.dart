import 'dart:async';
import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../services/logging/auth_logger.dart';
import '../config/environment.dart';
import 'aws_dynamodb_service.dart';

/// AWS Cognito authentication service for user registration and login
class CognitoAuthService {
  static String? _authToken;
  static String? get authToken => _authToken;
  AuthLogger? logger;

  /// Persist any cached extended registration fields to DynamoDB profile.
  /// Returns true if a pending cache existed and was successfully persisted.
  Future<bool> persistPendingRegistrationIfAny() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pending_driver_registration');
      if (raw == null || raw.isEmpty) {
        return false;
      }
      final Map<String, dynamic> pending = jsonDecode(raw);

      // Ensure the DynamoDB HTTP client is configured with a valid token.
      String? token = _authToken;
      if (token == null || token.isEmpty) {
        try {
          final session =
              await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
          if (session.isSignedIn) {
            token = session.userPoolTokensResult.value.accessToken.raw;
          }
        } catch (_) {}
      }
      if (token != null && token.isNotEmpty) {
        AWSDynamoDBService.configure(
          baseUrl: Environment.apiBaseUrl,
          authToken: token,
        );
      }

      // Fetch existing profile first to respect current verification status
      String existingStatus = 'PENDING_PROFILE';
      try {
        final existing = await AWSDynamoDBService().getDriverProfile(
          'self',
          maxRetries: 1,
        );
        if (existing != null &&
            (existing['status'] ?? '').toString().isNotEmpty) {
          existingStatus = existing['status'];
        }
      } catch (e) {
        debugPrint(
          'persistPendingRegistrationIfAny: failed to read existing profile (will proceed): $e',
        );
      }

      // Determine if we should auto-advance status to PENDING_REVIEW (all key docs present)
      final hasDocsInfo =
          (pending['licenseNumber'] ?? '').toString().isNotEmpty &&
          (pending['nationalId'] ?? '').toString().isNotEmpty &&
          (pending['docs'] ?? '').toString().isNotEmpty;

      final attr = <String, String>{
        'name': pending['name'] ?? '',
        'city': pending['city'] ?? '',
        'vehicleType': pending['vehicleType'] ?? '',
        'licenseNumber': pending['licenseNumber'] ?? '',
        'nationalId': pending['nationalId'] ?? '',
        'docs': pending['docs'] ?? '',
      };

      // Only attempt auto-transition if profile still at baseline
      if (hasDocsInfo && existingStatus == 'PENDING_PROFILE') {
        attr['status'] = 'PENDING_REVIEW';
        debugPrint(
          'persistPendingRegistrationIfAny: auto-transitioning status PENDING_PROFILE -> PENDING_REVIEW',
        );
      } else {
        debugPrint(
          'persistPendingRegistrationIfAny: not setting status (existingStatus=$existingStatus, hasDocsInfo=$hasDocsInfo)',
        );
      }

      // Persist to DynamoDB via HTTP API
      final ok = await AWSDynamoDBService().saveDriverRegistration(
        driverId: 'self',
        email: pending['email'] ?? '',
        phoneNumber: pending['phone'] ?? '',
        attributes: attr,
      );

      if (ok) {
        await prefs.remove('pending_driver_registration');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('persistPendingRegistrationIfAny error: $e');
      return false;
    }
  }

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
    Map<String, dynamic>? drivingLicenseFile,
    Map<String, dynamic>? vehicleRegistrationFile,
    Map<String, dynamic>? nonCriminalRecordFile,
  }) async {
    logger?.logSendCode(
      identity: email,
      channel: 'email',
      purpose: 'signup',
      attempt: 1,
    );
    debugPrint('🔧 CognitoAuthService.registerWithEmail called');
    debugPrint('   Email: $email');
    debugPrint('   Phone: $phone');
    debugPrint('   Name: $fullName');

    try {
      debugPrint('🔧 Building user attributes...');
      final userAttributes = <AuthUserAttributeKey, String>{
        AuthUserAttributeKey.email: email,
        if (phone.isNotEmpty)
          AuthUserAttributeKey.phoneNumber: _formatPhoneNumber(phone),
        AuthUserAttributeKey.name: fullName,
        // NOTE: Custom driver profile fields removed from Cognito. They will be stored in DynamoDB.
      };

      debugPrint(
        '🔧 User attributes prepared (Cognito only): ${userAttributes.length} attributes',
      );
      debugPrint('🔧 Formatted phone: ${_formatPhoneNumber(phone)}');

      debugPrint('🔧 Calling Amplify.Auth.signUp...');
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(userAttributes: userAttributes),
      );

      // Cache extended fields to persist post-confirmation
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'pending_driver_registration',
          jsonEncode({
            'email': email,
            'phone': _formatPhoneNumber(phone),
            'name': fullName,
            'city': city,
            'vehicleType': vehicleType,
            'licenseNumber': licenseNumber,
            'nationalId': nationalId,
            'docs': '',
          }),
        );
      } catch (_) {}

      // TODO(DynamoDB): After successful sign up, persist driver profile (city, vehicleType, licenseNumber, nationalId, files) in DynamoDB table.

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
    Map<String, dynamic>? drivingLicenseFile,
    Map<String, dynamic>? vehicleRegistrationFile,
    Map<String, dynamic>? nonCriminalRecordFile,
  }) async {
    debugPrint('🔧 CognitoAuthService.registerWithPhone called');
    debugPrint('🔧 Input phone: $phone');
    debugPrint('🔧 Input validation:');
    debugPrint('  - phone length: ${phone.length}');
    debugPrint('  - password length: ${password.length}');
    debugPrint('  - fullName: "$fullName"');
    debugPrint('  - city: "$city"');
    debugPrint('  - vehicleType: "$vehicleType"');
    debugPrint('  - licenseNumber: "$licenseNumber"');
    debugPrint('  - nationalId: "$nationalId"');
    debugPrint('🔧 Debug: Hot reload trigger');

    // Additional validation before AWS call
    if (!isValidIraqiPhone(phone)) {
      debugPrint('❌ Phone validation failed for: $phone');
      return {
        'success': false,
        'message': 'رقم الهاتف غير صحيح. يجب أن يبدأ بـ 07 ويكون 11 رقماً',
        'error': 'INVALID_PHONE_FORMAT',
      };
    }

    if (password.length < 8) {
      debugPrint('❌ Password too short: ${password.length}');
      return {
        'success': false,
        'message': 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
        'error': 'WEAK_PASSWORD',
      };
    }

    logger?.logSendCode(
      identity: phone,
      channel: 'phone',
      purpose: 'signup',
      attempt: 1,
    );
    try {
      final formattedPhone = _formatPhoneNumber(phone);
      debugPrint('🔧 Formatted phone: $formattedPhone');

      final userAttributes = <AuthUserAttributeKey, String>{
        AuthUserAttributeKey.phoneNumber: formattedPhone,
        AuthUserAttributeKey.name: fullName,
        // NOTE: Custom driver profile fields removed from Cognito. They will be stored in DynamoDB.
      };

      debugPrint(
        '🔧 User attributes prepared (Cognito only): ${userAttributes.length} attributes',
      );
      debugPrint(
        '🔧 Calling Amplify.Auth.signUp with username: $formattedPhone',
      );

      final result = await Amplify.Auth.signUp(
        username: formattedPhone,
        password: password,
        options: SignUpOptions(userAttributes: userAttributes),
      );

      // Cache extended fields to persist post-confirmation
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'pending_driver_registration',
          jsonEncode({
            'email': '',
            'phone': formattedPhone,
            'name': fullName,
            'city': city,
            'vehicleType': vehicleType,
            'licenseNumber': licenseNumber,
            'nationalId': nationalId,
            'docs': '',
          }),
        );
      } catch (_) {}

      // TODO(DynamoDB): After successful sign up, persist driver profile (city, vehicleType, licenseNumber, nationalId, files) in DynamoDB table.

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
      debugPrint('🔧 AuthException in registerWithPhone: ${e.message}');
      debugPrint('🔧 AuthException type: ${e.runtimeType}');
      debugPrint('🔧 Underlying exception: ${e.underlyingException}');

      // Detailed error analysis
      String detailedMessage = _getArabicErrorMessage(e);
      String errorCode = 'AUTH_ERROR';

      if (e is InvalidParameterException) {
        debugPrint('🔧 InvalidParameterException details:');
        debugPrint('   - Original phone: $phone');
        debugPrint('   - Formatted phone: ${_formatPhoneNumber(phone)}');
        debugPrint('   - Phone validation result: ${isValidIraqiPhone(phone)}');
        debugPrint('   - Password length: ${password.length}');
        errorCode = 'INVALID_PARAMETER';
      }
      
      return {
        'success': false,
        'message': detailedMessage,
        'error': e.message,
        'error_code': errorCode,
        'debug_info': {
          'input_phone': phone,
          'formatted_phone': _formatPhoneNumber(phone),
          'phone_validation': isValidIraqiPhone(phone),
          'exception_type': e.runtimeType.toString(),
        },
      };
    } catch (e) {
      debugPrint('🔧 Generic exception in registerWithPhone: $e');
      debugPrint('🔧 Exception type: ${e.runtimeType}');
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
    final success = await (() async {
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
    })();
    logger?.logVerifyCode(
      identity: email,
      channel: 'email',
      purpose: 'signup',
      success: success,
      failureReason: success ? null : 'code_mismatch',
    );
    return success;
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

      final attributeMap = <String, String>{};
      for (final attr in userAttributes) {
        attributeMap[attr.userAttributeKey.key] = attr.value;
      }

      // Configure DynamoDB API client with Cognito token
      final cognitoSession = session as CognitoAuthSession;
      final tokens = cognitoSession.userPoolTokensResult.value;
      final accessToken = tokens.accessToken.raw;
      AWSDynamoDBService.configure(
        baseUrl: Environment.apiBaseUrl,
        authToken: accessToken,
      );

      // Retry fetching profile (handle eventual consistency right after confirmation)
      Map<String, dynamic>? dynamoProfile;
      for (var attempt = 1; attempt <= 3; attempt++) {
        dynamoProfile = await AWSDynamoDBService().getDriverProfile(
          'self',
          maxRetries: 1,
        );
        if (dynamoProfile != null) break;
        await Future.delayed(const Duration(milliseconds: 200));
      }

      final merged = {
        'id': user.userId,
        'username': user.username,
        'name': attributeMap['name'] ?? (dynamoProfile?['name'] ?? ''),
        'email': attributeMap['email'] ?? (dynamoProfile?['email'] ?? ''),
        'phone':
            attributeMap['phone_number'] ?? (dynamoProfile?['phone'] ?? ''),
        'city': dynamoProfile?['city'] ?? '',
        'vehicle_type': dynamoProfile?['vehicleType'] ?? '',
        'license_number': dynamoProfile?['licenseNumber'] ?? '',
        'national_id': dynamoProfile?['nationalId'] ?? '',
        'email_verified': attributeMap['email_verified'] == 'true',
        'phone_verified': attributeMap['phone_number_verified'] == 'true',
        'status': dynamoProfile?['status'] ?? 'PENDING_PROFILE',
      };

      return {'success': true, 'data': merged};
    } on AuthException catch (e) {
      return {'success': false, 'message': _getArabicErrorMessage(e)};
    }
  }

  /// Verify phone number
  Future<Map<String, dynamic>> verifyPhoneNumber({
    required String phone,
    required String verificationCode,
  }) async {
    final result = await (() async {
      try {
        final formattedPhone = _formatPhoneNumber(phone);
        final result = await Amplify.Auth.confirmSignUp(
          username: formattedPhone,
          confirmationCode: verificationCode,
        );

        // After confirmation, try to read profile and save extended fields if available
        if (result.isSignUpComplete) {
          try {
            // Warm-up read and persist pending registration
            await persistPendingRegistrationIfAny();
            await Future.delayed(const Duration(milliseconds: 300));
            await AWSDynamoDBService().getDriverProfile('self');
          } catch (_) {}
        }

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
    })();
    logger?.logVerifyCode(
      identity: phone,
      channel: 'phone',
      purpose: 'signup',
      success: result['success'] == true,
      failureReason: result['success'] == true ? null : 'code_mismatch',
    );
    return result;
  }

  /// Login with email
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    logger?.logLoginAttempt(identity: email, channel: 'email');
    final success = await (() async {
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
            // Persist pending registration if exists
            await persistPendingRegistrationIfAny();
            return true;
          }
        }
        return false;
      } on AuthException catch (e) {
        safePrint('Login error: ${e.message}');
        return false;
      }
    })();
    logger?.logLoginResult(
      identity: email,
      channel: 'email',
      success: success,
      failureReason: success ? null : 'invalid_credentials',
    );
    return success;
  }

  /// Login with phone
  Future<bool> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    logger?.logLoginAttempt(identity: phone, channel: 'phone');
    final success = await (() async {
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
            // Persist pending registration if exists
            await persistPendingRegistrationIfAny();
            return true;
          }
        }
        return false;
      } on AuthException catch (e) {
        safePrint('Login error: ${e.message}');
        return false;
      }
    })();
    logger?.logLoginResult(
      identity: phone,
      channel: 'phone',
      success: success,
      failureReason: success ? null : 'invalid_credentials',
    );
    return success;
  }

  /// Login with email (detailed result)
  Future<Map<String, dynamic>> loginWithEmailDetailed({
    required String email,
    required String password,
  }) async {
    logger?.logLoginAttempt(identity: email, channel: 'email');
    final result = await (() async {
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
          return {'success': true, 'message': 'تم تسجيل الدخول بنجاح'};
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
    })();
    logger?.logLoginResult(
      identity: email,
      channel: 'email',
      success: result['success'] == true,
      failureReason: result['success'] == true ? null : 'invalid_credentials',
    );
    return result;
  }

  /// Login with phone (detailed result)
  Future<Map<String, dynamic>> loginWithPhoneDetailed({
    required String phone,
    required String password,
  }) async {
    logger?.logLoginAttempt(identity: phone, channel: 'phone');
    final result = await (() async {
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
          return {'success': true, 'message': 'تم تسجيل الدخول بنجاح'};
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
    })();
    logger?.logLoginResult(
      identity: phone,
      channel: 'phone',
      success: result['success'] == true,
      failureReason: result['success'] == true ? null : 'invalid_credentials',
    );
    return result;
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
    await _clearToken();
    logger?.logLogout(identity: 'session');
  }

  /// Resend confirmation code with details
  Future<Map<String, dynamic>> resendConfirmationCodeWithDetails({
    required String username,
  }) async {
    try {
      final result = await Amplify.Auth.resendSignUpCode(username: username);

      String? deliveryMessage;
      if (result.codeDeliveryDetails.destination != null) {
        final destination = result.codeDeliveryDetails.destination!;
        if (result.codeDeliveryDetails.deliveryMedium == DeliveryMedium.email) {
          deliveryMessage = 'تم إرسال الرمز إلى $destination';
        } else if (result.codeDeliveryDetails.deliveryMedium ==
            DeliveryMedium.sms) {
          deliveryMessage = 'تم إرسال الرمز إلى $destination';
        }
      }

      return {
        'success': true,
        'message': 'تم إعادة إرسال رمز التحقق',
        'delivery_message': deliveryMessage,
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': _getArabicErrorMessage(e)};
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

  /// Force send verification code to email specifically
  /// Use this when user registered with both email and phone, but we want email verification
  Future<Map<String, dynamic>> sendEmailVerificationCode({
    required String email,
  }) async {
    try {
      debugPrint('🔧 Sending email verification code to: $email');
      
      final result = await Amplify.Auth.sendUserAttributeVerificationCode(
        userAttributeKey: AuthUserAttributeKey.email,
      );

      String? deliveryMessage;
      if (result.codeDeliveryDetails.destination != null) {
        final destination = result.codeDeliveryDetails.destination!;
        deliveryMessage = 'تم إرسال رمز التحقق إلى بريدك الإلكتروني: $destination';
      }

      return {
        'success': true,
        'message': 'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
        'delivery_message': deliveryMessage,
        'delivery_medium': 'email',
      };
    } on AuthException catch (e) {
      debugPrint('🔧 Error sending email verification: ${e.message}');
      return {
        'success': false, 
        'message': _getArabicErrorMessage(e),
        'error': e.message,
      };
    }
  }

  /// Confirm email attribute verification (after user is already signed up)
  Future<bool> confirmEmailAttribute({
    required String verificationCode,
  }) async {
    try {
      await Amplify.Auth.confirmUserAttribute(
        userAttributeKey: AuthUserAttributeKey.email,
        confirmationCode: verificationCode,
      );
      debugPrint('🔧 Email attribute confirmed successfully');
      return true;
    } on AuthException catch (e) {
      debugPrint('🔧 Error confirming email attribute: ${e.message}');
      return false;
    }
  }

  // Helper methods
  String _formatPhoneNumber(String phone) {
    // Convert Iraqi phone format to international format
    // Handle empty or invalid input
    if (phone.isEmpty) return phone;

    // Clean the input - remove spaces and special characters except +
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If it already starts with +964, validate and return
    if (cleanPhone.startsWith('+964')) {
      // Remove + for length validation
      String withoutPlus = cleanPhone.substring(1);
      // Should be 964 + 7 + 9 digits = 13 total (12 without +)
      if (withoutPlus.length == 12 &&
          withoutPlus.substring(3).startsWith('7')) {
        return cleanPhone; // Already properly formatted
      }
    }

    // Handle Iraqi local format 07XXXXXXXXX (11 digits)
    if (cleanPhone.startsWith('07') && cleanPhone.length == 11) {
      return '+964${cleanPhone.substring(1)}'; // Remove 0, add +964
    }

    // Handle format 7XXXXXXXXX (10 digits)
    if (cleanPhone.startsWith('7') && cleanPhone.length == 10) {
      return '+964$cleanPhone';
    }
    
    // If it doesn't match expected patterns, return as-is (will likely fail validation)
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
    if (e is CodeMismatchException) {
      return 'رمز التحقق غير صحيح';
    }
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
      // More specific error messages for invalid parameters
      final message = e.message.toLowerCase();
      if (message.contains('phone') || message.contains('phonenumber')) {
        return 'رقم الهاتف غير صحيح. يرجى إدخال رقم هاتف عراقي صحيح (مثال: 07701234567)';
      } else if (message.contains('email')) {
        return 'البريد الإلكتروني غير صحيح';
      } else if (message.contains('password')) {
        return 'كلمة المرور لا تتوافق مع المتطلبات. يجب أن تحتوي على 8 أحرف على الأقل مع أحرف وأرقام';
      } else if (message.contains('username')) {
        return 'اسم المستخدم غير صحيح';
      } else if (message.contains('attribute')) {
        return 'هناك خطأ في البيانات المدخلة. يرجى التحقق من جميع الحقول';
      }
      return 'بيانات غير صحيحة. يرجى مراجعة المدخلات والمحاولة مرة أخرى';
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
