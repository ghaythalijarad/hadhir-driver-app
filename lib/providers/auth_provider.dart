import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/realtime_communication_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  Map<String, dynamic>? _currentDriver;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get currentDriver => _currentDriver;
  String? get errorMessage => _errorMessage;

  /// Initialize authentication state
  Future<void> initialize() async {
    debugPrint('🔐 AuthProvider: Initializing authentication state');
    _setLoading(true);

    try {
      await AuthService.initialize();
      debugPrint('🔐 AuthService initialized successfully');

      if (AuthService.isAuthenticated) {
        debugPrint('🔐 User is authenticated, loading driver data');
        debugPrint(
          '🚧 TEMPORARY: Skipping driver data loading during initialization',
        );
        // await _loadCurrentDriver(); // Temporarily disabled

        // Set basic authentication state without loading driver data
        _isAuthenticated = true;
        _errorMessage = null;
      } else {
        debugPrint('🔐 User is not authenticated');
      }
    } catch (e) {
      debugPrint('❌ AuthProvider initialization error: $e');
      _setError('خطأ في تهيئة التطبيق: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load current driver data and initialize real-time services
  Future<void> _loadCurrentDriver() async {
    debugPrint('👤 Loading current driver data...');

    // TEMPORARY: Skip actual data loading to avoid hanging
    debugPrint('🚧 TEMPORARY: Skipping driver data loading, using mock data');
    
    try {
      // Set mock driver data to allow login to proceed
      _currentDriver = {
        'id': 'temp_driver_123',
        'name': 'Test Driver',
        'phone': '+964 777 777 7777',
        'email': 'test@example.com',
        'city': 'Baghdad',
        'vehicle_type': 'motorcycle',
        'status': 'active',
        'is_verified': true,
      };
      
      _isAuthenticated = true;
      _errorMessage = null;
      debugPrint('✅ Mock driver data set successfully');

      // Skip real-time services initialization for now
      debugPrint('🚧 TEMPORARY: Skipping real-time services initialization');
    } catch (e) {
      _isAuthenticated = false;
      _currentDriver = null;
      _setError('خطأ في جلب بيانات السائق: ${e.toString()}');
      debugPrint('❌ Error loading driver data: $e');
    }
  }

  /// Initialize real-time communication services after authentication
  /// Currently disabled to avoid hanging during development
  /*
  Future<void> _initializeRealtimeServices() async {
    if (_currentDriver == null) return;

    try {
      debugPrint('🚀 Initializing real-time communication services...');

      final realtimeService = RealtimeCommunicationService();
      await realtimeService.initialize(
        driverId: _currentDriver!['id'] ?? 'driver_123',
        driverName: _currentDriver!['name'] ?? 'Unknown Driver',
        driverPhone: _currentDriver!['phone'] ?? '+964 770 123 4567',
        authToken: AuthService.authToken ?? 'mock_token',
      );

      debugPrint('✅ Real-time communication services initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize real-time services: $e');
      // Don't fail authentication if real-time services fail to initialize
    }
  }
  */

  /// Login with email and password via offline mock
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 AuthProvider: Login attempt for email: $email');
    _setLoading(true);
    _clearError();

    try {
      // Use phone-based AuthService mock path by mapping email to phone-style login if needed
      // For now, just simulate success path using AuthService.login with a mock phone
      final result = await AuthService.login(phone: email, password: password);

      if (result['success']) {
        debugPrint('✅ Login successful, loading driver data');
        await _loadCurrentDriver();
        return _isAuthenticated;
      } else {
        debugPrint('❌ Login failed: ${result['message']}');
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _setError('خطأ في تسجيل الدخول: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with phone and password
  Future<bool> login({required String phone, required String password}) async {
    debugPrint('🔐 AuthProvider: Login attempt for phone: $phone');
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.login(phone: phone, password: password);

      if (result['success']) {
        debugPrint('✅ Login successful, loading driver data');
        await _loadCurrentDriver();
        return _isAuthenticated;
      } else {
        debugPrint('❌ Login failed: ${result['message']}');
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _setError('خطأ في تسجيل الدخول: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new driver
  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required String city,
    required String vehicleType,
    required String licenseNumber,
    required String nationalId,
  }) async {
    debugPrint('📝 AuthProvider: Registration attempt for phone: $phone');
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.register(
        name: name,
        phone: phone,
        password: password,
        city: city,
        vehicleType: vehicleType,
        licenseNumber: licenseNumber,
        nationalId: nationalId,
      );

      if (result['success']) {
        debugPrint('✅ Registration successful');
        await _loadCurrentDriver();
        return true;
      } else {
        debugPrint('❌ Registration failed: ${result['message']}');
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      _setError('خطأ في التسجيل: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send verification code
  Future<bool> sendVerificationCode(String phone) async {
    debugPrint('📱 AuthProvider: Sending verification code to: $phone');
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.sendVerificationCode(phone);

      if (result['success']) {
        debugPrint('✅ Verification code sent successfully');
        return true;
      } else {
        debugPrint('❌ Failed to send verification code: ${result['message']}');
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Send verification code error: $e');
      _setError('خطأ في إرسال رمز التحقق: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify phone number
  Future<bool> verifyPhone(String phone, String code) async {
    debugPrint('✅ AuthProvider: Verifying phone: $phone with code: $code');
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.verifyPhone(phone: phone, code: code);

      if (result['success']) {
        debugPrint('✅ Phone verification successful');
        return true;
      } else {
        debugPrint('❌ Phone verification failed: ${result['message']}');
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Phone verification error: $e');
      _setError('خطأ في التحقق: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword({
    required String phone,
    required String verificationCode,
    required String newPassword,
  }) async {
    debugPrint('🔑 AuthProvider: Resetting password for phone: $phone');
    _setLoading(true);
    _clearError();

    try {
      final result = await AuthService.resetPassword(
        phone: phone,
        code: verificationCode,
        newPassword: newPassword,
      );

      if (result['success']) {
        debugPrint('✅ Password reset successful');
        return true;
      } else {
        debugPrint('❌ Password reset failed: ${result['message']}');
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      _setError('خطأ في إعادة تعيين كلمة المرور: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    debugPrint('🚪 AuthProvider: Logging out user');
    try {
      // Dispose real-time services first
      await _disposeRealtimeServices();
      
      await AuthService.logout();
      _isAuthenticated = false;
      _currentDriver = null;
      _errorMessage = null;
      debugPrint('✅ Logout successful');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Dispose real-time communication services
  Future<void> _disposeRealtimeServices() async {
    try {
      debugPrint('🔌 Disposing real-time communication services...');
      final realtimeService = RealtimeCommunicationService();
      await realtimeService.goOffline();
      realtimeService.dispose();
      debugPrint('✅ Real-time services disposed successfully');
    } catch (e) {
      debugPrint('❌ Failed to dispose real-time services: $e');
    }
  }

  /// Refresh current driver data
  Future<void> refreshDriver() async {
    if (_isAuthenticated) {
      await _loadCurrentDriver();
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// For testing purposes only
  void setAuthenticatedForTesting(bool authenticated) {
    _isAuthenticated = authenticated;
    if (authenticated) {
      _currentDriver = {
        'id': 'test_driver_123',
        'name': 'Test Driver',
        'phone': '07831367435',
        'email': 'test@example.com',
      };
    } else {
      _currentDriver = null;
    }
    notifyListeners();
  }
}
