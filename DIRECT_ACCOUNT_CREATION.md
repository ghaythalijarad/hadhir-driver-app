# Direct AWS Cognito Account Creation

## Summary

✅ **Successfully implemented**: Direct AWS Cognito user registration without UI navigation

## What was implemented

### 1. AWS Cognito Configuration

- **User Pool ID**: `us-east-1_usoTs2VtS`
- **App Client ID**: `7ak005suept85gp6l2vlg4jkbu`
- **Region**: `us-east-1`
- **User Pool Name**: `wizzgo-dev-users`

### 2. Direct Account Creation Service

Created `TestCognitoRegistration` class with methods:

- `createTestAccount()` - Creates account with email
- `createTestAccountWithPhone()` - Creates account with phone number
- `testLogin()` - Tests login with created account

### 3. UI Integration

Added a **"إنشاء حساب تجريبي مباشر"** button to the login screen that:

- Creates an account directly via AWS Cognito API
- Shows console logs with registration results
- Bypasses the registration form UI

### 4. Test Account Details

Default test account that will be created:

```
Email: testdriver@example.com
Password: TestPass123!
Name: سائق تجريبي
Phone: 07701234567
City: بغداد
Vehicle Type: دراجة نارية
License: DL123456789
National ID: 12345678901
```

## How to use

1. **Run the app** on iOS simulator
2. **Click** the orange button "إنشاء حساب تجريبي مباشر"
3. **Check console logs** for registration results
4. **Handle email verification** if required by Cognito
5. **Login** with the created account

## Expected Console Output

```
🚀 Starting account creation...
Email: testdriver@example.com
Phone: 07701234567
✅ Account created successfully!
Message: تم إنشاء الحساب. يرجى التحقق من بريدك الإلكتروني
📧 Email confirmation required
```

## Notes

- **Email verification may be required** depending on Cognito settings
- **Check AWS Cognito console** to see created users
- **Custom attributes** (city, vehicle_type, license_number, national_id) are stored
- **Production accounts** should use real email addresses for verification

## AWS Cognito Console Check

1. Go to AWS Console > Amazon Cognito
2. Select User pools > wizzgo-dev-users  
3. Go to Users tab
4. Look for newly created test users

## Error Handling

The service includes Arabic error messages for common scenarios:

- User already exists
- Invalid password format
- Network errors
- Verification code issues
