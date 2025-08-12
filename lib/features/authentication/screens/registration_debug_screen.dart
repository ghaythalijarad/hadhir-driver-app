import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/cognito_auth_service.dart';
import '../../../test_cognito_registration.dart';
import '../../../config/app_config.dart';

class RegistrationDebugScreen extends StatefulWidget {
  const RegistrationDebugScreen({super.key});

  @override
  State<RegistrationDebugScreen> createState() => _RegistrationDebugScreenState();
}

class _RegistrationDebugScreenState extends State<RegistrationDebugScreen> {
  final _phoneController = TextEditingController(text: '07901234572');
  final _passwordController = TextEditingController(text: 'TestPassword123!');
  final _nameController = TextEditingController(text: 'Debug UI Test Driver');
  final _licenseController = TextEditingController(text: 'DL789013');
  final _nationalIdController = TextEditingController(text: '1234567893');
  
  final String _selectedCity = 'Baghdad';
  final String _selectedVehicleType = 'motorcycle';
  
  bool _isLoading = false;
  String _result = '';
  String _lastError = '';

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  void _checkConfiguration() async {
    await AppConfig.initialize();
    AppConfig.printConfig();
    
    setState(() {
      _result = '''🔧 Configuration Status:
Backend URL: ${AppConfig.backendBaseUrl}
AWS Integration: ${AppConfig.enableAWSIntegration}
Mock Data: ${AppConfig.enableMockData}
Force Production: ${AppConfig.forceProductionMode}''';
    });
  }

  Future<void> _testRegistration() async {
    setState(() {
      _isLoading = true;
      _lastError = '';
      _result = 'Testing Cognito registration...';
    });

    try {
      debugPrint('🧪 DEBUG: Starting Cognito registration test');
      debugPrint('📱 Phone: ${_phoneController.text}');
      debugPrint('🔒 Password: ${_passwordController.text}');
      debugPrint('🏙️ City: $_selectedCity');
      debugPrint('🏍️ Vehicle: $_selectedVehicleType');
      debugPrint('👤 Name: ${_nameController.text}');
      debugPrint('🔢 License: ${_licenseController.text}');
      debugPrint('🆔 National ID: ${_nationalIdController.text}');

      final cognito = CognitoAuthService();
      final result = await cognito.registerWithPhone(
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        city: _selectedCity,
        vehicleType: _selectedVehicleType,
        licenseNumber: _licenseController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
      );

      debugPrint('🧪 DEBUG: Registration result: $result');

      setState(() {
        if (result['success'] == true) {
          _result = '''✅ Cognito Registration Successful!
Message: ${result['message'] ?? 'N/A'}
User ID: ${result['user_id'] ?? 'N/A'}
Confirmation Required: ${result['phone_verification_required'] ?? result['confirmation_required'] ?? false}''';
        } else {
          _result = '''❌ Cognito Registration Failed:
Message: ${result['message'] ?? 'No message'}
Error: ${result['error'] ?? 'Unknown'}''';
          _lastError = result['message'] ?? 'Unknown error';
        }
      });
    } catch (e) {
      debugPrint('🧪 DEBUG: Registration exception: $e');
      setState(() {
        _result = '''💥 Cognito Registration Exception:
Error: $e''';
        _lastError = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testBackendConnection() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing backend connection...';
    });

    try {
      final response = await AuthService.testConnection();
      setState(() {
        _result = '''🌐 Backend Connection Test:
${response.toString()}''';
      });
    } catch (e) {
      setState(() {
        _result = '''💥 Backend Connection Failed:
Error: $e''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCognitoDirectly() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing AWS Cognito directly...';
    });

    try {
      await TestCognitoRegistration.createTestAccount();
      setState(() {
        _result = '''✅ AWS Cognito Direct Test Completed!
Check the debug console for detailed logs.''';
      });
    } catch (e) {
      setState(() {
        _result = '''💥 AWS Cognito Direct Test Failed:
Error: $e''';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testCognitoRegistration() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing direct Cognito registration...';
    });

    try {
      await TestCognitoRegistration.createTestAccount();
      setState(() {
        _result = '''✅ Cognito Test Completed!
Check the console logs for detailed results.''';
      });
    } catch (e) {
      setState(() {
        _result = '''💥 Cognito Test Failed:
Error: $e''';
      });
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
        title: const Text('Registration Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configuration Check
            ElevatedButton(
              onPressed: _checkConfiguration,
              child: const Text('Check Configuration'),
            ),
            const SizedBox(height: 16),
            
            // Backend Connection Test
            ElevatedButton(
              onPressed: _isLoading ? null : _testBackendConnection,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Test Backend Connection'),
            ),
            const SizedBox(height: 16),

            // Form Fields
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'License Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _nationalIdController,
              decoration: const InputDecoration(
                labelText: 'National ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Test Registration Button
            ElevatedButton(
              onPressed: _isLoading ? null : _testRegistration,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                _isLoading ? 'Testing...' : 'Test Cognito Registration',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            // AWS Cognito Direct Test
            ElevatedButton(
              onPressed: _isLoading ? null : _testCognitoDirectly,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                'Test AWS Cognito Directly',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),

            // Test Cognito Registration Class
            ElevatedButton(
              onPressed: _isLoading ? null : _testCognitoRegistration,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: const Text(
                'Test Cognito Registration Class',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),

            // Results
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Results:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _result.isEmpty ? 'No test run yet' : _result,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  if (_lastError.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Last Error:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _lastError,
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _licenseController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }
}
