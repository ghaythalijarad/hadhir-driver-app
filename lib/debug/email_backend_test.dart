import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';

/// Simple email verification test that can be run from the Flutter app
class EmailBackendTest {
  static Future<void> runTest() async {
    debugPrint('🔍 === EMAIL VERIFICATION BACKEND TEST ===');
    
    await _ensureAmplifyConfigured();
    await _testCurrentUserStatus();
    await _testEmailVerificationRequest();
    await _testNewUserRegistration();
    
    debugPrint('🏁 Email backend test completed');
  }
  
  static Future<void> _ensureAmplifyConfigured() async {
    debugPrint('\n🔧 Checking Amplify configuration...');
    
    if (!Amplify.isConfigured) {
      debugPrint('❌ Amplify not configured');
      return;
    }
    
    debugPrint('✅ Amplify is configured');
    
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      debugPrint('   Current session signed in: ${session.isSignedIn}');
      
      if (session.isSignedIn) {
        final user = await Amplify.Auth.getCurrentUser();
        debugPrint('   Current user: ${user.username}');
      }
    } catch (e) {
      debugPrint('   ⚠️  Session check error: $e');
    }
  }
  
  static Future<void> _testCurrentUserStatus() async {
    debugPrint('\n👤 Testing current user status...');
    
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        debugPrint('ℹ️  No user signed in');
        return;
      }
      
      final user = await Amplify.Auth.getCurrentUser();
      debugPrint('✅ Current user: ${user.username}');
      
      final attributes = await Amplify.Auth.fetchUserAttributes();
      debugPrint('📋 User attributes:');
      
      bool hasEmail = false;
      bool emailVerified = false;
      bool hasPhone = false;
      bool phoneVerified = false;
      
      for (final attr in attributes) {
        final key = attr.userAttributeKey;
        final value = attr.value;
        
        if (key == AuthUserAttributeKey.email) {
          hasEmail = true;
          debugPrint('   📧 Email: $value');
        } else if (key == AuthUserAttributeKey.emailVerified) {
          emailVerified = value == 'true';
          debugPrint('   ✅ Email verified: $emailVerified');
        } else if (key == AuthUserAttributeKey.phoneNumber) {
          hasPhone = true;
          debugPrint('   📱 Phone: $value');
        } else if (key == AuthUserAttributeKey.phoneNumberVerified) {
          phoneVerified = value == 'true';
          debugPrint('   ✅ Phone verified: $phoneVerified');
        }
      }
      
      debugPrint('\n📊 Status Summary:');
      debugPrint('   Has email: $hasEmail, verified: $emailVerified');
      debugPrint('   Has phone: $hasPhone, verified: $phoneVerified');
      
      if (hasEmail && hasPhone) {
        debugPrint('   ⚠️  User has both email and phone - Cognito may default to SMS');
      }
      
    } catch (e) {
      debugPrint('❌ Failed to get user status: $e');
    }
  }
  
  static Future<void> _testEmailVerificationRequest() async {
    debugPrint('\n📧 Testing email verification request...');
    
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        debugPrint('ℹ️  No user signed in for email verification test');
        return;
      }
      
      debugPrint('🔄 Sending email verification code...');
      
      final result = await Amplify.Auth.sendUserAttributeVerificationCode(
        userAttributeKey: AuthUserAttributeKey.email,
      );
      
      debugPrint('✅ Email verification code sent successfully!');
      debugPrint('   📨 Delivery details:');
      debugPrint('      Medium: ${result.codeDeliveryDetails.deliveryMedium}');
      debugPrint('      Destination: ${result.codeDeliveryDetails.destination}');
      debugPrint('      Attribute: ${result.codeDeliveryDetails.attributeKey}');
      
      if (result.codeDeliveryDetails.deliveryMedium == DeliveryMedium.email) {
        debugPrint('   ✅ Code sent via EMAIL');
      } else if (result.codeDeliveryDetails.deliveryMedium == DeliveryMedium.sms) {
        debugPrint('   📱 Code sent via SMS (not email!)');
      }
      
    } catch (e) {
      debugPrint('❌ Email verification request failed: $e');
      
      if (e is AuthException) {
        debugPrint('   Error type: ${e.runtimeType}');
        debugPrint('   Message: ${e.message}');
        debugPrint('   Recovery: ${e.recoverySuggestion}');
      }
    }
  }
  
  static Future<void> _testNewUserRegistration() async {
    debugPrint('\n🧪 Testing new user registration with email...');
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'emailtest$timestamp@gmail.com'; // Use Gmail for better delivery
    final testPassword = 'TestPass123!';
    
    debugPrint('📝 Test email: $testEmail');
    
    try {
      final signUpResult = await Amplify.Auth.signUp(
        username: testEmail,
        password: testPassword,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: testEmail,
            AuthUserAttributeKey.name: 'Email Test User',
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
          debugPrint('   ✅ Verification code sent to EMAIL!');
        } else {
          debugPrint('   ⚠️  Verification code NOT sent to email');
        }
      } else {
        debugPrint('   ❌ No code delivery details - this is unexpected');
      }
      
      // Wait a moment then clean up
      await Future.delayed(Duration(seconds: 2));
      
      debugPrint('   🧹 Note: Test user will auto-expire in 7 days if not confirmed');
      
    } catch (e) {
      debugPrint('❌ Registration failed: $e');
      
      if (e is AuthException) {
        debugPrint('   Error type: ${e.runtimeType}');
        debugPrint('   Message: ${e.message}');
        debugPrint('   Recovery: ${e.recoverySuggestion}');
      }
    }
  }
}

/// Widget to run the email test from the app
class EmailTestScreen extends StatefulWidget {
  const EmailTestScreen({super.key});
  
  @override
  State<EmailTestScreen> createState() => _EmailTestScreenState();
}

class _EmailTestScreenState extends State<EmailTestScreen> {
  bool _isRunning = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Backend Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Email Verification Backend Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'This test will check:\n'
              '• Current user status\n'
              '• Email verification functionality\n'
              '• New user registration with email\n\n'
              'Check the debug console for detailed results.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isRunning ? null : _runTest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: _isRunning
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Running Test...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text('Run Email Backend Test', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Note: This test may create a temporary test user account that will auto-expire in 7 days.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _runTest() async {
    setState(() {
      _isRunning = true;
    });
    
    try {
      await EmailBackendTest.runTest();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email backend test completed! Check debug console for results.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Test failed with error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() {
        _isRunning = false;
      });
    }
  }
}
