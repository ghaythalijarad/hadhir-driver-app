import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/driver_websocket_service.dart';
import '../../services/new_auth_service.dart';
import '../../services/cognito_auth_service.dart';
import '../../config/app_config.dart';

/// Provides a singleton instance of [DriverWebSocketService].
final driverWebSocketServiceProvider = Provider<DriverWebSocketService>((ref) {
  return DriverWebSocketService();
});

/// Provides an instance of [NewAuthService], injecting its dependencies.
final newAuthServiceProvider = Provider<NewAuthService>((ref) {
  final wsService = ref.watch(driverWebSocketServiceProvider);
  return NewAuthService(webSocketService: wsService);
});

/// Provides an instance of [CognitoAuthService] for AWS Cognito authentication
final cognitoAuthServiceProvider = Provider<CognitoAuthService>((ref) {
  return CognitoAuthService();
});

/// Provides the appropriate auth service based on configuration
final authServiceProvider = Provider<dynamic>((ref) {
  if (AppConfig.enableAWSIntegration) {
    return ref.watch(cognitoAuthServiceProvider);
  } else {
    return ref.watch(newAuthServiceProvider);
  }
});
