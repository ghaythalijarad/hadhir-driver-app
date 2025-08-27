import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../services/cognito_auth_service.dart';

/// Comprehensive email verification diagnostic tool
/// Tests all aspects of email delivery to identify root causes
class ComprehensiveEmailTestScreen extends StatefulWidget {
  const ComprehensiveEmailTestScreen({super.key});

  @override
  State<ComprehensiveEmailTestScreen> createState() => _ComprehensiveEmailTestScreenState();
}

class _ComprehensiveEmailTestScreenState extends State<ComprehensiveEmailTestScreen> {
  final _emailController = TextEditingController(text: 'ghaythallaheebi@gmail.com');
  final _passwordController = TextEditingController(text: 'TestPassword123!');
  final _codeController = TextEditingController();
  late CognitoAuthService cognito;
  
  String _testResults = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    cognito = CognitoAuthService();
  }

  void _log(String message) {
    setState(() {
      _testResults += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
    print('EMAIL_TEST: $message');
  }

  Future<void> _runComprehensiveDiagnostic() async {
    setState(() {
      _isLoading = true;
      _testResults = '';
    });

    _log('🔍 Starting Comprehensive Email Diagnostic');
    _log('══════════════════════════════════════════');

    // Step 1: Configuration Check
    await _checkConfiguration();

    // Step 2: Amplify Status Check
    await _checkAmplifyStatus();

    // Step 3: User Pool Settings Check
    await _checkUserPoolSettings();

    // Step 4: Test User Registration
    await _testUserRegistration();

    // Step 5: Test Email Verification Code Request
    await _testEmailVerificationRequest();

    _log('══════════════════════════════════════════');
    _log('✅ Diagnostic Complete - Review Results Above');

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkConfiguration() async {
    _log('\n📋 STEP 1: Configuration Check');
    _log('─' * 40);

    try {
      // Check if Amplify is configured
      final isConfigured = Amplify.isConfigured;
      _log('Amplify Configured: $isConfigured');

      if (isConfigured) {
        // Get current user pool info
        final authPlugin = Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);
        _log('Auth Plugin: ${authPlugin.runtimeType}');
        
        // Try to get current configuration details
        try {
          final session = await Amplify.Auth.fetchAuthSession();
          _log('Auth Session Valid: ${session.isSignedIn}');
        } catch (e) {
          _log('Auth Session Error: $e');
        }
      }
    } catch (e) {
      _log('❌ Configuration Error: $e');
    }
  }

  Future<void> _checkAmplifyStatus() async {
    _log('\n🔧 STEP 2: Amplify Status Check');
    _log('─' * 40);

    try {
      final plugins = Amplify.Auth.plugins;
      _log('Auth Plugins Count: ${plugins.length}');
      
      for (final plugin in plugins) {
        _log('Plugin: ${plugin.runtimeType}');
      }

      // Check if we can access Auth category
      final currentUser = await Amplify.Auth.getCurrentUser();
      _log('Current User: ${currentUser.username}');
    } catch (e) {
      _log('No current user (expected if not signed in): ${e.toString().substring(0, 100)}');
    }
  }

  Future<void> _checkUserPoolSettings() async {
    _log('\n⚙️ STEP 3: User Pool Settings Check');
    _log('─' * 40);

    // This would require AWS CLI or direct API calls
    // For now, we'll note what to check manually
    _log('Manual checks needed in AWS Console:');
    _log('1. User Pool → General Settings → Verification');
    _log('2. Check if email verification is REQUIRED');
    _log('3. Check if SES is configured for email sending');
    _log('4. Check email templates and customization');
    _log('5. Verify User Pool ID: us-east-1_90UtBLIfK');
  }

  Future<void> _testUserRegistration() async {
    _log('\n👤 STEP 4: Test User Registration');
    _log('─' * 40);

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _log('❌ Email required for testing');
      return;
    }

    try {
      // First, try to delete user if exists
      try {
        await _deleteTestUser(email);
      } catch (e) {
        _log('Info: User may not exist yet (normal): ${e.toString().substring(0, 50)}');
      }

      _log('Attempting registration for: $email');
      
      // Use the actual CognitoAuthService registration method
      final result = await cognito.registerWithEmail(
        email: email,
        password: _passwordController.text,
        fullName: 'Test User',
        phone: '+9647701234567',
        city: 'بغداد',
        vehicleType: 'دراجة نارية',
        licenseNumber: 'DL123456789',
        nationalId: '12345678901',
      );

      if (result['success'] == true) {
        _log('✅ Registration successful!');
        _log('User ID: ${result['userId']}');
        _log('Next Step: ${result['nextStep']}');
        
        if (result['nextStep'] == 'CONFIRM_SIGN_UP_STEP') {
          _log('🎯 Email verification required - this is correct!');
        }
      } else {
        _log('❌ Registration failed: ${result['error']}');
      }
    } catch (e) {
      _log('❌ Registration exception: $e');
    }
  }

  Future<void> _testEmailVerificationRequest() async {
    _log('\n📧 STEP 5: Test Email Verification Request');
    _log('─' * 40);

    final email = _emailController.text.trim();
    
    try {
      _log('Requesting email verification code for: $email');
      
      // Method 1: Try direct resend confirmation code
      try {
        await Amplify.Auth.resendSignUpCode(username: email);
        _log('✅ Amplify resendSignUpCode called successfully');
      } catch (e) {
        _log('❌ Amplify resendSignUpCode failed: $e');
      }

      // Method 2: Try our service method
      try {
        final result = await cognito.sendEmailVerificationCode(email: email);
        if (result['success'] == true) {
          _log('✅ CognitoAuthService sendEmailVerificationCode successful');
        } else {
          _log('❌ CognitoAuthService sendEmailVerificationCode failed: ${result['error']}');
        }
      } catch (e) {
        _log('❌ CognitoAuthService exception: $e');
      }

      _log('📧 Check your email: $email');
      _log('Note: Email may take 1-5 minutes to arrive');
      _log('Check spam/junk folder if not received');
      
    } catch (e) {
      _log('❌ Email verification request exception: $e');
    }
  }

  Future<void> _deleteTestUser(String email) async {
    try {
      _log('Attempting to clean up test user: $email');
      // Note: This would require admin credentials
      // For now, we'll note this needs manual cleanup
      _log('Note: Test user cleanup should be done via AWS Console if needed');
    } catch (e) {
      _log('User cleanup note: $e');
    }
  }

  Future<void> _testEmailVerification() async {
    final code = _codeController.text.trim();
    final email = _emailController.text.trim();
    
    if (code.isEmpty || email.isEmpty) {
      _log('❌ Email and verification code required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _log('\n🔐 Testing Email Verification');
      _log('Email: $email');
      _log('Code: $code');

      final success = await cognito.confirmEmail(
        email: email, 
        verificationCode: code
      );

      if (success) {
        _log('✅ Email verification successful!');
        _log('User can now sign in normally');
      } else {
        _log('❌ Email verification failed');
      }
    } catch (e) {
      _log('❌ Email verification exception: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Email Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Test Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Test Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code (if received)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _runComprehensiveDiagnostic,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('🔍 Run Full Diagnostic'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: (_isLoading || _codeController.text.isEmpty) ? null : _testEmailVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('✅ Test Verification Code'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.terminal, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Diagnostic Results', 
                            style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _testResults = '';
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResults.isEmpty 
                              ? 'Click "Run Full Diagnostic" to start testing...'
                              : _testResults,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
class ComprehensiveEmailTest extends StatefulWidget {
  const ComprehensiveEmailTest({super.key});

  @override
  State<ComprehensiveEmailTest> createState() => _ComprehensiveEmailTestState();
}

class _ComprehensiveEmailTestState extends State<ComprehensiveEmailTest> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  String _log = '';
  bool _isRunning = false;
  
  @override
  void initState() {
    super.initState();
    _emailController.text = 'test.hadhir.${DateTime.now().millisecondsSinceEpoch}@gmail.com';
  }

  void _addLog(String message) {
    setState(() {
      _log += '${DateTime.now().toIso8601String().substring(11, 19)} $message\n';
    });
    debugPrint('[EMAIL_TEST] $message');
  }

  void _clearLog() {
    setState(() {
      _log = '';
    });
  }

  Future<void> _runComprehensiveTest() async {
    if (_isRunning) return;
    
    setState(() {
      _isRunning = true;
    });
    
    _clearLog();
    _addLog('🔍 === COMPREHENSIVE EMAIL VERIFICATION TEST ===');
    
    await _testAmplifyConfiguration();
    await _testCognitoUserPoolConnection();
    await _testUserRegistration();
    await _testEmailDeliveryMethods();
    await _testExistingUserEmailVerification();
    
    _addLog('🏁 Test completed. Check results above.');
    
    setState(() {
      _isRunning = false;
    });
  }

  Future<void> _testAmplifyConfiguration() async {
    _addLog('\n📋 === STEP 1: Amplify Configuration ===');
    
    try {
      if (!Amplify.isConfigured) {
        _addLog('❌ CRITICAL: Amplify is not configured!');
        return;
      }
      _addLog('✅ Amplify is configured');
      
      // Test auth session
      final session = await Amplify.Auth.fetchAuthSession();
      _addLog('📱 Auth session status: ${session.isSignedIn ? "Signed In" : "Not Signed In"}');
      
      // Get current auth plugin info
      final authPlugin = Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);
      _addLog('🔧 Auth plugin: ${authPlugin.runtimeType}');
      
    } catch (e) {
      _addLog('❌ Amplify configuration error: $e');
    }
  }

  Future<void> _testCognitoUserPoolConnection() async {
    _addLog('\n🔗 === STEP 2: Cognito User Pool Connection ===');
    
    try {
      // Try to get current user (will fail if not signed in, but tests connection)
      try {
        final user = await Amplify.Auth.getCurrentUser();
        _addLog('👤 Current user: ${user.username} (${user.userId})');
      } catch (e) {
        _addLog('ℹ️  No current user (expected if not signed in)');
      }
      
      // Test if we can interact with Cognito by fetching user attributes
      try {
        final attributes = await Amplify.Auth.fetchUserAttributes();
        _addLog('📋 User attributes count: ${attributes.length}');
      } catch (e) {
        _addLog('ℹ️  Cannot fetch attributes (expected if not signed in)');
      }
      
      _addLog('✅ Cognito connection test completed');
      
    } catch (e) {
      _addLog('❌ Cognito connection error: $e');
    }
  }

  Future<void> _testUserRegistration() async {
    _addLog('\n👤 === STEP 3: User Registration Test ===');
    
    final testEmail = _emailController.text;
    final testPassword = 'TestPass123!';
    
    _addLog('📧 Testing with email: $testEmail');
    
    try {
      // First, check if user already exists by trying to sign in
      try {
        await Amplify.Auth.signIn(
          username: testEmail,
          password: testPassword,
        );
        _addLog('ℹ️  User already exists, signing out...');
        await Amplify.Auth.signOut();
      } catch (e) {
        _addLog('ℹ️  User does not exist (expected)');
      }
      
      // Try to register new user
      _addLog('🔄 Attempting user registration...');
      
      final signUpResult = await Amplify.Auth.signUp(
        username: testEmail,
        password: testPassword,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: testEmail,
            AuthUserAttributeKey.name: 'Test User',
          },
        ),
      );
      
      _addLog('✅ Registration successful!');
      _addLog('🆔 User ID: ${signUpResult.userId}');
      _addLog('📧 Sign up complete: ${signUpResult.isSignUpComplete}');
      _addLog('🔄 Next step: ${signUpResult.nextStep.signUpStep}');
      
      if (signUpResult.nextStep.codeDeliveryDetails != null) {
        final delivery = signUpResult.nextStep.codeDeliveryDetails!;
        _addLog('📨 Code delivery details:');
        _addLog('   📱 Medium: ${delivery.deliveryMedium}');
        _addLog('   📧 Destination: ${delivery.destination}');
        _addLog('   🏷️  Attribute: ${delivery.attributeKey}');
        
        if (delivery.deliveryMedium == DeliveryMedium.email) {
          _addLog('✅ EMAIL delivery confirmed by Cognito!');
        } else {
          _addLog('⚠️  Warning: Delivery medium is not EMAIL: ${delivery.deliveryMedium}');
        }
      } else {
        _addLog('❌ No code delivery details provided by Cognito');
      }
      
    } catch (e) {
      _addLog('❌ Registration failed: $e');
      if (e is AuthException) {
        _addLog('   Error type: ${e.runtimeType}');
        _addLog('   Message: ${e.message}');
        _addLog('   Recovery: ${e.recoverySuggestion}');
      }
    }
  }

  Future<void> _testEmailDeliveryMethods() async {
    _addLog('\n📬 === STEP 4: Email Delivery Methods Test ===');
    
    final testEmail = _emailController.text;
    
    // Test 1: resendSignUpCode
    _addLog('🔄 Testing resendSignUpCode...');
    try {
      final resendResult = await Amplify.Auth.resendSignUpCode(username: testEmail);
      _addLog('✅ resendSignUpCode successful');
      _addLog('   📱 Medium: ${resendResult.codeDeliveryDetails.deliveryMedium}');
      _addLog('   📧 Destination: ${resendResult.codeDeliveryDetails.destination}');
    } catch (e) {
      _addLog('❌ resendSignUpCode failed: $e');
    }
    
    // Test 2: Check if user needs to sign in to send attribute verification
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        _addLog('🔄 Testing sendUserAttributeVerificationCode (signed in)...');
        try {
          final attrResult = await Amplify.Auth.sendUserAttributeVerificationCode(
            userAttributeKey: AuthUserAttributeKey.email,
          );
          _addLog('✅ sendUserAttributeVerificationCode successful');
          _addLog('   📱 Medium: ${attrResult.codeDeliveryDetails.deliveryMedium}');
          _addLog('   📧 Destination: ${attrResult.codeDeliveryDetails.destination}');
        } catch (e) {
          _addLog('❌ sendUserAttributeVerificationCode failed: $e');
        }
      } else {
        _addLog('ℹ️  Cannot test sendUserAttributeVerificationCode (not signed in)');
      }
    } catch (e) {
      _addLog('❌ Session check failed: $e');
    }
    
    // Test 3: Test our service wrapper
    _addLog('🔄 Testing CognitoAuthService.sendEmailVerificationCode...');
    try {
      final cognitoService = CognitoAuthService();
      final serviceResult = await cognitoService.sendEmailVerificationCode(email: testEmail);
      _addLog('✅ Service method result: ${serviceResult['success']}');
      _addLog('   📝 Message: ${serviceResult['message']}');
      if (serviceResult['delivery_message'] != null) {
        _addLog('   📧 Delivery: ${serviceResult['delivery_message']}');
      }
    } catch (e) {
      _addLog('❌ Service method failed: $e');
    }
  }

  Future<void> _testExistingUserEmailVerification() async {
    _addLog('\n👥 === STEP 5: Existing User Email Status ===');
    
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (!session.isSignedIn) {
        _addLog('ℹ️  No user signed in, skipping existing user test');
        return;
      }
      
      final user = await Amplify.Auth.getCurrentUser();
      _addLog('👤 Testing with signed-in user: ${user.username}');
      
      final attributes = await Amplify.Auth.fetchUserAttributes();
      String? emailValue;
      String? emailVerified;
      
      for (final attr in attributes) {
        if (attr.userAttributeKey == AuthUserAttributeKey.email) {
          emailValue = attr.value;
        } else if (attr.userAttributeKey == AuthUserAttributeKey.emailVerified) {
          emailVerified = attr.value;
        }
      }
      
      _addLog('📧 Email: ${emailValue ?? "Not set"}');
      _addLog('✅ Email verified: ${emailVerified ?? "Unknown"}');
      
      if (emailValue != null && emailVerified != 'true') {
        _addLog('🔄 Testing email verification for existing user...');
        try {
          final result = await Amplify.Auth.sendUserAttributeVerificationCode(
            userAttributeKey: AuthUserAttributeKey.email,
          );
          _addLog('✅ Email verification code sent');
          _addLog('   📱 Medium: ${result.codeDeliveryDetails.deliveryMedium}');
          _addLog('   📧 Destination: ${result.codeDeliveryDetails.destination}');
        } catch (e) {
          _addLog('❌ Failed to send verification code: $e');
        }
      }
      
    } catch (e) {
      _addLog('❌ Existing user test failed: $e');
    }
  }

  Future<void> _testCodeVerification() async {
    if (_codeController.text.trim().isEmpty) {
      _addLog('⚠️  Please enter verification code first');
      return;
    }
    
    _addLog('\n🔐 === CODE VERIFICATION TEST ===');
    
    final code = _codeController.text.trim();
    final email = _emailController.text;
    
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: email,
        confirmationCode: code,
      );
      
      _addLog('✅ Code verification successful!');
      _addLog('📧 Sign up complete: ${result.isSignUpComplete}');
      _addLog('🔄 Next step: ${result.nextStep.signUpStep}');
      
    } catch (e) {
      _addLog('❌ Code verification failed: $e');
      if (e is AuthException) {
        _addLog('   Error type: ${e.runtimeType}');
        _addLog('   Message: ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification Diagnostics'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comprehensive Email Test',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Test Configuration', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Test Email Address',
                        border: OutlineInputBorder(),
                        hintText: 'Enter email to test with',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code (if received)',
                        border: OutlineInputBorder(),
                        hintText: 'Enter 6-digit code',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRunning ? null : _runComprehensiveTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isRunning 
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Running Tests...'),
                          ],
                        )
                      : const Text('🔍 Run Comprehensive Test'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testCodeVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('🔐 Test Code Verification'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('🧹 Clear Log'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Diagnostic Results:', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 400,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _log.isEmpty ? '🔍 Run tests to see diagnostic results...' : _log,
                          style: const TextStyle(
                            fontFamily: 'monospace', 
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📋 What This Test Checks:', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      '• Amplify configuration status\n'
                      '• Cognito User Pool connectivity\n'
                      '• User registration with email\n'
                      '• Code delivery method (email vs SMS)\n'
                      '• Multiple email sending approaches\n'
                      '• Existing user email verification\n'
                      '• Code verification process',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}
