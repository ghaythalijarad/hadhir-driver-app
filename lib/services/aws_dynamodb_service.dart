import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AWSDynamoDBService {
  static final AWSDynamoDBService _instance = AWSDynamoDBService._internal();
  factory AWSDynamoDBService() => _instance;
  AWSDynamoDBService._internal();

  // Base URL for the new API Gateway HTTP API (set at runtime from config)
  static String?
  _baseUrl; // e.g., https://abc123.execute-api.us-east-1.amazonaws.com/dev
  static String? _authToken; // Cognito access token (Bearer)

  // Allow injecting a custom HTTP client for testing
  static http.Client _client = http.Client();
  static void setHttpClient(http.Client client) {
    _client = client;
  }

  static void configure({required String baseUrl, required String authToken}) {
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    _authToken = authToken;
  }

  Map<String, String> get _headers {
    final h = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      h[HttpHeaders.authorizationHeader] = 'Bearer $_authToken';
    }
    return h;
  }

  Uri _uri(String path) {
    if (_baseUrl == null) {
      throw StateError(
        'AWSDynamoDBService not configured. Call configure(baseUrl, authToken).',
      );
    }
    return Uri.parse('$_baseUrl$path');
  }

  // Save driver registration data (PUT /driver/me)
  Future<bool> saveDriverRegistration({
    required String driverId,
    required String email,
    required String phoneNumber,
    required Map<String, String> attributes,
  }) async {
    try {
      debugPrint('DynamoDB API - Saving driver registration for: $driverId');
      final body = {
        'name': attributes['name'] ?? '',
        'city': attributes['city'] ?? '',
        'vehicleType': attributes['vehicleType'] ?? '',
        'licenseNumber': attributes['licenseNumber'] ?? '',
        'nationalId': attributes['nationalId'] ?? '',
        'docs': attributes['docs'] ?? '',
      };
      // Only include status if caller explicitly supplied (allows baseline PENDING_PROFILE to remain)
      final status = attributes['status'];
      if (status != null && status.isNotEmpty) {
        body['status'] = status;
      }

      final resp = await _client.put(
        _uri('/driver/me'),
        headers: _headers,
        body: jsonEncode(body),
      );
      debugPrint(
        'DynamoDB API - PUT /driver/me -> ${resp.statusCode}: ${resp.body}',
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) return true;
      return false;
    } catch (e) {
      debugPrint('DynamoDB API - Error saveDriverRegistration: $e');
      return false;
    }
  }

  // Get driver profile with retry/backoff for eventual consistency
  Future<Map<String, dynamic>?> getDriverProfile(
    String driverId, {
    int maxRetries = 5,
  }) async {
    int attempt = 0;
    Duration delay = const Duration(milliseconds: 300);
    while (true) {
      attempt += 1;
      try {
        debugPrint('DynamoDB API - GET /driver/me (attempt $attempt)');
        final resp = await _client.get(_uri('/driver/me'), headers: _headers);
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          return data['data'] as Map<String, dynamic>? ?? data;
        }
        if (resp.statusCode == 404) {
          debugPrint('DynamoDB API - Profile not found (404)');
        } else {
          debugPrint(
            'DynamoDB API - GET failed ${resp.statusCode}: ${resp.body}',
          );
        }
      } catch (e) {
        debugPrint('DynamoDB API - Error getDriverProfile: $e');
      }

      if (attempt >= maxRetries) return null;
      await Future.delayed(delay);
      delay *= 2; // exponential backoff
      if (delay > const Duration(seconds: 5))
        delay = const Duration(seconds: 5);
    }
  }

  // Update driver verification/status (PUT /driver/me)
  Future<bool> updateDriverVerificationStatus({
    required String driverId,
    required bool isVerified,
  }) async {
    try {
      final status = isVerified ? 'VERIFIED' : 'PENDING_REVIEW';
      final resp = await _client.put(
        _uri('/driver/me'),
        headers: _headers,
        body: jsonEncode({'status': status}),
      );
      debugPrint(
        'DynamoDB API - update status -> ${resp.statusCode}: ${resp.body}',
      );
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('DynamoDB API - Error updateDriverVerificationStatus: $e');
      return false;
    }
  }

  // Update driver profile fields (PUT /driver/me) without forcing status changes
  Future<bool> updateDriverProfile(Map<String, dynamic> fields) async {
    try {
      // Filter out empty values to avoid overwriting with blanks
      final body = <String, dynamic>{};
      for (final entry in fields.entries) {
        final v = entry.value;
        if (v is String && v.isEmpty) continue;
        if (v != null) body[entry.key] = v;
      }
      if (body.isEmpty) return true; // nothing to update

      final resp = await _client.put(
        _uri('/driver/me'),
        headers: _headers,
        body: jsonEncode(body),
      );
      debugPrint(
        'DynamoDB API - update profile -> ${resp.statusCode}: ${resp.body}',
      );
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('DynamoDB API - Error updateDriverProfile: $e');
      return false;
    }
  }

  // Location/status/earnings related endpoints are not part of this API yet; keep stubs
  Future<bool> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    required String city,
  }) async {
    debugPrint('DynamoDB API - updateDriverLocation stub');
    return true;
  }

  Future<bool> saveOrderAssignment({
    required String orderId,
    required String driverId,
    required Map<String, dynamic> orderDetails,
  }) async {
    debugPrint('DynamoDB API - saveOrderAssignment stub');
    return true;
  }

  Future<Map<String, dynamic>?> getDriverEarnings(String driverId) async {
    debugPrint('DynamoDB API - getDriverEarnings stub');
    return null;
  }

  Future<bool> updateDriverStatus({
    required String driverId,
    required String status,
  }) async {
    debugPrint('DynamoDB API - updateDriverStatus stub');
    return true;
  }
}
