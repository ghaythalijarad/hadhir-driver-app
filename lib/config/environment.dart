// AWS Cognito environment configuration
class Environment {
  // Environment flags
  static const bool isProduction = false;
  static String get environment => 'development';

  // AWS Cognito Configuration - Updated for wizz-dev-users pool (Account: 031857856164)
  static const String awsRegion = 'us-east-1';
  static const String cognitoUserPoolId = 'us-east-1_xDptXxzaI';
  static const String cognitoUserPoolName = 'wizz-dev-users';
  static const String cognitoUserPoolArn =
      'arn:aws:cognito-idp:us-east-1:031857856164:userpool/us-east-1_xDptXxzaI';

  // App Client ID from Cognito User Pool: wizz-dev-drivers-app
  static const String cognitoAppClientId =
      'vjcumd2cck66kprpc86nmgs9t'; // wizz-dev-drivers-app client

  // AWS Access Keys for services like SNS
  static const String awsAccessKeyId = 'YOUR_AWS_ACCESS_KEY_ID';
  static const String awsSecretAccessKey = 'YOUR_AWS_SECRET_ACCESS_KEY';

  // API endpoints (update these with your actual backend URLs when available)
  static const String apiBaseUrl =
      'https://your-api-gateway.execute-api.us-east-1.amazonaws.com/dev';

  // WebSocket URL (update with your actual WebSocket endpoint)
  static String get webSocketUrl =>
      'wss://your-websocket-endpoint.execute-api.us-east-1.amazonaws.com/dev';

  // Regional defaults
  static const String defaultCountryCode = '+964';
  static const String defaultLanguage = 'ar';
  static const String defaultTimezone = 'Asia/Baghdad';

  // API endpoints
  static String get authEndpoint => '$apiBaseUrl/auth';
  static String get ordersEndpoint => '$apiBaseUrl/orders';
  static String get driversEndpoint => '$apiBaseUrl/drivers';
  static String get notificationsEndpoint => '$apiBaseUrl/notifications';
}
