import 'package:flutter/material.dart';
import '../services/cognito_auth_service.dart';
import '../config/environment.dart';

class EmailVerificationTestScreen extends StatefulWidget {
  const EmailVerificationTestScreen({super.key});

  @override
  State<EmailVerificationTestScreen> createState() => _EmailVerificationTestScreenState();
}

class _EmailVerificationTestScreenState extends State<EmailVerificationTestScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  
  bool _isLoading = false;
  String _status = '';
  String? _userId;
  
  final CognitoAuthService _cognitoService = CognitoAuthService();
  
  @override
  void initState() {
    super.initState();
    // Pre-fill with test data
    _emailController.text = 'test.hadhir.email@gmail.com';
    _phoneController.text = '07801234567';
    _nameController.text = 'Test User';
  }

  Future<void> _testRegistration() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting registration test...';
    });

    try {
      _status = 'Environment check:\n';
      _status += 'User Pool ID: ${Environment.cognitoUserPoolId}\n';
      _status += 'App Client ID: ${Environment.cognitoAppClientId}\n';
      _status += 'Region: ${Environment.awsRegion}\n\n';
      
      _status += 'Attempting registration with email verification...\n';
      setState(() {});

      final result = await _cognitoService.registerWithEmail(
        email: _emailController.text.trim(),
        password: 'TempPassword123!',
        phone: _phoneController.text.trim(),
        fullName: _nameController.text.trim(),
        city: 'Test City',
        vehicleType: 'Test Vehicle',
        licenseNumber: 'Test123',
        nationalId: '1234567890',
      );

      if (result['success'] == true) {
        _userId = result['userId'];
        _status += 'SUCCESS: Registration initiated!\n';
        _status += 'User ID: $_userId\n';
        _status += 'Email verification code should be sent to: ${_emailController.text}\n';
        _status += 'Check your email and enter the code below.\n';
      } else {
        _status += 'REGISTRATION FAILED:\n';
        _status += 'Error: ${result['error']}\n';
      }
    } catch (e) {
      _status += 'EXCEPTION during registration:\n';
      _status += e.toString();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testEmailCodeVerification() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _status += '\nPlease enter the verification code first.\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status += '\nVerifying email code: ${_codeController.text.trim()}\n';
    });

    try {
      final result = await _cognitoService.confirmEmail(
        email: _emailController.text.trim(),
        verificationCode: _codeController.text.trim(),
      );

      if (result) {
        _status += 'SUCCESS: Email verification completed!\n';
        _status += 'User can now sign in normally.\n';
      } else {
        _status += 'EMAIL VERIFICATION FAILED:\n';
        _status += 'Error: Invalid verification code\n';
      }
    } catch (e) {
      _status += 'EXCEPTION during email verification:\n';
      _status += e.toString();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testResendEmailCode() async {
    setState(() {
      _isLoading = true;
      _status += '\nResending email verification code...\n';
    });

    try {
      final result = await _cognitoService.sendEmailVerificationCode(
        email: _emailController.text.trim(),
      );

      if (result['success'] == true) {
        _status += 'SUCCESS: New verification code sent to email!\n';
      } else {
        _status += 'RESEND FAILED:\n';
        _status += 'Error: ${result['error']}\n';
      }
    } catch (e) {
      _status += 'EXCEPTION during resend:\n';
      _status += e.toString();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email Verification Testing',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            ),
            const SizedBox(height: 20),
            
            // User Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Test User Information', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('1. Test Registration & Email Send'),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Verification Code Input
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Email Verification Code',
                border: OutlineInputBorder(),
                hintText: 'Enter the 6-digit code from email',
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testEmailCodeVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('2. Verify Code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testResendEmailCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Resend Code'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Status Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Test Results:', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 300,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _status.isEmpty ? 'Test results will appear here...' : _status,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
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
    _phoneController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}
