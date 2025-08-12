# Legacy Auth Cleanup (August 2025)

Status: LEGACY FILES DELETED. Disabled experimental enhanced auth screens pending final QA decision.

Deleted (confirmed removed):

- lib/features/authentication/screens/cognito_login_screen.dart
- lib/features/authentication/screens/cognito_login_screen_new.dart
- lib/features/authentication/screens/cognito_register_screen.dart
- lib/features/authentication/screens/cognito_phone_verification_screen.dart
- lib/features/authentication/screens/cognito_phone_verification_screen_new.dart
- lib/features/authentication/screens/phone_verification_screen.dart
- lib/providers/cognito_auth_provider.dart

Remaining disabled experimental (*.disabled) candidates for deletion:

- enhanced_cognito_login_screen.dart.disabled
- enhanced_cognito_register_screen.dart.disabled
- enhanced_email_verification_screen.dart.disabled
- enhanced_sms_verification_screen.dart.disabled
- enhanced_dual_verification_screen.dart.disabled
- cognito_auth_provider.dart.disabled
- order_provider.dart.disabled
- notification_provider.dart.disabled

Active retained:

- lib/services/cognito_auth_service.dart
- lib/services/new_auth_service.dart
- new_login_screen.dart / register / forgot-password

Next Steps:

1. End-to-end signup & verification (email + phone) on iOS & Android simulator.
2. Decide if disabled enhanced screens are discarded (recommended) or archived elsewhere.
3. Remove disabled files; rerun analyzer (expect clean) -> update status to COMPLETE.
4. Ensure no static AWS keys remain in any profile (keys rotated & removed locally).
5. Commit changes (git) tagging auth-unification milestone.
