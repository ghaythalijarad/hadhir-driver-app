import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:hadhir_driver/services/cognito_auth_service.dart';
import 'package:hadhir_driver/services/aws_dynamodb_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('persistPendingRegistrationIfAny returns false when no cache', () async {
    // Arrange
    final service = CognitoAuthService();
    await service.initialize();

    // Act
    final ok = await service.persistPendingRegistrationIfAny();

    // Assert
    expect(ok, false);
  });

  test(
    'persistPendingRegistrationIfAny persists to API and clears cache',
    () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cognito_auth_token', 'token-123');
      await prefs.setString(
        'pending_driver_registration',
        jsonEncode({
          'email': 'ali@example.com',
          'phone': '+9647701234567',
          'name': 'Ali',
          'city': 'Baghdad',
          'vehicleType': 'car',
          'licenseNumber': 'LIC-1',
          'nationalId': 'NAT-1',
          'docs': '',
        }),
      );

      final service = CognitoAuthService();
      await service.initialize();

      http.Request? capturedRequest;
      AWSDynamoDBService.setHttpClient(
        MockClient((request) async {
          capturedRequest = request;
          expect(request.method, 'PUT');
          expect(request.url.path, contains('/driver/me'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['name'], 'Ali');
          expect(body['city'], 'Baghdad');
          expect(body['vehicleType'], 'car');
          expect(body['licenseNumber'], 'LIC-1');
          expect(body['nationalId'], 'NAT-1');
          expect(body['status'], 'PENDING_REVIEW');
          return http.Response('{"ok": true}', 200);
        }),
      );

      // Act
      final ok = await service.persistPendingRegistrationIfAny();

      // Assert
      expect(ok, true);
      expect(capturedRequest, isNotNull);
      expect(prefs.getString('pending_driver_registration'), isNull);
    },
  );
}
