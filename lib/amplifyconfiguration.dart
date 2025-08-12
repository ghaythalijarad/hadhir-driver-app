// Amplify configuration for AWS Cognito User Pool Auth
// Updated for wizz-dev-users pool with wizz-dev-drivers-app client
const amplifyconfig = '''
{
  "UserAgent": "aws-amplify-flutter/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_xDptXxzaI",
            "AppClientId": "vjcumd2cck66kprpc86nmgs9t",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "authenticationFlowType": "USER_SRP_AUTH",
            "socialProviders": [],
            "usernameAttributes": ["email", "phone_number"],
            "signupAttributes": ["email", "phone_number"],
            "passwordProtectionSettings": {
              "passwordPolicyMinLength": 8,
              "passwordPolicyCharacters": []
            },
            "mfaConfiguration": "OFF",
            "mfaTypes": ["SMS"],
            "verificationMechanisms": ["email", "phone_number"]
          }
        }
      }
    }
  }
}
''';
