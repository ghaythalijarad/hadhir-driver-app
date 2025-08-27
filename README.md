# Hadhir Driver App

A Flutter mobile application for drivers with AWS Cognito authentication and email verification functionality.

## Features

- **User Authentication**: AWS Cognito integration with email/password authentication
- **Email Verification**: Secure email verification during user registration
- **Driver Management**: Comprehensive driver profile and management system
- **Modern UI**: Clean and intuitive Flutter interface
- **Debug Tools**: Comprehensive diagnostic tools for email verification testing

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Authentication**: AWS Amplify with Amazon Cognito
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **Platform**: Android & iOS

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode
- AWS Account with Cognito User Pool configured

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/hadhir-driver-app.git
   cd hadhir-driver-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure AWS Amplify**
   - Ensure `amplifyconfiguration.json` is properly configured
   - Update `lib/config/environment.dart` with your AWS Cognito settings

4. **Run the application**
   ```bash
   flutter run
   ```

## Configuration

### AWS Cognito Setup

The app requires AWS Cognito User Pool configuration. Key configuration files:

- `amplifyconfiguration.json` - AWS Amplify configuration
- `lib/config/environment.dart` - Environment-specific settings
- `lib/amplifyconfiguration.dart` - Dart configuration wrapper

### Email Verification

The app includes comprehensive email verification functionality:

- **Registration Flow**: Users receive verification codes via email
- **Email Confirmation**: Secure code-based email verification
- **Debug Tools**: Built-in diagnostic screens for testing email delivery

## Project Structure

```
lib/
├── config/                 # Configuration files
├── features/
│   └── authentication/     # Authentication screens and logic
├── services/               # Business logic and API services
├── providers/              # Riverpod state management
├── debug/                  # Debug and diagnostic tools
└── main.dart              # Application entry point
```

## Development

### Debug Tools

The app includes several debug screens for development and testing:

- **Config Debug Screen**: Verify runtime configuration
- **Email Verification Test**: Test email delivery functionality
- **Comprehensive Email Test**: Full diagnostic suite
- **SSO Email Test**: Direct AWS Amplify testing

Access debug tools through the login screen (development mode only).

### Testing

Run unit tests:
```bash
flutter test
```

### Building

For Android:
```bash
flutter build apk
```

For iOS:
```bash
flutter build ios
```

## Email Verification Troubleshooting

If email verification codes are not being delivered:

1. Check AWS Cognito User Pool configuration
2. Verify SES (Simple Email Service) settings
3. Use the built-in debug screens to test email delivery
4. Check AWS CloudWatch logs for delivery issues

### Known Issues

- **Email Delivery**: Some email providers may filter verification codes as spam
- **Configuration**: Ensure all AWS services are properly configured and linked

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:

- Create an issue in the GitHub repository
- Check the debug screens for diagnostic information
- Verify AWS Cognito and SES configuration

## Changelog

### Latest Changes

- ✅ Fixed email verification method calls
- ✅ Enhanced Cognito authentication service
- ✅ Added comprehensive debug tools
- ✅ Implemented SSO email testing framework
- ✅ Resolved User Pool ID configuration mismatch
- ✅ Added email-specific verification methods

---

**Status**: Development (Email verification functionality active)
