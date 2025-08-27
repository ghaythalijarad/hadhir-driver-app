// AWS Cognito environment configuration
class Environment {
  // Environment flags
  static const bool isProduction = false;
  static String get environment => 'development';

  // AWS Cognito Configuration - Updated for WhizzDrivers pool (Account: 031857856164)
  static const String awsRegion = 'us-east-1';
  static const String cognitoUserPoolId = 'us-east-1_90UtBLIfK';
  static const String cognitoUserPoolName = 'WhizzDrivers';
  static const String cognitoUserPoolArn =
      'arn:aws:cognito-idp:us-east-1:031857856164:userpool/us-east-1_90UtBLIfK';

  // App Client ID from Cognito User Pool: WhizzDrivers client
  static const String cognitoAppClientId =
      '7s3rvcnp34fr2jp54jmksbdd0s'; // WhizzDrivers client

  // AWS Access Keys for services like SNS
  static const String awsAccessKeyId = 'YOUR_AWS_ACCESS_KEY_ID';
  static const String awsSecretAccessKey = 'YOUR_AWS_SECRET_ACCESS_KEY';

  // API endpoints (update these with your actual backend URLs when available)
  static const String apiBaseUrl =
      'https://yv7qnba4a5.execute-api.us-east-1.amazonaws.com/dev';

  // WebSocket URL (update with unified driver/users/merchants/admin channel)
  static String get webSocketUrl =>
      'wss://rydaqvx17c.execute-api.us-east-1.amazonaws.com/Dev'; // unified WS (authorizer: wizzgo-dev-wss-authorizer)

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
