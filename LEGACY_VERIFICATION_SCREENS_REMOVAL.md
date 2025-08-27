# Legacy Verification Screens Removal

Removed disabled legacy enhanced verification & cognito screens that were superseded by unified Riverpod + AuthLogger flows:

Removed files:

- lib/features/authentication/screens/enhanced_email_verification_screen.dart.disabled
- lib/features/authentication/screens/enhanced_sms_verification_screen.dart.disabled
- lib/features/authentication/screens/enhanced_dual_verification_screen.dart.disabled
- lib/features/authentication/screens/enhanced_cognito_login_screen.dart.disabled
- lib/features/authentication/screens/enhanced_cognito_register_screen.dart.disabled
- lib/providers/cognito_auth_provider.dart.disabled

Rationale:

- New flows use `verification_throttle_provider`, `VerificationCodeInput`, and structured logging.
- Disabled files were not referenced anywhere in active code.
- Reduces confusion and dead code surface.

If rollback is ever needed, retrieve from git history prior to commit removing these files.
