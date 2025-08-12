import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../models/order_marker.dart' as marker;
import '../services/order_notification_service.dart';
import '../services/order_service.dart';
import '../utils/coordinates.dart';

/// Manages all order-related operations and state
/// Ensures single source of truth for order data
class OrderManager extends ChangeNotifier {
  final OrderService? _orderService;
  final OrderNotificationService? _orderNotificationService;

  // Internal state
  bool _isListening = false;
  OrderModel? _currentNotificationOrder;

  OrderManager(this._orderService, this._orderNotificationService);

  // Getters
  bool get isListening => _isListening;
  OrderModel? get currentNotificationOrder => _currentNotificationOrder;

  List<marker.OrderMarker> get activeOrders {
    return _orderService?.activeOrders ?? [];
  }

  List<marker.OrderMarker> get availableOrders {
    return _orderService?.availableOrders ?? [];
  }

  /// Start listening for orders
  Future<void> startListening({Function(OrderModel)? onOrderReceived}) async {
    if (_isListening) return;

    try {
      // Enable mock mode for order service to prevent API calls
      if (_orderService != null) {
        _orderService.startListening();
      }

      // Note: OrderNotificationService is managed by DriverStateManager
      // No need to start it here to avoid duplicate notifications

      _isListening = true;
      notifyListeners();
      debugPrint('📋 OrderManager started listening in mock mode');
    } catch (e) {
      debugPrint('❌ Failed to start listening: $e');
      rethrow;
    }
  }

  /// Stop listening for orders
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      // Stop order service
      if (_orderService != null) {
        _orderService.stopListening();
      }

      // Note: OrderNotificationService is managed by DriverStateManager
      // No need to stop it here

      _isListening = false;
      _currentNotificationOrder = null;

      notifyListeners();
      debugPrint('📋 OrderManager stopped listening');
    } catch (e) {
      debugPrint('❌ Failed to stop listening: $e');
    }
  }

  /// Accept an order
  Future<bool> acceptOrder(OrderModel order) async {
    if (_orderService == null || _orderNotificationService == null) {
      debugPrint('❌ Services not initialized');
      return false;
    }

    try {
      // Accept in notification service
      _orderNotificationService.acceptOrder(order);

      // Convert OrderModel to OrderMarker
      final orderMarker = _convertOrderModelToMarker(order);

      // Add to order service
      _orderService.addActiveOrder(orderMarker);

      // Clear current notification
      _currentNotificationOrder = null;

      notifyListeners();
      debugPrint('✅ Order accepted: ${order.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to accept order: $e');
      return false;
    }
  }

  /// Reject an order
  Future<bool> rejectOrder(OrderModel order) async {
    if (_orderNotificationService == null) {
      debugPrint('❌ Notification service not initialized');
      return false;
    }

    try {
      _orderNotificationService.rejectOrder(order);
      _currentNotificationOrder = null;

      notifyListeners();
      debugPrint('✅ Order rejected: ${order.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to reject order: $e');
      return false;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    if (_orderService == null) {
      debugPrint('❌ Order service not initialized');
      return false;
    }

    try {
      final success = await _orderService.updateOrderStatus(orderId, newStatus);

      if (success) {
        notifyListeners();
        debugPrint('✅ Order status updated: $orderId -> ${newStatus.name}');

        // If order is completed, allow new orders
        if (newStatus == OrderStatus.delivered ||
            newStatus == OrderStatus.cancelled) {
          OrderModel? completedOrder;
          try {
            completedOrder = _orderNotificationService?.activeOrders.firstWhere(
              (order) => order.id == orderId,
            );
          } catch (_) {
            completedOrder = null;
          }
          if (completedOrder != null) {
            _orderNotificationService?.completeActiveOrder(completedOrder);
          }
        }
      }

      return success;
    } catch (e) {
      debugPrint('❌ Failed to update order status: $e');
      return false;
    }
  }

  /// Get orders near a location
  List<marker.OrderMarker> getOrdersNearLocation(
    LatLng location, {
    double radiusKm = 5.0,
  }) {
    if (_orderService == null) return [];

    return _orderService.getOrdersNearLocation(location, radiusKm: radiusKm);
  }

  /// Get active orders filtered by status
  List<marker.OrderMarker> getActiveOrdersByStatus(
    List<OrderStatus> statuses,
  ) {
    return activeOrders
        .where((order) => statuses.contains(order.status))
        .toList();
  }

  /// Get order by ID
  marker.OrderMarker? getOrderById(String orderId) {
    try {
      return activeOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  /// Convert OrderModel to OrderMarker
  marker.OrderMarker _convertOrderModelToMarker(OrderModel order) {
    return marker.OrderMarker(
      id: order.id,
      location: LatLng(
        order.restaurantLocation.latitude,
        order.restaurantLocation.longitude,
      ),
      customerLocation: LatLng(
        order.customerLocation.latitude,
        order.customerLocation.longitude,
      ),
      status: OrderStatus.confirmed,
      type: marker.OrderType.delivery,
      restaurantName: order.restaurantName,
      customerName: order.customerName,
      address: order.customerAddress,
      estimatedEarnings: order.totalAmount,
      estimatedTime: 25, // Default estimation
      distance: order.distance,
      createdAt: order.createdAt,
      acceptedAt: DateTime.now(),
      items: order.items,
      totalAmount: order.totalAmount,
      paymentMethod: order.paymentMethod,
    );
  }

  /// Clear all orders (for testing or reset)
  void clearAllOrders() {
    if (_orderService != null) {
      _orderService.clearOrders();
    }
    _currentNotificationOrder = null;
    notifyListeners();
    debugPrint('🗑️ All orders cleared');
  }

  @override
  void dispose() {
    if (_isListening) {
      stopListening();
    }
    super.dispose();
  }
}
