#!/bin/bash
# Backup and cleanup script for duplicate authentication screens
# This script removes old duplicate authentication screens and keeps only the working "New" ones

echo "🧹 Cleaning up duplicate authentication screens"
echo "============================================="

# Create backup directory
BACKUP_DIR="./backup_auth_screens_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "📦 Created backup directory: $BACKUP_DIR"

# Authentication screens directory
AUTH_DIR="./lib/features/authentication/screens"

# List of old/duplicate screens to remove (keeping the "new_" prefixed working ones)
OLD_SCREENS=(
    "cognito_login_screen.dart"
    "cognito_login_screen_new.dart"
    "cognito_register_screen.dart" 
    "cognito_phone_verification_screen.dart"
    "cognito_phone_verification_screen_new.dart"
    "login_screen.dart"
    "register_screen.dart"
    "phone_verification_screen.dart"
    "forgot_password_screen.dart"
    "new_forgot_password_screen_fixed.dart"
    "registration_debug_screen.dart"
)

# Backup and remove old screens
echo "📋 Backing up and removing old duplicate screens:"
for screen in "${OLD_SCREENS[@]}"; do
    if [ -f "$AUTH_DIR/$screen" ]; then
        echo "  - $screen"
        cp "$AUTH_DIR/$screen" "$BACKUP_DIR/"
        rm "$AUTH_DIR/$screen"
    else
        echo "  - $screen (not found, skipping)"
    fi
done

echo ""
echo "✅ Keeping working screens:"
echo "  - new_login_screen.dart"
echo "  - new_driver_signup_screen.dart"
echo "  - new_phone_verification_screen.dart"
echo "  - new_email_verification_screen.dart"
echo "  - new_forgot_password_screen.dart"

echo ""
echo "🎯 Cleanup completed!"
echo "📦 Backup created at: $BACKUP_DIR"
echo "📁 Check remaining files in: $AUTH_DIR"

# List remaining files
echo ""
echo "📋 Remaining authentication screens:"
ls -1 "$AUTH_DIR"/*.dart 2>/dev/null || echo "No .dart files found"

echo ""
echo "⚠️  Next steps:"
echo "1. Verify the Flutter app builds correctly"
echo "2. Test the authentication flow"
echo "3. Remove backup directory if everything works"
echo "4. Commit changes to version control"
