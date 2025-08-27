import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/driver_websocket_service.dart';
import '../../services/aws_dynamodb_service.dart';
import '../../services/new_auth_service.dart';
import '../../services/cognito_auth_service.dart';
import '../../models/driver_status.dart';
import '../../config/app_config.dart';
import '../../services/logging/auth_logger.dart';

/// Provides a singleton instance of [DriverWebSocketService].
final driverWebSocketServiceProvider = Provider<DriverWebSocketService>((ref) {
  final service = DriverWebSocketService();
  service.attachLogger(ref.read(authLoggerProvider));
  return service;
});

/// Provides a singleton instance of [AWSDynamoDBService].
final awsDynamoDBServiceProvider = Provider<AWSDynamoDBService>((ref) {
  return AWSDynamoDBService();
});

/// Provides an instance of [NewAuthService], injecting its dependencies.
final newAuthServiceProvider = Provider<NewAuthService>((ref) {
  final wsService = ref.watch(driverWebSocketServiceProvider);
  final logger = ref.watch(authLoggerProvider);
  return NewAuthService(webSocketService: wsService, logger: logger);
});

/// Provides an instance of [CognitoAuthService] for AWS Cognito authentication
final cognitoAuthServiceProvider = Provider<CognitoAuthService>((ref) {
  final service = CognitoAuthService();
  service.logger = ref.watch(authLoggerProvider);
  return service;
});

/// Provides the appropriate auth service based on configuration
final authServiceProvider = Provider<dynamic>((ref) {
  if (AppConfig.enableAWSIntegration) {
    return ref.watch(cognitoAuthServiceProvider);
  } else {
    return ref.watch(newAuthServiceProvider);
  }
});

/// Provides driver status state management
final driverStatusProvider = StateProvider<DriverStatus>((ref) {
  return DriverStatus.offline;
});

/// Provides a singleton instance of [AuthLogger]
final authLoggerProvider = Provider<AuthLogger>((ref) {
  return AuthLogger();
});

// NOTE: unifiedWebSocketServiceProvider was removed here to avoid duplication.
// See `driver_connection_provider.dart` for the active implementation & disposal logic.
