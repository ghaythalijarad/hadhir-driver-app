import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Quick setup utility for enabling AWS Cognito integration
class RegistrationModeSetup {
  
  /// Enable AWS Cognito integration for production use
  static Future<void> enableAWSCognito() async {
    await AppConfig.initialize();
    await AppConfig.setForceProductionMode(true);
    await AppConfig.setUseMockData(false);
    
    debugPrint('🚀 AWS Cognito integration enabled!');
    debugPrint('Registration will now save data to AWS Cognito and DynamoDB');
    AppConfig.printConfig();
  }
  
  /// Enable mock data mode for development/testing
  static Future<void> enableMockMode() async {
    await AppConfig.initialize();
    await AppConfig.setForceProductionMode(false);
    await AppConfig.setUseMockData(true);
    
    debugPrint('🧪 Mock mode enabled!');
    debugPrint('Registration will use fake data for testing');
    AppConfig.printConfig();
  }
  
  /// Quick method to check current registration mode
  static Future<String> getCurrentMode() async {
    await AppConfig.initialize();
    
    if (AppConfig.enableAWSIntegration) {
      return '🚀 AWS Cognito Integration (Production Mode)';
    } else {
      return '🧪 Mock Data Mode (Development)';
    }
  }
  
  /// Test the current registration configuration
  static Future<Map<String, dynamic>> testConfiguration() async {
    await AppConfig.initialize();
    
    return {
      'mode': AppConfig.enableAWSIntegration ? 'AWS Cognito' : 'Mock Data',
      'backend_url': AppConfig.backendBaseUrl,
      'aws_integration': AppConfig.enableAWSIntegration,
      'mock_data': AppConfig.enableMockData,
      'force_production': AppConfig.forceProductionMode,
      'environment': AppConfig.environment,
      'aws_config': AppConfig.awsConfig,
      'recommendations': _getRecommendations(),
    };
  }
  
  static List<String> _getRecommendations() {
    final recommendations = <String>[];
    
    if (!AppConfig.enableAWSIntegration) {
      recommendations.add('Enable AWS Cognito for real data persistence');
      recommendations.add('Set Force Production Mode to true in app settings');
    }
    
    if (AppConfig.backendBaseUrl.contains('localhost')) {
      recommendations.add('Update backend URL for production deployment');
    }
    
    if (AppConfig.enableMockData && AppConfig.forceProductionMode) {
      recommendations.add('Disable mock data when using production mode');
    }
    
    return recommendations;
  }
  
  /// Display current configuration in a user-friendly format
  static void showConfigurationDialog(BuildContext context) async {
    final config = await testConfiguration();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 Registration Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Mode: ${config['mode']}', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              Text('Backend URL: ${config['backend_url']}'),
              Text('AWS Integration: ${config['aws_integration'] ? "✅ Enabled" : "❌ Disabled"}'),
              Text('Environment: ${config['environment']}'),
              
              const SizedBox(height: 16),
              const Text('AWS Configuration:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(config['aws_config'] as Map<String, String>).entries
                  .map((e) => Text('${e.key}: ${e.value}')),
              
              if ((config['recommendations'] as List<String>).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...(config['recommendations'] as List<String>)
                    .map((rec) => Text('• $rec')),
              ],
            ],
          ),
        ),
        actions: [
          if (!config['aws_integration'])
            TextButton(
              onPressed: () async {
                await enableAWSCognito();
                if (context.mounted) {
                  Navigator.pop(context);
                  showConfigurationDialog(context); // Refresh dialog
                }
              },
              child: const Text('Enable AWS Cognito'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Extension on BuildContext for easy access
extension RegistrationSetupExtension on BuildContext {
  void showRegistrationConfig() {
    RegistrationModeSetup.showConfigurationDialog(this);
  }
}
