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
          userAttribute: AuthUserAttribute(
            userAttributeKey: AuthUserAttributeKey.email,
            value: email,
          ),
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
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testAuthStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check Auth Status'),
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
