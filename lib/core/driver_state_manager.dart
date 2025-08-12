import 'package:flutter/material.dart';

import '../services/location_service.dart';
import '../services/order_notification_service.dart';
import '../services/order_service.dart';

/// Manages driver's online/offline state and related functionality
/// Follows single responsibility principle
class DriverStateManager extends ChangeNotifier {
  final LocationService? _locationService;
  final OrderService? _orderService;
  final OrderNotificationService? _orderNotificationService;

  // State variables
  bool _isOnline = false;
  String? _currentZone;
  DateTime? _shiftStartTime;
  bool _isInFullScreenNavigation = false;

  DriverStateManager(
    this._locationService,
    this._orderService,
    this._orderNotificationService,
  );

  // Getters
  bool get isOnline => _isOnline;
  String? get currentZone => _currentZone;
  DateTime? get shiftStartTime => _shiftStartTime;
  bool get isInFullScreenNavigation => _isInFullScreenNavigation;

  Duration? get shiftDuration {
    if (_shiftStartTime == null) return null;
    return DateTime.now().difference(_shiftStartTime!);
  }

  /// Go online and start driver shift
  Future<bool> goOnline({String? selectedZone}) async {
    if (_isOnline) return true;

    try {
      // Start location tracking
      if (_locationService != null) {
        await _locationService.startTracking();
        debugPrint('📍 Location tracking started');
      }

      // Set zone
      _currentZone = selectedZone ?? 'Baghdad';

      // Start order service listening
      if (_orderService != null) {
        _orderService.startListening(city: _currentZone!);
        debugPrint('📋 Order service started listening in $_currentZone');
      }

      // Start notification service and set driver online
      if (_orderNotificationService != null) {
        _orderNotificationService.setDriverOnlineStatus(true);
        debugPrint('🔔 Notification service driver status set to online');
      }

      // Update state
      _isOnline = true;
      _shiftStartTime = DateTime.now();

      notifyListeners();
      debugPrint('✅ Driver went online in zone: $_currentZone');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to go online: $e');
      await _cleanup(); // Cleanup on failure
      return false;
    }
  }

  /// Go offline and end driver shift
  Future<bool> goOffline() async {
    if (!_isOnline) return true;

    try {
      await _cleanup();

      _isOnline = false;
      _currentZone = null;
      _shiftStartTime = null;
      _isInFullScreenNavigation = false;

      notifyListeners();
      debugPrint('✅ Driver went offline');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to go offline: $e');
      return false;
    }
  }

  /// Set full screen navigation mode
  void setFullScreenNavigation(bool isFullScreen) {
    if (_isInFullScreenNavigation != isFullScreen) {
      _isInFullScreenNavigation = isFullScreen;
      notifyListeners();
      debugPrint('🗺️ Full screen navigation: $isFullScreen');
    }
  }

  /// Change working zone
  Future<bool> changeZone(String newZone) async {
    if (!_isOnline || _currentZone == newZone) return true;

    try {
      // Stop current zone listening
      if (_orderService != null) {
        _orderService.stopListening();
      }

      // Update zone
      _currentZone = newZone;

      // Start listening in new zone
      if (_orderService != null) {
        _orderService.startListening(city: newZone);
      }

      notifyListeners();
      debugPrint('📍 Zone changed to: $newZone');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to change zone: $e');
      return false;
    }
  }

  /// Initialize from saved state (when app restarts)
  Future<void> initializeFromSavedState({
    required bool wasOnline,
    String? savedZone,
    DateTime? savedShiftStart,
  }) async {
    if (wasOnline && savedZone != null) {
      _currentZone = savedZone;
      _shiftStartTime = savedShiftStart;
      await goOnline(selectedZone: savedZone);
      debugPrint('🔄 Restored driver state: online in $savedZone');
    }
  }

  /// Cleanup all resources
  Future<void> _cleanup() async {
    try {
      // Stop location tracking
      if (_locationService != null) {
        _locationService.stopTracking();
        debugPrint('📍 Location tracking stopped');
      }

      // Stop order service
      if (_orderService != null) {
        _orderService.stopListening();
        debugPrint('📋 Order service stopped');
      }

      // Stop notification service and set driver offline
      if (_orderNotificationService != null) {
        _orderNotificationService.setDriverOnlineStatus(false);
        debugPrint('🔔 Notification service driver status set to offline');
      }
    } catch (e) {
      debugPrint('⚠️ Cleanup error: $e');
    }
  }

  @override
  void dispose() {
    if (_isOnline) {
      _cleanup(); // Ensure cleanup on dispose
    }
    super.dispose();
  }
}
