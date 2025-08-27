import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

/// Test email verification using already configured SSO/Cognito
class SSOEmailTestScreen extends StatefulWidget {
  const SSOEmailTestScreen({super.key});

  @override
  State<SSOEmailTestScreen> createState() => _SSOEmailTestScreenState();
}

class _SSOEmailTestScreenState extends State<SSOEmailTestScreen> {
  final _emailController = TextEditingController(text: 'ghaythallaheebi@gmail.com');
  final _passwordController = TextEditingController(text: 'TestPassword123!');
  final _codeController = TextEditingController();
  
  String _testResults = '';
  bool _isLoading = false;

  void _log(String message) {
    setState(() {
      _testResults += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
    print('SSO_EMAIL_TEST: $message');
  }

  /// Test direct Cognito registration using configured SSO
  Future<void> _testDirectCognitoRegistration() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    _log('🔍 Testing Direct Cognito SSO Email Registration');
    _log('══════════════════════════════════════════════');
    
    try {
      // Check if Amplify is configured
      final isConfigured = Amplify.isConfigured;
      _log('✅ Amplify configured: $isConfigured');
      
      if (!isConfigured) {
        _log('❌ Amplify not configured. Cannot proceed.');
        return;
      }

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      _log('📧 Testing registration for: $email');
      
      // Test direct Amplify Auth registration
      try {
        final result = await Amplify.Auth.signUp(
          username: email,
          password: password,
          options: SignUpOptions(
            userAttributes: {
              AuthUserAttributeKey.email: email,
              AuthUserAttributeKey.name: 'Test User',
              AuthUserAttributeKey.phoneNumber: '+9647701234567',
              // Custom attributes
              const CognitoUserAttributeKey.custom('city'): 'بغداد',
              const CognitoUserAttributeKey.custom('vehicle_type'): 'دراجة نارية',
              const CognitoUserAttributeKey.custom('license_number'): 'DL123456789',
              const CognitoUserAttributeKey.custom('national_id'): '12345678901',
            },
          ),
        );

        _log('✅ Registration call completed');
        _log('   User ID: ${result.userId}');
        _log('   Next Step: ${result.nextStep.signUpStep}');
        _log('   Is signup complete: ${result.isSignUpComplete}');
        
        if (result.nextStep.signUpStep == AuthSignUpStep.confirmSignUp) {
          _log('📧 Email verification required');
          
          // Test sending verification code
          await _testSendVerificationCode(email);
        } else {
          _log('✅ Registration complete without verification');
        }
        
      } on AuthException catch (authError) {
        _log('⚠️  Auth Exception: ${authError.message}');
        
        if (authError.message.contains('UsernameExistsException') || 
            authError.message.contains('already exists')) {
          _log('👤 User already exists. Testing email verification for existing user...');
          await _testSendVerificationCode(email);
        } else {
          _log('❌ Registration failed: ${authError.message}');
        }
      }
      
    } catch (error) {
      _log('❌ Unexpected error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Test sending email verification code
  Future<void> _testSendVerificationCode(String email) async {
    _log('');
    _log('📧 Testing Email Verification Code Sending...');
    
    try {
      // Method 1: Try resending confirmation code
      try {
        await Amplify.Auth.resendSignUpCode(username: email);
        _log('✅ Verification code sent via resendSignUpCode()');
        _log('🔍 Check email inbox for verification code');
        return;
      } on AuthException catch (resendError) {
        _log('⚠️  ResendSignUpCode failed: ${resendError.message}');
      }
      
      // Method 2: Try updating email attribute (triggers verification)
      try {
        await Amplify.Auth.updateUserAttribute(
          userAttributeKey: AuthUserAttributeKey.email,
          value: email,
        );
        _log('✅ Email attribute update initiated (should send verification code)');
        _log('🔍 Check email inbox for verification code');
        return;
      } on AuthException catch (updateError) {
        _log('⚠️  Update email attribute failed: ${updateError.message}');
      }
      
      // Method 3: Try fetching user attributes to get current status
      try {
        final attributes = await Amplify.Auth.fetchUserAttributes();
        _log('📋 Current user attributes:');
        for (final attr in attributes) {
          _log('   ${attr.userAttributeKey.key}: ${attr.value}');
        }
      } on AuthException catch (fetchError) {
        _log('⚠️  Fetch attributes failed: ${fetchError.message}');
      }
      
    } catch (error) {
      _log('❌ Email verification test failed: $error');
    }
  }

  /// Test confirming email verification code
  Future<void> _testConfirmVerificationCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    
    if (code.isEmpty) {
      _log('❌ Please enter verification code');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    _log('');
    _log('🔐 Testing Verification Code Confirmation...');
    _log('Email: $email');
    _log('Code: $code');
    
    try {
      // Method 1: Try confirming signup
      try {
        final result = await Amplify.Auth.confirmSignUp(
          username: email,
          confirmationCode: code,
        );
        
        if (result.isSignUpComplete) {
          _log('✅ Email verification successful!');
          _log('✅ User registration completed');
        } else {
          _log('⚠️  Verification submitted but signup not complete');
          _log('   Next step: ${result.nextStep.signUpStep}');
        }
        return;
      } on AuthException catch (confirmError) {
        _log('⚠️  ConfirmSignUp failed: ${confirmError.message}');
      }
      
      // Method 2: Try confirming user attribute
      try {
        await Amplify.Auth.confirmUserAttribute(
          userAttributeKey: AuthUserAttributeKey.email,
          confirmationCode: code,
        );
        _log('✅ Email attribute verification successful!');
        return;
      } on AuthException catch (attrError) {
        _log('⚠️  ConfirmUserAttribute failed: ${attrError.message}');
      }
      
    } catch (error) {
      _log('❌ Code confirmation failed: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Test current authentication status
  Future<void> _testAuthStatus() async {
    _log('');
    _log('🔍 Checking Current Auth Status...');
    
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      _log('✅ Auth session fetched');
      _log('   Is signed in: ${session.isSignedIn}');
      
      if (session.isSignedIn) {
        final user = await Amplify.Auth.getCurrentUser();
        _log('   User ID: ${user.userId}');
        _log('   Username: ${user.username}');
        
        final attributes = await Amplify.Auth.fetchUserAttributes();
        _log('   User attributes:');
        for (final attr in attributes) {
          _log('     ${attr.userAttributeKey.key}: ${attr.value}');
        }
      }
      
    } catch (error) {
      _log('❌ Auth status check failed: $error');
    }
  }

  /// Advanced email delivery debugging
  Future<void> _debugEmailDelivery() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    _log('🔍 === ADVANCED EMAIL DELIVERY DEBUG ===');
    _log('Time: ${DateTime.now()}');
    _log('══════════════════════════════════════════');
    
    final email = _emailController.text.trim();
    
    // Step 1: AWS Configuration Check
    _log('');
    _log('📋 STEP 1: AWS Configuration Check');
    _log('──────────────────────────────────────');
    _log('🏷️  User Pool ID: us-east-1_90UtBLIfK');
    _log('🏷️  App Client ID: 7s3rvcnp34fr2jp54jmksbdd0s');
    _log('🌍 Region: us-east-1');
    _log('📝 Pool Name: WhizzDrivers');
    
    // Step 2: Check Amplify Configuration
    try {
      final isConfigured = Amplify.isConfigured;
      _log('✅ Amplify configured: $isConfigured');
      
      if (!isConfigured) {
        _log('❌ CRITICAL: Amplify not configured!');
        setState(() => _isLoading = false);
        return;
      }
    } catch (e) {
      _log('❌ Amplify config check failed: $e');
    }
    
    // Step 3: Test registration with unique email
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'test_${timestamp}_$email';
    
    _log('');
    _log('👨‍💻 STEP 2: Registration with Unique Email');
    _log('──────────────────────────────────────────');
    _log('📧 Test email: $testEmail');
    
    try {
      final result = await Amplify.Auth.signUp(
        username: testEmail,
        password: _passwordController.text,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: testEmail,
            AuthUserAttributeKey.name: 'Email Debug User',
          },
        ),
      );
      
      _log('✅ Registration successful!');
      _log('   🆔 User ID: ${result.userId}');
      _log('   📋 Next step: ${result.nextStep.signUpStep}');
      _log('   ✅ Signup complete: ${result.isSignUpComplete}');
      
      if (result.nextStep.codeDeliveryDetails != null) {
        final delivery = result.nextStep.codeDeliveryDetails!;
        _log('   📨 Code delivery details:');
        _log('      📱 Medium: ${delivery.deliveryMedium}');
        _log('      📧 Destination: ${delivery.destination}');
        _log('      🏷️  Attribute: ${delivery.attributeKey}');
        
        if (delivery.deliveryMedium == DeliveryMedium.email) {
          _log('   🎉 SUCCESS: Code should be sent to EMAIL!');
          _log('   📬 Check inbox: ${delivery.destination}');
          _log('   ⏰ Wait 1-2 minutes for delivery');
          _log('   📂 Check spam/junk folder if not in inbox');
        } else if (delivery.deliveryMedium == DeliveryMedium.sms) {
          _log('   ⚠️  WARNING: Code sent to SMS instead of email!');
          _log('   📱 SMS destination: ${delivery.destination}');
          _log('   🔧 This indicates email delivery is not properly configured');
        } else {
          _log('   ❓ Unknown delivery medium: ${delivery.deliveryMedium}');
        }
      } else {
        _log('   ❌ PROBLEM: No code delivery details found!');
        _log('   🔧 This indicates email delivery is NOT configured');
      }
      
    } catch (e) {
      if (e is AuthException) {
        _log('⚠️  Auth exception: ${e.message}');
        _log('   📝 Recovery: ${e.recoverySuggestion}');
        
        if (e.message.contains('UsernameExistsException')) {
          _log('   👤 User already exists - trying resend code');
          
          try {
            await Amplify.Auth.resendSignUpCode(username: testEmail);
            _log('   ✅ Resend code successful');
          } catch (resendError) {
            _log('   ❌ Resend failed: $resendError');
          }
        }
      } else {
        _log('❌ Registration failed: $e');
      }
    }
    
    // Step 4: Check what to verify in AWS Console
    _log('');
    _log('🔧 STEP 3: AWS Console Checks Required');
    _log('─────────────────────────────────────────');
    _log('🌐 Go to: https://console.aws.amazon.com/cognito');
    _log('📝 Navigate to: User Pool us-east-1_90UtBLIfK');
    _log('⚙️  Check "Messaging" tab:');
    _log('   • Email source: Cognito default or SES');
    _log('   • FROM email address configured');
    _log('   • SES domain verified (if using SES)');
    _log('📋 Check "Sign-up experience":');
    _log('   • Required attributes include email');
    _log('   • Email verification enabled');
    _log('📧 Check message templates:');
    _log('   • Email verification template exists');
    _log('   • Subject and message are configured');
    
    _log('');
    _log('🚨 COMMON ISSUES:');
    _log('   • User Pool not configured for email verification');
    _log('   • SES not set up or domain not verified');
    _log('   • Account in SES sandbox mode (limited sending)');
    _log('   • FROM email address not verified in SES');
    _log('   • Email templates missing or malformed');
    _log('   • Verification codes going to spam folder');
    
    _log('');
    _log('🏁 Email delivery debug complete!');
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSO Email Verification Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            
            // Password input
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            
            // Verification code input
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Verification Code (enter after receiving email)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testDirectCognitoRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Test Registration'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testConfirmVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testAuthStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Check Auth Status'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _debugEmailDelivery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('🔍 Debug Email'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Results display
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty ? 'Test results will appear here...' : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}
