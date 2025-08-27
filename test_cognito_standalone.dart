// ignore_for_file: avoid_print
import 'package:flutter/widgets.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

// Amplify configuration for the new user pool
const amplifyConfig = '''
{
  "UserAgent": "aws-amplify-flutter/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_xDptXxzaI",
            "AppClientId": "vjcumd2cck66kprpc86nmgs9t",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "socialProviders": [],
            "usernameAttributes": ["email", "phone_number"],
            "signupAttributes": ["email", "phone_number"],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": []
            },
            "mfaConfiguration": "OFF",
            "mfaTypes": ["SMS"],
            "verificationMechanisms": ["email", "phone_number"]
          }
        }
      }
    }
  }
}
''';

/// Standalone test for Cognito registration
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Standalone Cognito test start');
  try {
    // Configure Amplify
    if (!Amplify.isConfigured) {
      await Amplify.addPlugin(AmplifyAuthCognito());
      await Amplify.configure(amplifyConfig);
      debugPrint('Amplify configured');
    }

    // Test account data
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'testdriver$timestamp@example.com';
    final testPhone = '+9647701234567'; // Iraqi phone format
    final password = 'TestPass123!';
    
    debugPrint('📧 Test Email: $testEmail');
    debugPrint('📱 Test Phone: $testPhone');
    
    // Attempt registration with email
    debugPrint('🔍 Attempting registration with email...');
    
    final userAttributes = <AuthUserAttributeKey, String>{
      AuthUserAttributeKey.email: testEmail,
      AuthUserAttributeKey.phoneNumber: testPhone,
      AuthUserAttributeKey.name: 'Test Driver $timestamp',
      // Custom attributes for driver profile
      const CognitoUserAttributeKey.custom('city'): 'بغداد',
      const CognitoUserAttributeKey.custom('vehicle_type'): 'دراجة نارية',
      const CognitoUserAttributeKey.custom('license_number'): 'DL$timestamp',
      const CognitoUserAttributeKey.custom('national_id'): '1234567890',
    };

    final result = await Amplify.Auth.signUp(
      username: testEmail,
      password: password,
      options: SignUpOptions(userAttributes: userAttributes),
    );

    debugPrint('✅ Registration successful!');
    debugPrint('🆔 User ID: ${result.userId}');
    debugPrint('📧 Sign-up complete: ${result.isSignUpComplete}');
    debugPrint('🔄 Next step: ${result.nextStep.signUpStep.name}');
    
    if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
      debugPrint('📋 Email verification required');
      debugPrint('💌 Check your email at: $testEmail');
    }

  } catch (e, stackTrace) {
    debugPrint('Error: $e');
    if (e is AuthException) {
      debugPrint('Auth Error Message: ${e.message}');
    }
    debugPrint(stackTrace.toString().split('\n').take(3).join('\n'));
  }
  debugPrint('Test completed');
}
