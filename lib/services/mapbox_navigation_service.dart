import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/mapbox_config.dart';
import '../models/order_model.dart';
import '../utils/coordinates.dart';
import '../services/routing_service.dart';

class MapboxNavigationService extends ChangeNotifier {
  static final MapboxNavigationService _instance = MapboxNavigationService._internal();
  factory MapboxNavigationService() => _instance;
  MapboxNavigationService._internal();

  final RoutingService _routingService = RoutingService();
  bool _isNavigating = false;
  bool _isInitialized = false;
  RouteResult? _currentRoute;
  OrderModel? _currentOrder;
  String? _currentDestinationType; // 'restaurant' or 'customer'
  
  // Navigation state
  double? _distanceRemaining;
  double? _durationRemaining;
  String? _nextInstruction;
  LatLng? _currentLocation;
  
  // Timer for location updates
  Timer? _locationUpdateTimer;
  
  // Getters
  bool get isNavigating => _isNavigating;
  bool get isInitialized => _isInitialized;
  RouteResult? get currentRoute => _currentRoute;
  OrderModel? get currentOrder => _currentOrder;
  String? get currentDestinationType => _currentDestinationType;
  double? get distanceRemaining => _distanceRemaining;
  double? get durationRemaining => _durationRemaining;
  String? get nextInstruction => _nextInstruction;
  LatLng? get currentLocation => _currentLocation;

  /// Initialize Mapbox Navigation Service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Get access token from config to verify Mapbox is configured
      final accessToken = await MapboxConfig.accessToken;
      if (accessToken.isEmpty) {
        debugPrint('❌ MapboxNavigationService: No access token configured');
        return false;
      }

      _isInitialized = true;
      debugPrint('✅ MapboxNavigationService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('❌ MapboxNavigationService initialization failed: $e');
    }
    
    return false;
  }

  /// Start location tracking during navigation
  void _startLocationTracking() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        final newLocation = LatLng(position.latitude, position.longitude);
        
        if (_currentLocation == null || _hasLocationChanged(newLocation)) {
          _currentLocation = newLocation;
          
          // Update navigation progress if we have a route
          if (_currentRoute != null && _currentOrder != null) {
            _updateNavigationProgress();
          }
          
          notifyListeners();
        }
      } catch (e) {
        debugPrint('❌ Failed to get location during navigation: $e');
      }
    });
  }

  /// Check if location has changed significantly
  bool _hasLocationChanged(LatLng newLocation) {
    if (_currentLocation == null) return true;
    
    const double threshold = 0.0001; // About 10 meters
    return ((_currentLocation!.latitude - newLocation.latitude).abs() > threshold ||
            (_currentLocation!.longitude - newLocation.longitude).abs() > threshold);
  }

  /// Update navigation progress
  void _updateNavigationProgress() {
    if (_currentLocation == null || _currentRoute == null || _currentOrder == null) return;
    
    // Calculate remaining distance to destination
    final destination = _currentDestinationType == 'restaurant'
        ? _currentOrder!.restaurantLatLng
        : _currentOrder!.customerLatLng;
    
    final distanceToDestination = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      destination.latitude,
      destination.longitude,
    );
    
    _distanceRemaining = distanceToDestination;
    
    // Estimate remaining time (assuming 30 km/h average)
    _durationRemaining = (distanceToDestination / 1000) / 30 * 3600; // seconds
    
    // Generate simple navigation instruction
    _generateNavigationInstruction(destination);
  }

  /// Generate simple navigation instruction
  void _generateNavigationInstruction(LatLng destination) {
    if (_currentLocation == null) return;
    
    final distance = _distanceRemaining ?? 0;
    
    if (distance < 50) {
      _nextInstruction = 'You have arrived at your destination';
    } else if (distance < 200) {
      _nextInstruction = 'Continue straight for ${distance.toInt()}m';
    } else if (distance < 1000) {
      _nextInstruction = 'Continue on current route for ${(distance/1000).toStringAsFixed(1)}km';
    } else {
      _nextInstruction = 'Follow the route to your destination';
    }
  }

  /// Start navigation to restaurant
  Future<bool> startNavigationToRestaurant(OrderModel order) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final destination = LatLng(
        order.restaurantLocation.latitude,
        order.restaurantLocation.longitude,
      );

      final success = await _startNavigation(destination, 'restaurant', order);
      if (success) {
        _currentOrder = order;
        _currentDestinationType = 'restaurant';
        debugPrint('✅ Started navigation to restaurant: ${order.restaurantName}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to start navigation to restaurant: $e');
      return false;
    }
  }

  /// Start navigation to customer
  Future<bool> startNavigationToCustomer(OrderModel order) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final destination = LatLng(
        order.customerLocation.latitude,
        order.customerLocation.longitude,
      );

      final success = await _startNavigation(destination, 'customer', order);
      if (success) {
        _currentOrder = order;
        _currentDestinationType = 'customer';
        debugPrint('✅ Started navigation to customer: ${order.customerName}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to start navigation to customer: $e');
      return false;
    }
  }

  /// Internal method to start navigation
  Future<bool> _startNavigation(LatLng destination, String type, OrderModel order) async {
    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition();
      final origin = LatLng(position.latitude, position.longitude);

      // Calculate route using routing service
      final routeResult = await _routingService.getRoute(
        start: origin,
        end: destination,
      );

      if (routeResult != null) {
        _currentRoute = routeResult;
        _currentLocation = origin;
        _isNavigating = true;
        _distanceRemaining = routeResult.distanceKm * 1000; // Convert to meters
        _durationRemaining = routeResult.durationMinutes * 60; // Convert to seconds
        
        // Start location tracking
        _startLocationTracking();
        
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Failed to calculate route');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Failed to start navigation: $e');
    }
    
    return false;
  }

  /// Stop current navigation
  Future<void> stopNavigation() async {
    if (_isNavigating) {
      try {
        _locationUpdateTimer?.cancel();
        _onNavigationFinished();
        debugPrint('✅ Navigation stopped');
      } catch (e) {
        debugPrint('❌ Failed to stop navigation: $e');
      }
    }
  }

  /// Cancel current navigation
  Future<void> cancelNavigation() async {
    if (_isNavigating) {
      try {
        _locationUpdateTimer?.cancel();
        _onNavigationCancelled();
        debugPrint('✅ Navigation cancelled');
      } catch (e) {
        debugPrint('❌ Failed to cancel navigation: $e');
      }
    }
  }

  /// Launch external navigation app
  Future<bool> launchExternalNavigation(LatLng destination, {String? destinationName}) async {
    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition();
      final origin = LatLng(position.latitude, position.longitude);
      
      // Try Google Maps first
      final googleMapsUrl = 'https://www.google.com/maps/dir/'
          '${origin.latitude},${origin.longitude}/'
          '${destination.latitude},${destination.longitude}';
      
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
        return true;
      }
      
      // Fallback to Apple Maps on iOS
      final appleMapsUrl = 'http://maps.apple.com/?saddr='
          '${origin.latitude},${origin.longitude}&daddr='
          '${destination.latitude},${destination.longitude}';
      
      if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        await launchUrl(Uri.parse(appleMapsUrl), mode: LaunchMode.externalApplication);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Failed to launch external navigation: $e');
      return false;
    }
  }

  /// Handle navigation finished event
  void _onNavigationFinished() {
    _isNavigating = false;
    _currentRoute = null;
    _distanceRemaining = null;
    _durationRemaining = null;
    _nextInstruction = null;
    _locationUpdateTimer?.cancel();
    
    debugPrint('🏁 Navigation finished to $_currentDestinationType');
    
    // If we just arrived at restaurant, automatically suggest navigation to customer
    if (_currentDestinationType == 'restaurant' && _currentOrder != null) {
      _suggestNavigationToCustomer();
    }
    
    _currentDestinationType = null;
    _currentOrder = null;
    notifyListeners();
  }

  /// Handle navigation cancelled event
  void _onNavigationCancelled() {
    _isNavigating = false;
    _currentRoute = null;
    _currentOrder = null;
    _currentDestinationType = null;
    _distanceRemaining = null;
    _durationRemaining = null;
    _nextInstruction = null;
    _locationUpdateTimer?.cancel();
    
    debugPrint('❌ Navigation cancelled');
    notifyListeners();
  }

  /// Suggest navigation to customer after reaching restaurant
  void _suggestNavigationToCustomer() {
    // This can be handled by the UI to show a dialog or notification
    // to start navigation to customer
    debugPrint('💡 Suggesting navigation to customer');
  }

  /// Get formatted distance remaining
  String getFormattedDistanceRemaining() {
    if (_distanceRemaining == null) return '';
    
    if (_distanceRemaining! >= 1000) {
      return '${(_distanceRemaining! / 1000).toStringAsFixed(1)} km';
    } else {
      return '${_distanceRemaining!.toInt()} m';
    }
  }

  /// Get formatted duration remaining
  String getFormattedDurationRemaining() {
    if (_durationRemaining == null) return '';
    
    final minutes = (_durationRemaining! / 60).round();
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Check if navigation is available for the current order
  bool canNavigate(OrderModel order) {
    return _isInitialized && !_isNavigating;
  }

  /// Get navigation summary for current route
  Map<String, dynamic> getNavigationSummary() {
    return {
      'isNavigating': _isNavigating,
      'destinationType': _currentDestinationType,
      'distanceRemaining': getFormattedDistanceRemaining(),
      'durationRemaining': getFormattedDurationRemaining(),
      'nextInstruction': _nextInstruction,
      'currentLocation': _currentLocation,
      'orderId': _currentOrder?.id,
    };
  }

  /// Dispose resources
  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}

// Navigation extensions and utilities
extension NavigationHelpers on OrderModel {
  /// Check if this order has valid coordinates for navigation
  bool get hasValidCoordinates {
    return restaurantLocation.latitude != 0 &&
           restaurantLocation.longitude != 0 &&
           customerLocation.latitude != 0 &&
           customerLocation.longitude != 0;
  }
  
  /// Get restaurant location as LatLng
  LatLng get restaurantLatLng => LatLng(
    restaurantLocation.latitude,
    restaurantLocation.longitude,
  );
  
  /// Get customer location as LatLng
  LatLng get customerLatLng => LatLng(
    customerLocation.latitude,
    customerLocation.longitude,
  );
}
