# AWS Cognito + DynamoDB Driver Profile Architecture (Dev)

## Summary

- Registration uses Cognito only for core attributes (email/phone, name).
- Custom driver attributes were removed from Cognito; extended data is stored in DynamoDB.
- Post Confirmation Lambda creates a baseline driver profile in table `DriverProfiles_dev`.
- HTTP API (API Gateway v2) with Cognito JWT authorizer exposes GET/PUT `/driver/me`.
- Flutter app fetches and updates the profile via this API using the Cognito access token.

## AWS Resources (provisioned by backend/deploy.py)

1) DynamoDB table: `DriverProfiles_dev`
   - PK: driverId (String)
   - GSIs: email-index, phone-index
   - Billing: On-Demand
   - SSE: Enabled

2) Lambdas
   - `driver-profile-post-confirmation`: Cognito trigger, PutItem baseline profile
   - `driver-profile-api`: HTTP API handler, GET/PUT `/driver/me`

3) API Gateway HTTP API
   - Name: `driver-profile-api-dev`
   - Authorizer: JWT (Issuer = Cognito User Pool, Audience = App Client ID)
   - Routes: GET `/driver/me`, PUT `/driver/me`

4) IAM
   - Trigger Lambda role: dynamodb:PutItem + logs
   - API Lambda role: dynamodb:GetItem, dynamodb:UpdateItem + logs

## App Integration

- `AWSDynamoDBService`
  - configure(baseUrl, authToken)
  - GET `/driver/me` with retry/backoff after confirmation
  - PUT `/driver/me` to save registration and to update fields
- `CognitoAuthService`
  - After sign-in: configures AWSDynamoDBService and merges profile
  - After phone confirmation: warms read and persists pending registration fields
- `DriverService`
  - If AWS enabled, reads/updates via HTTP API; otherwise uses legacy ApiService

## Pending/Actions

- Set Environment.apiBaseUrl to deployed value: https://{apiId}.execute-api.{region}.amazonaws.com/dev
- Re-run deploy.py with --app-client-id vjcumd2cck66kprpc86nmgs9t if audience not set
- Wire profile screens to update via DriverService (now backed by AWSDynamoDBService)
- Tests: signup -> confirmation -> GET `/driver/me` exists (with retry)
- Security: keep least privilege; consider KMS CMK, redact PII in logs

## Notes

- Iraqi phone normalization enforced; Arabic error messages included.
- Baseline status values: PENDING_PROFILE -> PENDING_REVIEW -> VERIFIED.
