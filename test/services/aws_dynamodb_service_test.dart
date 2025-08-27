import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hadhir_driver/services/aws_dynamodb_service.dart';

void main() {
  group('AWSDynamoDBService', () {
    setUp(() {
      AWSDynamoDBService.configure(
        baseUrl: 'https://api.example.com/dev',
        authToken: 'token',
      );
    });

    test('filters empty strings on updateDriverProfile', () async {
      final requests = <http.Request>[];
      AWSDynamoDBService.setHttpClient(
        MockClient((request) async {
          requests.add(request);
          expect(request.method, 'PUT');
          expect(
            request.url.toString(),
            'https://api.example.com/dev/driver/me',
          );
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          // Empty string should be filtered out
          expect(body.containsKey('city'), false);
          // Non-empty values should be present
          expect(body['name'], 'Ali');
          expect(body['vehicleType'], 'car');
          return http.Response('{"ok":true}', 200);
        }),
      );

      final ok = await AWSDynamoDBService().updateDriverProfile({
        'name': 'Ali',
        'city': '', // should be filtered
        'vehicleType': 'car',
      });
      expect(ok, true);
      expect(requests.length, 1);
    });

    test('getDriverProfile retries then succeeds', () async {
      int call = 0;
      AWSDynamoDBService.setHttpClient(
        MockClient((request) async {
          call++;
          if (call < 3) {
            return http.Response('Not found', 404);
          }
          return http.Response(
            jsonEncode({
              'data': {'driverId': 'sub-123', 'name': 'Ali'},
            }),
            200,
          );
        }),
      );

      final t0 = DateTime.now();
      final data = await AWSDynamoDBService().getDriverProfile(
        'self',
        maxRetries: 3,
      );
      final elapsed = DateTime.now().difference(t0);

      expect(data, isNotNull);
      expect(data!['name'], 'Ali');
      // Should have taken some time due to retries
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(500));
    });
  });
}
