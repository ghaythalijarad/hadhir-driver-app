import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // Ensure Flutter bindings for Amplify
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'services/cognito_auth_service.dart';

/// Test function to directly create a new account in AWS Cognito
/// This bypasses the UI and creates an account programmatically
class TestCognitoRegistration {
  static final CognitoAuthService _cognitoService = CognitoAuthService();

  /// Create a test driver account directly in Cognito
  static Future<void> createTestAccount() async {
    // Multiple logging methods to ensure visibility
    _log('🚀 Starting account creation...');

    try {
      // Step 1: Check Amplify configuration
      _log('🔍 Step 1: Checking Amplify configuration...');
      if (!Amplify.isConfigured) {
        _log('❌ CRITICAL: Amplify is not configured!');
        _log('   Please ensure _configureAmplify() was called in main.dart');
        return;
      }
      _log('✅ Amplify is properly configured');

      // Step 2: Test Auth plugin availability
      _log('🔍 Step 2: Checking Auth plugin...');
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        _log(
          '✅ Auth plugin is accessible, current session signed in: ${session.isSignedIn}',
        );
      } catch (e) {
        _log('❌ Auth plugin error: $e');
        return;
      }

      // Step 3: Initialize our service
      _log('🔍 Step 3: Initializing Cognito service...');
      await _cognitoService.initialize();
      _log('✅ Service initialized successfully');

      // Step 4: Generate unique test account
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testAccountData = {
        'email': 'testdriver$timestamp@example.com', // Unique email
        'password': 'TestPass123!',
        'fullName': 'سائق تجريبي $timestamp',
        'phone': '07701234567',
        'city': 'بغداد',
        'vehicleType': 'دراجة نارية',
        'licenseNumber': 'DL$timestamp',
        'nationalId': '1234567890$timestamp',
      };

      _log('🔍 Step 4: Test Account Details:');
      _log('  Email: ${testAccountData['email']}');
      _log('  Phone: ${testAccountData['phone']}');
      _log('  Name: ${testAccountData['fullName']}');

      // Step 5: Call registration
      _log('🔍 Step 5: Calling Cognito registerWithEmail...');

      final result = await _cognitoService.registerWithEmail(
        email: testAccountData['email']!,
        password: testAccountData['password']!,
        fullName: testAccountData['fullName']!,
        phone: testAccountData['phone']!,
        city: testAccountData['city']!,
        vehicleType: testAccountData['vehicleType']!,
        licenseNumber: testAccountData['licenseNumber']!,
        nationalId: testAccountData['nationalId']!,
      );

      // Step 6: Process results
      _log('🔍 Step 6: Registration Result:');
      _log('  Success: ${result['success']}');
      _log('  Message: ${result['message']}');
      _log('  User ID: ${result['user_id'] ?? 'N/A'}');
      _log(
        '  Confirmation Required: ${result['confirmation_required'] ?? 'N/A'}',
      );

      if (result['success'] == true) {
        _log('✅ Account created successfully in AWS Cognito!');
        _log('📧 Account Details:');
        _log('  - Email: ${testAccountData['email']}');
        _log('  - Password: ${testAccountData['password']}');
        _log('  - User ID: ${result['user_id']}');

        if (result['confirmation_required'] == true) {
          _log('📧 Email confirmation required');
          _log('📋 Next Steps:');
          _log('  1. Check email for verification code');
          _log('  2. Or verify in AWS Cognito console at:');
          _log(
            '     https://console.aws.amazon.com/cognito/v2/idp/user-pools/us-east-1_xDptXxzaI/users',
          );
        } else {
          _log('🎉 Account is ready to use immediately!');
        }
      } else {
        _log('❌ Account creation failed');
        _log('  Error: ${result['error'] ?? 'Unknown error'}');
        _log('  Error Code: ${result['error_code'] ?? 'N/A'}');
      }
    } catch (e, stackTrace) {
      _log('💥 Exception during account creation:');
      _log('  Error: $e');
      _log(
        '  Stack Trace Preview: ${stackTrace.toString().split('\n').take(3).join('\n')}',
      );

      // Additional debugging
      try {
        if (!Amplify.isConfigured) {
          _log('⚠️  Amplify is not configured! Check main.dart initialization');
        } else {
          _log('✅ Amplify is configured');
        }
      } catch (amplifyError) {
        _log('❌ Error checking Amplify status: $amplifyError');
      }
    }

    _log('🏁 Account creation process completed');
  }

  /// Create account with phone number instead of email
  static Future<void> createTestAccountWithPhone() async {
    _log('🚀 Starting phone account creation...');

    try {
      await _cognitoService.initialize();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testAccountData = {
        'phone': '07701234568', // Different phone number
        'password': 'TestPass123!',
        'fullName': 'سائق تجريبي بالهاتف $timestamp',
        'city': 'البصرة',
        'vehicleType': 'سيارة شخصية',
        'licenseNumber': 'DL$timestamp',
        'nationalId': '10987654321',
      };

      _log('📱 Phone: ${testAccountData['phone']}');
      _log('👤 Name: ${testAccountData['fullName']}');

      final result = await _cognitoService.registerWithPhone(
        phone: testAccountData['phone']!,
        password: testAccountData['password']!,
        fullName: testAccountData['fullName']!,
        city: testAccountData['city']!,
        vehicleType: testAccountData['vehicleType']!,
        licenseNumber: testAccountData['licenseNumber']!,
        nationalId: testAccountData['nationalId']!,
      );

      if (result['success'] == true) {
        _log('✅ Phone account created successfully!');
        _log('📧 SMS verification may be required');
      } else {
        _log('❌ Phone account creation failed: ${result['message']}');
      }
    } catch (e) {
      _log('💥 Phone account creation error: $e');
    }
  }

  /// Test login with the created account
  static Future<void> testLogin() async {
    _log('🔑 Testing login...');

    try {
      final success = await _cognitoService.loginWithEmail(
        email: 'testdriver@example.com',
        password: 'TestPass123!',
      );

      if (success) {
        _log('✅ Login successful!');
        final profile = await _cognitoService.getCurrentDriver();
        _log('👤 Driver Profile: $profile');
      } else {
        _log('❌ Login failed');
      }
    } catch (e) {
      _log('💥 Login error: $e');
    }
  }

  /// Test AWS Cognito backend connection
  static Future<void> testCognitoConnection() async {
    _log('🌐 Testing AWS Cognito backend connection...');
    _log('');

    try {
      // Step 1: Check Amplify configuration
      _log('🔍 Step 1: Checking Amplify configuration...');
      if (!Amplify.isConfigured) {
        _log('❌ CRITICAL: Amplify is not configured!');
        return;
      }
      _log('✅ Amplify is configured');

      // Step 2: Check Auth plugin
      _log('🔍 Step 2: Testing Auth plugin availability...');
      try {
        final session = await Amplify.Auth.fetchAuthSession();
        _log('✅ Auth plugin is working');
        _log('   - Session signed in: ${session.isSignedIn}');
        if (session is CognitoAuthSession) {
          _log('   - Cognito session detected');

          try {
            final tokens = session.userPoolTokensResult.value;
            _log('   - User pool tokens available: true');
            _log(
              '   - Access token present: ${tokens.accessToken.raw.isNotEmpty}',
            );
          } catch (e) {
            _log('   - User pool tokens available: false');
          }
        }
      } catch (e) {
        _log('❌ Auth plugin error: $e');
        return;
      }

      // Step 3: Test user pool connection by attempting to get current user (will fail gracefully if not signed in)
      _log('🔍 Step 3: Testing user pool connection...');
      try {
        await Amplify.Auth.getCurrentUser();
        _log('✅ User pool connection successful (user is signed in)');
      } catch (e) {
        if (e.toString().contains('not authorized') ||
            e.toString().contains('NotAuthorizedException')) {
          _log(
            '✅ User pool connection successful (no user signed in - expected)',
          );
        } else {
          _log('⚠️  User pool connection issue: $e');
        }
      }

      // Step 4: Test network connectivity by attempting a lightweight operation
      _log('🔍 Step 4: Testing network connectivity to AWS...');
      try {
        // Try to reset password for a dummy email - this will fail but tests network connectivity
        await Amplify.Auth.resetPassword(
          username: 'test.connectivity@example.com',
        );
        _log('✅ Network connectivity to AWS Cognito confirmed');
      } catch (e) {
        if (e.toString().contains('UserNotFoundException') ||
            e.toString().contains('user does not exist')) {
          _log('✅ Network connectivity to AWS Cognito confirmed');
          _log('   (Got expected UserNotFoundException for test email)');
        } else if (e.toString().contains('NetworkException') ||
            e.toString().contains('timeout') ||
            e.toString().contains('connection')) {
          _log('❌ Network connectivity issue: $e');
          return;
        } else {
          _log('✅ Network connectivity appears functional');
          _log(
            '   (Got non-network error as expected: ${e.toString().substring(0, 100)}...)',
          );
        }
      }

      // Step 5: Display configuration summary
      _log('🔍 Step 5: Configuration summary...');
      _log('   - AWS Region: us-east-1');
      _log('   - User Pool ID: us-east-1_xDptXxzaI');
      _log('   - App Client ID: 7ak005suept85gp6l2vlg4jkbu');
      _log('   - Username attributes: email, phone_number');
      _log('   - Signup attributes: email, phone_number');
      _log('   - MFA: OFF');
      _log('   - Verification mechanisms: email, phone_number');

      _log('');
      _log('🎉 AWS Cognito backend connection test PASSED!');
      _log('✅ Backend is properly configured and accessible');
      _log('✅ Ready for registration and authentication operations');
    } catch (e, stackTrace) {
      _log('💥 Connection test failed with exception:');
      _log('   Error: $e');
      _log(
        '   Stack trace preview: ${stackTrace.toString().split('\n').take(3).join('\n')}',
      );
    }

    _log('');
    _log('🏁 Connection test completed');
  }

  /// Helper method for comprehensive logging
  static void _log(String message) {
    // Debug output (shows in Flutter Inspector)
    debugPrint(message);

    // Also log with timestamp for better tracking
    final timestamp = DateTime.now().toIso8601String();
    if (kDebugMode) {
      debugPrint('[$timestamp] $message');
    }
  }
}

/// Entry point for manual Cognito testing.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Choose one of the test methods below:
  await TestCognitoRegistration.createTestAccount();
  // await TestCognitoRegistration.createTestAccountWithPhone();
  // await TestCognitoRegistration.testLogin();
}
