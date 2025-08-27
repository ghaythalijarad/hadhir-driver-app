import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/driver_profile.dart';
import '../models/earnings.dart';
import 'api_service.dart';
import '../config/app_config.dart';
import '../config/environment.dart';
import 'aws_dynamodb_service.dart';

class DriverService {
  static const String _baseUrl =
      'https://your-backend-url.com/api/v1'; // Replace with actual backend URL

  // Get driver profile exclusively via AWS when enabled
  static Future<DriverProfile?> getDriverProfile() async {
    try {
      // If AWS integration is enabled, read from DynamoDB API
      if (AppConfig.enableAWSIntegration) {
        debugPrint('DriverService (AWS): Getting driver profile via HTTP API');
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        if (!session.isSignedIn) {
          debugPrint('DriverService (AWS): Not signed in');
          return null;
        }
        final tokens = session.userPoolTokensResult.value;
        AWSDynamoDBService.configure(
          baseUrl: Environment.apiBaseUrl,
          authToken: tokens.accessToken.raw,
        );

        final data = await AWSDynamoDBService().getDriverProfile('self');
        if (data == null) return null;

        // Map API response to DriverProfile JSON schema
        final mapped = {
          'id': data['driverId'] ?? '',
          'name': data['name'] ?? '',
          'phone': data['phone'] ?? '',
          'email': data['email'] ?? '',
          'city': data['city'] ?? '',
          'vehicle_type': data['vehicleType'] ?? '',
          'license_number': data['licenseNumber'] ?? '',
          'national_id': data['nationalId'] ?? '',
          'status': data['status'] ?? 'PENDING_PROFILE',
          'join_date': DateTime.fromMillisecondsSinceEpoch(
            ((data['createdAt'] ?? 0) as int) * 1000,
          ).toIso8601String(),
          'total_deliveries': 0,
          'rating': 0.0,
          'is_verified': (data['status'] == 'VERIFIED'),
          'preferred_language': 'ar',
        };
        return DriverProfile.fromJson(mapped);
      }

      // AWS disabled: legacy profile calls are deprecated
      debugPrint(
        'DriverService: AWS integration disabled; legacy profile API removed',
      );
      return null;
    } catch (e) {
      debugPrint('Error fetching driver profile: $e');
      return null;
    }
  }

  // Update driver profile exclusively via AWS when enabled
  static Future<bool> updateDriverProfile(DriverProfile profile) async {
    try {
      if (AppConfig.enableAWSIntegration) {
        debugPrint('DriverService (AWS): Updating driver profile via HTTP API');
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        if (!session.isSignedIn) return false;
        final tokens = session.userPoolTokensResult.value;
        AWSDynamoDBService.configure(
          baseUrl: Environment.apiBaseUrl,
          authToken: tokens.accessToken.raw,
        );

        final ok = await AWSDynamoDBService().updateDriverProfile({
          'name': profile.name,
          'city': profile.city,
          'vehicleType': profile.vehicleType,
          'licenseNumber': profile.licenseNumber,
          'nationalId': profile.nationalId,
        });
        return ok;
      }

      // AWS disabled: legacy profile API removed
      debugPrint(
        'DriverService: AWS integration disabled; legacy profile API removed',
      );
      return false;
    } catch (e) {
      debugPrint('Error updating driver profile: $e');
      return false;
    }
  }

  // Update vehicle info (limited to supported fields in /driver/me)
  static Future<bool> updateVehicleInfo(VehicleInfo vehicleInfo) async {
    try {
      if (AppConfig.enableAWSIntegration) {
        debugPrint('DriverService (AWS): Updating vehicle info via HTTP API');
        final session =
            await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
        if (!session.isSignedIn) return false;
        final tokens = session.userPoolTokensResult.value;
        AWSDynamoDBService.configure(
          baseUrl: Environment.apiBaseUrl,
          authToken: tokens.accessToken.raw,
        );

        // Backend currently supports updating vehicleType only
        final ok = await AWSDynamoDBService().updateDriverProfile({
          'vehicleType': vehicleInfo.type,
        });
        return ok;
      }

      // Legacy backend path (not supported in this build)
      debugPrint('DriverService (legacy): updateVehicleInfo not supported');
      return false;
    } catch (e) {
      debugPrint('Error updating vehicle info: $e');
      return false;
    }
  }

  // Get earnings data
  static Future<EarningsData?> getEarningsData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/driver/earnings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return EarningsData.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching earnings data: $e');
      return null;
    }
  }

  // Add payment method
  static Future<bool> addPaymentMethod(PaymentMethod paymentMethod) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/payment-methods'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode(paymentMethod.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding payment method: $e');
      return false;
    }
  }

  // Remove payment method
  static Future<bool> removePaymentMethod(String paymentMethodId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/driver/payment-methods/$paymentMethodId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing payment method: $e');
      return false;
    }
  }

  // Update emergency contact
  static Future<bool> updateEmergencyContact(EmergencyContact contact) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/driver/emergency-contact'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode(contact.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating emergency contact: $e');
      return false;
    }
  }

  // Submit feedback
  static Future<bool> submitFeedback({
    required String category,
    required String message,
    int? rating,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'category': category,
          'message': message,
          'rating': rating,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      return false;
    }
  }

  // Get support tickets
  static Future<List<Map<String, dynamic>>> getSupportTickets() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/driver/support/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching support tickets: $e');
      return [];
    }
  }

  // Create support ticket
  static Future<bool> createSupportTicket({
    required String category,
    required String subject,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/support/tickets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'category': category,
          'subject': subject,
          'description': description,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating support ticket: $e');
      return false;
    }
  }

  // Request identity verification
  static Future<bool> requestIdentityVerification() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/verification/identity'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'request_type': 'identity_verification',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting identity verification: $e');
      return false;
    }
  }

  // Update phone number
  static Future<bool> updatePhoneNumber(String newPhoneNumber) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/driver/phone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'phone_number': newPhoneNumber,
          'country_code': '+964', // Iraq country code
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating phone number: $e');
      return false;
    }
  }

  // Emergency action - Share location with emergency contact
  static Future<bool> shareEmergencyLocation() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/emergency/share-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'emergency_type': 'share_location',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error sharing emergency location: $e');
      return false;
    }
  }

  // Report safety issue
  static Future<bool> reportSafetyIssue({
    required String issueType,
    required String description,
    String? location,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/safety/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'issue_type': issueType,
          'description': description,
          'location': location,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error reporting safety issue: $e');
      return false;
    }
  }

  // Submit identity verification documents
  static Future<bool> submitIdentityVerification({
    required File nationalIdFront,
    required File nationalIdBack,
    required File drivingLicense,
    required File selfiePhoto,
  }) async {
    try {
      // Note: In a real implementation, this would use multipart/form-data
      // to upload the files. For now, we'll simulate the upload process.

      final response = await http.post(
        Uri.parse('$_baseUrl/driver/verification/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'national_id_front': nationalIdFront.path,
          'national_id_back': nationalIdBack.path,
          'driving_license': drivingLicense.path,
          'selfie_photo': selfiePhoto.path,
          'submission_timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error submitting identity verification: $e');
      return false;
    }
  }

  // Get emergency contacts
  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/driver/emergency-contacts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => EmergencyContact.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching emergency contacts: $e');
      return [];
    }
  }

  // Add emergency contact
  static Future<bool> addEmergencyContact(EmergencyContact contact) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/emergency-contacts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode(contact.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding emergency contact: $e');
      return false;
    }
  }

  // Delete emergency contact
  static Future<bool> deleteEmergencyContact(EmergencyContact contact) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/driver/emergency-contacts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({'name': contact.name, 'phone': contact.phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting emergency contact: $e');
      return false;
    }
  }

  // Sign out
  static Future<bool> signOut() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
      );

      if (response.statusCode == 200) {
        // Clear local auth token
        ApiService.setAuthToken('');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error signing out: $e');
      return false;
    }
  }

  // Change password
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/driver/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error changing password: $e');
      return false;
    }
  }

  // Delete account
  static Future<bool> deleteAccount({
    required String password,
    required String reason,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/driver/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.authToken}',
        },
        body: jsonEncode({
          'password': password,
          'deletion_reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Clear local auth token after successful deletion
          ApiService.setAuthToken('');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  // Request password reset
  static Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/driver/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting password reset: $e');
      return false;
    }
  }
}
