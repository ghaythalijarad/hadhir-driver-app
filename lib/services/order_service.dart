import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/order_marker.dart';
import '../models/order_model.dart';
import '../utils/coordinates.dart';
import 'location_service.dart';

class OrderService extends ChangeNotifier {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final List<OrderMarker> _availableOrders = [];
  final List<OrderMarker> _activeOrders = [];
  Timer? _orderUpdateTimer;
  bool _isListening = false;

  // AWS API endpoint
  static const String _baseUrl =
      'https://api.example.com/api/v1'; // Replace with your actual backend URL

  List<OrderMarker> get availableOrders => List.unmodifiable(_availableOrders);
  List<OrderMarker> get activeOrders => List.unmodifiable(_activeOrders);
  bool get isListening => _isListening;

  /// Start listening for new orders in the current area
  void startListening({String city = 'Baghdad'}) {
    if (_isListening) return;

    _isListening = true;

    // Start periodic order updates every 10 seconds
    _orderUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchAvailableOrders(city);
    });

    // Initial fetch
    _fetchAvailableOrders(city);

    notifyListeners();
  }

  /// Stop listening for new orders
  void stopListening() {
    _orderUpdateTimer?.cancel();
    _orderUpdateTimer = null;
    _isListening = false;
    notifyListeners();
  }

  /// Fetch available orders from the API
  Future<void> _fetchAvailableOrders(String city) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/orders/$city?status=pending'),
            headers: {
              'Content-Type': 'application/json',
              // Add auth header when implemented
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final ordersJson = data['data'] as List;
          final newOrders = ordersJson
              .map((json) => OrderMarker.fromJson(json))
              .where((order) => order.isPending)
              .toList();

          _availableOrders.clear();
          _availableOrders.addAll(newOrders);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('OrderService: API connection failed, no mock data available');
      _availableOrders.clear(); // Clear orders on API failure
      notifyListeners();
    }
  }

  /// Accept an order
  Future<bool> acceptOrder(String orderId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/orders/$orderId/assign'),
            headers: {
              'Content-Type': 'application/json',
              // Add auth header when implemented
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Move order from available to active
          final orderIndex = _availableOrders.indexWhere(
            (o) => o.id == orderId,
          );
          if (orderIndex != -1) {
            final order = _availableOrders.removeAt(orderIndex);
            final acceptedOrder = order.copyWith(
              status: OrderStatus.confirmed,
              acceptedAt: DateTime.now(),
            );
            _activeOrders.add(acceptedOrder);
            notifyListeners();
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint(
        'OrderService: API error when accepting order, no mock data available',
      );
      return false;
    }
    return false;
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/orders/$orderId/status'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'status': newStatus.name}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Update local order status
          final orderIndex = _activeOrders.indexWhere((o) => o.id == orderId);
          if (orderIndex != -1) {
            final order = _activeOrders[orderIndex];
            final updatedOrder = order.copyWith(
              status: newStatus,
              pickedUpAt: newStatus == OrderStatus.onTheWay
                  ? DateTime.now()
                  : order.pickedUpAt,
              deliveredAt: newStatus == OrderStatus.delivered
                  ? DateTime.now()
                  : order.deliveredAt,
            );

            if (newStatus == OrderStatus.delivered ||
                newStatus == OrderStatus.cancelled) {
              _activeOrders.removeAt(orderIndex);
            } else {
              _activeOrders[orderIndex] = updatedOrder;
            }

            notifyListeners();
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint(
        'OrderService: API error when updating status, no mock data available',
      );
      return false;
    }
    return false;
  }

  /// Get orders near a specific location
  List<OrderMarker> getOrdersNearLocation(
    LatLng location, {
    double radiusKm = 5.0,
  }) {
    final locationService = LocationService();

    return _availableOrders.where((order) {
      final distance = locationService.getDistanceBetween(
        location,
        order.location,
      );
      return distance <= (radiusKm * 1000); // Convert km to meters
    }).toList();
  }

  /// Add an order externally (e.g., from main app acceptance)
  void addActiveOrder(OrderMarker order) {
    // Remove from available orders if it exists there
    _availableOrders.removeWhere((o) => o.id == order.id);

    // Add to active orders if not already there
    final existingIndex = _activeOrders.indexWhere((o) => o.id == order.id);
    if (existingIndex == -1) {
      _activeOrders.add(order);
      debugPrint(
        'OrderService: Added active order ${order.id} - ${order.restaurantName}',
      );
    } else {
      _activeOrders[existingIndex] = order;
      debugPrint(
        'OrderService: Updated active order ${order.id} - ${order.restaurantName}',
      );
    }

    notifyListeners();
  }

  /// Clear all orders
  void clearOrders() {
    _availableOrders.clear();
    _activeOrders.clear();
    notifyListeners();
    debugPrint('OrderService: All orders cleared');
  }

  /// Check if backend is available
  Future<bool> checkBackendConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
