import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/location_service.dart';
import '../utils/coordinates.dart';

/// Central application controller that manages all core business logic
/// Follows singleton pattern to ensure single source of truth
class AppController extends ChangeNotifier {
  static final AppController _instance = AppController._internal();
  factory AppController() => _instance;
  AppController._internal();

  // Core managers
  // late final DriverStateManager _driverStateManager; // Removed as per new_code
  // late final OrderManager _orderManager; // Removed as per new_code

  // Services
  // LocationService? _locationService; // Kept from original, but not used in new_code
  // OrderService? _orderService; // Kept from original, but not used in new_code
  // OrderNotificationService? _orderNotificationService; // Kept from original, but not used in new_code
  // DemandAnalysisService? _demandAnalysisService; // Added as per new_code

  // Initialization state
  bool _isInitialized = false;
  bool _isOnline = false; // Added as per new_code
  LatLng? _currentLocation; // Added as per new_code
  String? _selectedZone; // Added as per new_code

  bool get isInitialized => _isInitialized;
  bool get isOnline => _isOnline; // Added as per new_code
  LatLng? get currentLocation => _currentLocation; // Added as per new_code
  String? get selectedZone => _selectedZone; // Added as per new_code

  // Getters for managers
  // DriverStateManager get driverState => _driverStateManager; // Removed as per new_code
  // OrderManager get orderManager => _orderManager; // Removed as per new_code

  /// Initialize the app controller
  Future<void> initialize(BuildContext context) async {
    debugPrint('🎮 AppController: Initializing...');

    if (_isInitialized) {
      debugPrint('✅ AppController already initialized');
      return;
    }

    try {
      // Initialize services
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );
      // final orderService = Provider.of<OrderService>(context, listen: false);
      // final orderNotificationService = Provider.of<OrderNotificationService>(
      //   context,
      //   listen: false,
      // );
      // final demandAnalysisService = Provider.of<DemandAnalysisService>(
      //   context,
      //   listen: false,
      // );

      debugPrint('📍 Initializing LocationService...');
      await locationService.initialize();

      debugPrint('📋 Initializing OrderService...');
      // OrderService initialization is handled internally

      debugPrint('🔔 Initializing OrderNotificationService...');
      // OrderNotificationService initialization is handled internally

      debugPrint('📊 Initializing DemandAnalysisService...');
      // DemandAnalysisService initialization is handled internally

      // Get initial location
      debugPrint('📍 Getting initial location...');
      final location = await locationService.getCurrentLocation();
      if (location != null) {
        _currentLocation = location;
        debugPrint(
          '✅ Initial location set: ${location.latitude}, ${location.longitude}',
        );
      } else {
        debugPrint('⚠️ Could not get initial location');
      }

      _isInitialized = true;
      debugPrint('✅ AppController initialized successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ AppController initialization error: $e');
      rethrow;
    }
  }

  /// Setup communication between managers to avoid tight coupling
  // void _setupManagerCommunication() { // Removed as per new_code
  //   // Driver state changes affect order management
  //   _driverStateManager.addListener(() {
  //     if (_driverStateManager.isOnline) {
  //       _orderManager.startListening();
  //     } else {
  //       _orderManager.stopListening();
  //     }
  //   });

  //   // Order manager notifies driver state of order changes
  //   _orderManager.addListener(() {
  //     notifyListeners(); // Propagate changes to UI
  //   });
  // }

  /// Start driver shift
  Future<bool> startShift({String? selectedZone}) async {
    debugPrint('🚀 AppController: Starting shift with zone: $selectedZone');

    if (!_isInitialized) {
      debugPrint('❌ AppController not initialized');
      return false;
    }

    try {
      _selectedZone = selectedZone;
      _isOnline = true;

      debugPrint('✅ Shift started successfully');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start shift: $e');
      return false;
    }
  }

  /// End driver shift
  Future<bool> endShift() async {
    debugPrint('🛑 AppController: Ending shift');

    if (!_isInitialized) {
      debugPrint('❌ AppController not initialized');
      return false;
    }

    try {
      _isOnline = false;
      _selectedZone = null;

      debugPrint('✅ Shift ended successfully');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Failed to end shift: $e');
      return false;
    }
  }

  /// Accept an order with proper state management
  // Future<bool> acceptOrder(OrderModel order) async { // Removed as per new_code
  //   if (!_isInitialized || !_driverStateManager.isOnline) {
  //     return false;
  //   }

  //   try {
  //     return await _orderManager.acceptOrder(order);
  //   } catch (e) {
  //     debugPrint('❌ Failed to accept order: $e');
  //     return false;
  //   }
  // }

  /// Reject an order
  // Future<bool> rejectOrder(OrderModel order) async { // Removed as per new_code
  //   if (!_isInitialized) return false;

  //   try {
  //     return await _orderManager.rejectOrder(order);
  //   } catch (e) {
  //     debugPrint('❌ Failed to reject order: $e');
  //     return false;
  //   }
  // }

  /// Update order status
  // Future<bool> updateOrderStatus( // Removed as per new_code
  //   String orderId,
  //   marker.OrderStatus newStatus,
  // ) async {
  //   if (!_isInitialized) return false;

  //   try {
  //     return await _orderManager.updateOrderStatus(orderId, newStatus);
  //   } catch (e) {
  //     debugPrint('❌ Failed to update order status: $e');
  //     return false;
  //   }
  // }

  /// Get current active orders
  // List<marker.OrderMarker> get activeOrders { // Removed as per new_code
  //   if (!_isInitialized) return [];
  //   return _orderManager.activeOrders;
  // }

  /// Get available orders
  // List<marker.OrderMarker> get availableOrders { // Removed as per new_code
  //   if (!_isInitialized) return [];
  //   return _orderManager.availableOrders;
  // }

  /// Check if driver is online
  // bool get isOnline { // Removed as per new_code
  //   if (!_isInitialized) return false;
  //   return _driverStateManager.isOnline;
  // }

  /// Get current zone
  // String? get currentZone { // Removed as per new_code
  //   if (!_isInitialized) return null;
  //   return _driverStateManager.currentZone;
  // }

  /// Get current location
  // LatLng? get currentLocation { // Removed as per new_code
  //   if (!_isInitialized || _locationService == null) return null;
  //   return _locationService!.currentLocation;
  // }

  /// Update current location
  Future<void> updateLocation(LatLng location) async {
    debugPrint(
      '📍 AppController: Updating location to ${location.latitude}, ${location.longitude}',
    );
    _currentLocation = location;
    notifyListeners();
  }

  /// Set selected zone
  void setSelectedZone(String zone) {
    debugPrint('🗺️ AppController: Setting selected zone to $zone');
    _selectedZone = zone;
    notifyListeners();
  }

  /// Cleanup resources
  @override
  void dispose() {
    debugPrint('🎮 AppController: Disposing...');
    super.dispose();
  }

  /// Reset controller state (for testing or logout)
  void reset() {
    if (_isInitialized) {
      // _driverStateManager.dispose(); // Removed as per new_code
      // _orderManager.dispose(); // Removed as per new_code
    }
    _isInitialized = false;
    notifyListeners();
  }
}
