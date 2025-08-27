import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import '../config/environment.dart';
import '../services/cognito_auth_service.dart';

class ConfigDebugScreen extends StatefulWidget {
  const ConfigDebugScreen({super.key});

  @override
  State<ConfigDebugScreen> createState() => _ConfigDebugScreenState();
}

class _ConfigDebugScreenState extends State<ConfigDebugScreen> {
  Map<String, dynamic> configInfo = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigInfo();
  }

  Future<void> _loadConfigInfo() async {
    try {
      // Get environment config
      final envConfig = {
        'Environment User Pool ID': Environment.cognitoUserPoolId,
        'Environment App Client ID': Environment.cognitoAppClientId,
        'Environment Region': Environment.awsRegion,
        'Environment Pool Name': Environment.cognitoUserPoolName,
        'Environment': Environment.environment,
      };

      // Try to get Amplify config if available
      Map<String, dynamic> amplifyConfig = {};
      try {
        if (Amplify.isConfigured) {
          final authPlugin = Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey);
          amplifyConfig['Amplify Configured'] = 'Yes';
          amplifyConfig['Auth Plugin'] = authPlugin.runtimeType.toString();
        } else {
          amplifyConfig['Amplify Configured'] = 'No';
        }
      } catch (e) {
        amplifyConfig['Amplify Error'] = e.toString();
      }

      // Test actual service configuration
      Map<String, dynamic> serviceConfig = {};
      try {
        final cognitoService = CognitoAuthService();
        serviceConfig['Service Available'] = 'Yes';
        serviceConfig['Service Type'] = cognitoService.runtimeType.toString();
      } catch (e) {
        serviceConfig['Service Error'] = e.toString();
      }

      setState(() {
        configInfo = {
          'Environment Config': envConfig,
          'Amplify Config': amplifyConfig,
          'Service Config': serviceConfig,
        };
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        configInfo = {'Error': e.toString()};
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration Debug Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                  ),
                  const SizedBox(height: 20),
                  ...configInfo.entries.map((section) => _buildSection(
                        section.key,
                        section.value,
                      )),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loadConfigInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Refresh Configuration'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, dynamic content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            if (content is Map<String, dynamic>)
              ...content.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 160,
                          child: Text(
                            '${entry.key}:',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SelectableText(
                            entry.value.toString(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: entry.key.contains('Pool ID') &&
                                      entry.value.toString().contains('90UtBLIfK')
                                  ? Colors.green
                                  : entry.key.contains('Pool ID') &&
                                          entry.value
                                              .toString()
                                              .contains('xDptXxzaI')
                                      ? Colors.red
                                      : Colors.black87,
                              fontWeight: entry.key.contains('Pool ID')
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
            else
              SelectableText(
                content.toString(),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
          ],
        ),
      ),
    );
  }
}
