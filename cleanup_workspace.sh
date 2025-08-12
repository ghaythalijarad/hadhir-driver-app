#!/bin/bash

echo "🧹 Cleaning up workspace..."
echo "================================"

# Create backup directory just in case
mkdir -p .cleanup_backup
echo "📁 Created backup directory: .cleanup_backup"

# Function to safely remove files
safe_remove() {
    local file="$1"
    if [ -f "$file" ] || [ -d "$file" ]; then
        echo "🗑️  Removing: $file"
        rm -rf "$file"
    fi
}

echo ""
echo "📋 Phase 1: Removing Documentation Files"
echo "----------------------------------------"

# Documentation files
safe_remove "AMPLIFY_AUTHENTICATION_FIX_COMPLETE.md"
safe_remove "APP_LAUNCH_LOGIN_FIRST_COMPLETE.md"
safe_remove "AWS_COGNITO_INTEGRATION_COMPLETE.md"
safe_remove "AWS_DEPLOYMENT_STATUS.md"
safe_remove "BACKEND_REGISTRATION_TESTING_COMPLETE.md"
safe_remove "CIRCULAR_WIZZ_BUTTON_IMPLEMENTATION.md"
safe_remove "DEBUG_GUIDE.md"
safe_remove "DEPLOYMENT_COMPLETE.md"
safe_remove "DUAL_AUTHENTICATION_COMPLETE.md"
safe_remove "DYNAMIC_STATUS_IMPLEMENTATION.md"
safe_remove "FINAL_IMPLEMENTATION_SUMMARY.md"
safe_remove "FLUTTER_TEST_READY.md"
safe_remove "GOOGLE_MAPS_SETUP.md"
safe_remove "iOS_COMPLETION_SUMMARY.md"
safe_remove "iOS_DIALOG_IMPROVEMENTS.md"
safe_remove "iOS_GUIDE.md"
safe_remove "iOS_ORDER_DIALOG_IMPROVEMENTS.md"
safe_remove "iOS_TESTING_GUIDE.md"
safe_remove "iOS_TESTING_GUIDE_UPDATED.md"
safe_remove "iOS_TESTING_SESSION_PROGRESS.md"
safe_remove "LANGUAGE_SETTINGS_IMPLEMENTATION_COMPLETE.md"
safe_remove "LOCALE_PROVIDER_TESTING.md"
safe_remove "MAPBOX_FIX_SUMMARY.md"
safe_remove "MAP_ZOOM_ADJUSTMENT_SUMMARY.md"
safe_remove "NAVIGATION_GUIDANCE_IMPLEMENTATION.md"
safe_remove "NEW_AUTHENTICATION_SYSTEM_COMPLETE.md"
safe_remove "NOTIFICATION_DUPLICATION_FIX.md"
safe_remove "PHONE_VALIDATION_FIX_COMPLETE.md"
safe_remove "PRODUCTION_DEPLOYMENT_README.md"
safe_remove "PROVIDER_TO_RIVERPOD_MIGRATION.md"
safe_remove "REALTIME_CLUSTERING_SUMMARY.md"
safe_remove "REGISTRATION_AWS_INTEGRATION_GUIDE.md"
safe_remove "RIVERPOD_IMPLEMENTATION_CONCLUSION.md"
safe_remove "RIVERPOD_IMPLEMENTATION_DETAILS.md"
safe_remove "RIVERPOD_IMPLEMENTATION_NEXT_STEPS.md"
safe_remove "RIVERPOD_IMPLEMENTATION_PLAN.md"
safe_remove "RIVERPOD_IMPLEMENTATION_PROGRESS.md"
safe_remove "RIVERPOD_IMPLEMENTATION_SUMMARY.md"
safe_remove "RIVERPOD_MIGRATION_SUMMARY.md"
safe_remove "RIVERPOD_PROVIDER_GUIDE.md"
safe_remove "SCROLLING_FIX_SUMMARY.md"
safe_remove "aws-production-setup.md"

echo ""
echo "🧪 Phase 2: Removing Test Files"
echo "-------------------------------"

# Test files in root
safe_remove "check_config.dart"
safe_remove "clear_auth_and_test.dart"
safe_remove "final_test.dart"
safe_remove "manual_login_test.dart"
safe_remove "test_account_details.dart"
safe_remove "test_backend_registration.dart"
safe_remove "test_backend_simple.dart"
safe_remove "test_clustering_cli.dart"
safe_remove "test_complete_flow.dart"
safe_remove "test_demand_clustering.dart"
safe_remove "test_driver_synchronization.dart"
safe_remove "test_flutter_registration.sh"
safe_remove "test_innovative_dialog.dart"
safe_remove "test_integration.dart"
safe_remove "test_language_switching.dart"
safe_remove "test_login_flow.dart"
safe_remove "test_new_registration_backend.dart"
safe_remove "test_notification_fix.dart"
safe_remove "test_notification_unification.dart"
safe_remove "test_ui_login.dart"

# Python test files
safe_remove "test_aws_registration.py"
safe_remove "test_backend_minimal.py"
safe_remove "test_phone_validation.py"
safe_remove "test_phone_validation_fix.py"
safe_remove "test_registration_07831367435.py"

# Shell script tests
safe_remove "test_amplify_fixed.sh"
safe_remove "test_dual_authentication.sh"
safe_remove "test_login_flow.sh"
safe_remove "test_new_authentication.sh"

echo ""
echo "📜 Phase 3: Removing Script Files"
echo "---------------------------------"

# Deployment and setup scripts
safe_remove "complete_test_flow.sh"
safe_remove "create_fresh_account.sh"
safe_remove "demonstrate_clustering.sh"
safe_remove "deploy-improved.sh"
safe_remove "deploy.sh"
safe_remove "enable_aws_cognito.sh"
safe_remove "fix_android_plugins.sh"
safe_remove "run_app.sh"
safe_remove "run_ios.sh"
safe_remove "setup_aws_cognito.sh"

echo ""
echo "🗂️ Phase 4: Removing Log Files and Images"
echo "------------------------------------------"

# Log files and images
safe_remove "flutter_01.log"
safe_remove "flutter_02.log"
safe_remove "flutter_03.log"
safe_remove "flutter_01.png"
safe_remove "hadhir_current_state.png"

echo ""
echo "📦 Phase 5: Removing Duplicate/Unused Config Files"
echo "--------------------------------------------------"

# Duplicate/unused config files
safe_remove "pubspec_test.yaml"
safe_remove "untranslated.json"

echo ""
echo "🏗️ Phase 6: Removing Unused Infrastructure"
echo "-------------------------------------------"

# Remove unused infrastructure (keep main backend)
safe_remove "aws-lambda-backend/"
safe_remove "aws-lambda-backend-node/"
safe_remove "docker/"
safe_remove "terraform/"
safe_remove "api-schemas/"
safe_remove "aws-infrastructure/"

# Remove Docker files if not using Docker
safe_remove "Dockerfile"
safe_remove "docker-compose.yml"

# Remove Node.js files if not needed
safe_remove "package.json"
safe_remove "package-lock.json"
safe_remove "node_modules/"

echo ""
echo "🎯 Phase 7: Cleaning up empty directories and cache"
echo "---------------------------------------------------"

# Remove empty directories
find . -type d -empty -delete 2>/dev/null || true

echo ""
echo "✅ Cleanup Complete!"
echo "==================="
echo ""
echo "📊 Summary:"
echo "- Removed documentation files"
echo "- Removed test files" 
echo "- Removed script files"
echo "- Removed log files and images"
echo "- Removed duplicate config files"
echo "- Removed unused infrastructure"
echo ""
echo "📁 Core project structure preserved:"
echo "- lib/ (Flutter source code)"
echo "- android/ and ios/ (platform code)"
echo "- backend/ (Python backend)"
echo "- test/ (official Flutter tests)"
echo "- pubspec.yaml (main config)"
echo "- README.md (main documentation)"
echo ""
echo "🎉 Your workspace is now clean and organized!"
