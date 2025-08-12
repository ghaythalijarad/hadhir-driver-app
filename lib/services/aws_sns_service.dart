import '../config/environment.dart';
import 'package:flutter/foundation.dart';

/// AWS SNS Service for sending SMS notifications to drivers
/// Handles verification codes, order updates, and emergency alerts
class AWSSNSService {
  static final AWSSNSService _instance = AWSSNSService._internal();
  factory AWSSNSService() => _instance;
  AWSSNSService._internal();

  bool _isInitialized = false;
  String _accessKey = '';
  String _secretKey = '';
  String _region = '';

  /// Initialize the AWS SNS service
  Future<void> initialize() async {
    debugPrint('🔔 Initializing AWS SNS Service...');

    _accessKey = Environment.awsAccessKeyId;
    _secretKey = Environment.awsSecretAccessKey;
    _region = Environment.awsRegion;

    debugPrint('📋 AWS Region: $_region');
    debugPrint('🔑 Access Key configured: ${_accessKey.isNotEmpty}');
    debugPrint('🗝️ Secret Key configured: ${_secretKey.isNotEmpty}');

    _isInitialized = true;
    debugPrint('✅ AWS SNS Service initialized successfully');
  }

  /// Send SMS verification code
  Future<bool> sendSMSVerificationCode({
    required String phoneNumber,
    required String verificationCode,
    String? driverName,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ AWS SNS not initialized');
      return false;
    }

    try {
      // Format phone number for Iraqi numbers
      String formattedPhone = _formatIraqiPhoneNumber(phoneNumber);

      // Create verification message in Arabic
      String message = driverName != null
          ? 'مرحباً $driverName،\nرمز التحقق لتطبيق هاضر للسائقين: $verificationCode\nهذا الرمز صالح لمدة 5 دقائق.'
          : 'رمز التحقق لتطبيق هاضر للسائقين: $verificationCode\nهذا الرمز صالح لمدة 5 دقائق.';

      // For development, use mock implementation
      return await _mockSendSMS(phoneNumber: formattedPhone, message: message);
    } catch (e) {
      debugPrint('❌ Error sending SMS: $e');
      return false;
    }
  }

  /// Send order notification SMS
  Future<bool> sendOrderNotificationSMS({
    required String phoneNumber,
    required String driverName,
    required String orderDetails,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ AWS SNS not initialized');
      return false;
    }

    try {
      String formattedPhone = _formatIraqiPhoneNumber(phoneNumber);

      String message =
          'مرحباً $driverName،\n'
          'لديك طلب توصيل جديد:\n'
          '$orderDetails\n'
          'يرجى فتح التطبيق لقبول الطلب.';

      return await _mockSendSMS(phoneNumber: formattedPhone, message: message);
    } catch (e) {
      debugPrint('❌ Error sending order notification SMS: $e');
      return false;
    }
  }

  /// Send emergency SMS
  Future<bool> sendEmergencySMS({
    required String phoneNumber,
    required String driverName,
    required String location,
    required String emergencyType,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ AWS SNS not initialized');
      return false;
    }

    try {
      String formattedPhone = _formatIraqiPhoneNumber(phoneNumber);

      String message =
          '🚨 تنبيه طوارئ - هاضر\n'
          'السائق: $driverName\n'
          'نوع الطارئ: $emergencyType\n'
          'الموقع: $location\n'
          'الوقت: ${DateTime.now().toString()}\n'
          'يرجى التواصل فوراً.';

      return await _mockSendSMS(phoneNumber: formattedPhone, message: message);
    } catch (e) {
      debugPrint('❌ Error sending emergency SMS: $e');
      return false;
    }
  }

  /// Format Iraqi phone numbers for international format
  String _formatIraqiPhoneNumber(String phoneNumber) {
    // Remove any whitespace and special characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // If it starts with +964, it's already formatted
    if (cleaned.startsWith('+964')) {
      return cleaned;
    }

    // If it starts with 964, add the +
    if (cleaned.startsWith('964')) {
      return '+$cleaned';
    }

    // If it starts with 07, replace with +9647
    if (cleaned.startsWith('07')) {
      return '+964${cleaned.substring(1)}';
    }

    // If it starts with 7, add +9647
    if (cleaned.startsWith('7') && cleaned.length == 10) {
      return '+964$cleaned';
    }

    // Default: assume it's an Iraqi number and add +964
    return '+964$cleaned';
  }

  /// Mock SMS sending for development
  Future<bool> _mockSendSMS({
    required String phoneNumber,
    required String message,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('📱 [MOCK SMS] To: $phoneNumber');
    debugPrint('📱 [MOCK SMS] Message: $message');
    debugPrint('✅ [MOCK SMS] Sent successfully');

    return true;
  }

  /// Create SNS topic for driver notifications (mock)
  Future<String?> createDriverNotificationTopic(String driverId) async {
    if (!_isInitialized) {
      debugPrint('❌ AWS SNS not initialized');
      return null;
    }

    final mockTopicArn =
        'arn:aws:sns:$_region:123456789012:hadhir-driver-$driverId-notifications';
    debugPrint('✅ [MOCK] Created SNS topic: $mockTopicArn');
    return mockTopicArn;
  }

  /// Subscribe driver phone to SNS topic (mock)
  Future<bool> subscribeDriverToTopic({
    required String topicArn,
    required String phoneNumber,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ AWS SNS not initialized');
      return false;
    }

    String formattedPhone = _formatIraqiPhoneNumber(phoneNumber);
    debugPrint('✅ [MOCK] Subscribed $formattedPhone to topic: $topicArn');
    return true;
  }

  /// Publish notification to SNS topic (mock)
  Future<bool> publishToTopic({
    required String topicArn,
    required String message,
    String? subject,
  }) async {
    if (!_isInitialized) {
      debugPrint('❌ AWS SNS not initialized');
      return false;
    }

    debugPrint('✅ [MOCK] Published message to topic: $topicArn');
    debugPrint('📢 Message: $message');
    return true;
  }

  bool get isInitialized => _isInitialized;
}
