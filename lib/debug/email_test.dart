import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Simple email test that can be called from debug console
class EmailTest {
  static Future<void> testEmailRegistration() async {
    debugPrint('🧪 === EMAIL REGISTRATION TEST ===');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'backend_test_$timestamp@gmail.com';
    final testPassword = 'TestPass123!';

    debugPrint('📧 Test email: $testEmail');
    debugPrint('🔑 Test password: $testPassword');

    try {
      // Check if Amplify is configured
      if (!Amplify.isConfigured) {
        debugPrint('❌ Amplify not configured');
        return;
      }

      debugPrint('✅ Amplify is configured');

      // Register with email
      debugPrint('🔄 Starting registration...');

      final signUpResult = await Amplify.Auth.signUp(
        username: testEmail,
        password: testPassword,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: testEmail,
            AuthUserAttributeKey.name: 'Backend Test User',
          },
        ),
      );

      debugPrint('✅ Registration successful!');
      debugPrint('   User ID: ${signUpResult.userId}');
      debugPrint('   Sign up complete: ${signUpResult.isSignUpComplete}');
      debugPrint('   Next step: ${signUpResult.nextStep.signUpStep}');

      if (signUpResult.nextStep.codeDeliveryDetails != null) {
        final delivery = signUpResult.nextStep.codeDeliveryDetails!;
        debugPrint('   📨 Code delivery details:');
        debugPrint('      Medium: ${delivery.deliveryMedium}');
        debugPrint('      Destination: ${delivery.destination}');
        debugPrint('      Attribute: ${delivery.attributeKey}');

        if (delivery.deliveryMedium == DeliveryMedium.email) {
          debugPrint('   ✅ SUCCESS: Verification code sent to EMAIL!');
        } else if (delivery.deliveryMedium == DeliveryMedium.sms) {
          debugPrint('   ⚠️  WARNING: Code sent to SMS instead of email');
        } else {
          debugPrint(
            '   ❓ Unknown delivery medium: ${delivery.deliveryMedium}',
          );
        }
      } else {
        debugPrint('   ❌ ERROR: No code delivery details found');
      }

      debugPrint('🏁 Test completed successfully');
    } catch (e) {
      debugPrint('❌ Registration failed: $e');

      if (e is AuthException) {
        debugPrint('   Error type: ${e.runtimeType}');
        debugPrint('   Message: ${e.message}');
        debugPrint('   Recovery suggestion: ${e.recoverySuggestion}');
      }
    }
  }

  static Future<void> testExistingUserEmailVerification() async {
    debugPrint('🧪 === EXISTING USER EMAIL VERIFICATION TEST ===');

    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        debugPrint('ℹ️  No user signed in');
        return;
      }

      final user = await Amplify.Auth.getCurrentUser();
      debugPrint('👤 Current user: ${user.username}');

      // Get user attributes
      final attributes = await Amplify.Auth.fetchUserAttributes();
      debugPrint('📋 User attributes:');

      String? email;
      bool emailVerified = false;

      for (final attr in attributes) {
        debugPrint('   ${attr.userAttributeKey}: ${attr.value}');

        if (attr.userAttributeKey == AuthUserAttributeKey.email) {
          email = attr.value;
        } else if (attr.userAttributeKey ==
            AuthUserAttributeKey.emailVerified) {
          emailVerified = attr.value == 'true';
        }
      }

      if (email == null) {
        debugPrint('❌ No email found for current user');
        return;
      }

      debugPrint('📊 Email status: $email (verified: $emailVerified)');

      if (emailVerified) {
        debugPrint('✅ Email already verified');
        return;
      }

      // Try to send email verification code
      debugPrint('🔄 Sending email verification code...');

      final result = await Amplify.Auth.sendUserAttributeVerificationCode(
        userAttributeKey: AuthUserAttributeKey.email,
      );

      debugPrint('✅ Email verification request successful!');
      debugPrint('   📨 Code delivery details:');
      debugPrint('      Medium: ${result.codeDeliveryDetails.deliveryMedium}');
      debugPrint(
        '      Destination: ${result.codeDeliveryDetails.destination}',
      );
      debugPrint('      Attribute: ${result.codeDeliveryDetails.attributeKey}');

      if (result.codeDeliveryDetails.deliveryMedium == DeliveryMedium.email) {
        debugPrint('   ✅ SUCCESS: Code sent to EMAIL!');
      } else {
        debugPrint('   ⚠️  WARNING: Code NOT sent to email');
      }
    } catch (e) {
      debugPrint('❌ Email verification test failed: $e');
    }
  }

  static Future<void> runAllTests() async {
    debugPrint('🚀 === RUNNING ALL EMAIL TESTS ===');
    debugPrint('');

    await testEmailRegistration();
    debugPrint('');
    await testExistingUserEmailVerification();
    debugPrint('');

    debugPrint('🏁 === ALL EMAIL TESTS COMPLETED ===');
  }
}

/// Global function that can be called from debug console
void testEmail() {
  EmailTest.runAllTests();
}
