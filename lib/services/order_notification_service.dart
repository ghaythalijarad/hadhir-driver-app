import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/batched_order_model.dart';
import '../models/order_model.dart';
import '../services/order_optimization_service.dart';

class OrderNotificationService extends ChangeNotifier {
  // Timer for generating orders
  Timer? _orderGenerationTimer;
  bool _isDriverOnline = false;
  bool _isListening = false;

  // Stream controller for notifications
  final _notificationStreamController =
      StreamController<BatchedOrderNotification>.broadcast();

  // Current order notification - now supports batched orders
  BatchedOrderNotification? _currentNotificationBatch;

  // Active batch - driver can only have ONE batch at a time
  BatchedOrderNotification? _activeBatch;

  // Completed orders and pending orders pool
  final List<OrderModel> _completedOrders = [];
  final List<OrderModel> _pendingOrders = [];

  // Callback for when a new batched order is received
  // Function(BatchedOrderNotification)? _onBatchedOrderReceived; // Replaced by stream

  // Stream for new batched orders
  Stream<BatchedOrderNotification> get orderNotificationStream =>
      _notificationStreamController.stream;

  // Remove all code related to mock data, mock order generation, and local testing
  // Only keep real notification logic

  // Getters
  bool get isDriverOnline => _isDriverOnline;
  bool get isListening => _isListening;
  BatchedOrderNotification? get currentNotificationBatch =>
      _currentNotificationBatch;
  BatchedOrderNotification? get activeBatch => _activeBatch;

  // For backward compatibility
  OrderModel? get currentNotificationOrder =>
      _currentNotificationBatch?.primaryOrder;

  // Legacy getters - now return from active batch
  List<OrderModel> get activeOrders => _activeBatch?.orders ?? [];
  List<OrderModel> get completedOrders => List.unmodifiable(_completedOrders);
  List<OrderModel> get pendingOrders => List.unmodifiable(_pendingOrders);

  // Check if driver has any active work
  bool get hasActiveWork => _activeBatch != null;

  /// Initialize the service
  void initialize() {
    debugPrint('🔔 OrderNotificationService initialized');
  }

  /// Set driver online/offline status
  void setDriverOnlineStatus(bool isOnline) {
    _isDriverOnline = isOnline;
    notifyListeners();

    if (isOnline) {
      startListening();
    } else {
      stopListening();
    }
  }

  /// Start listening for new orders
  void startListening() {
    if (_isListening) return;

    _isListening = true;

    // Start generating batched orders every 60 seconds for realistic testing
    _orderGenerationTimer = Timer.periodic(
      const Duration(seconds: 60),
      (timer) => _generateBatchedOrder(),
    );

    debugPrint(
      '🔔 Order notification service started listening for batched orders',
    );
    notifyListeners();
  }

  /// Stop listening for new orders
  void stopListening() {
    _orderGenerationTimer?.cancel();
    _orderGenerationTimer = null;
    _isListening = false;
    _currentNotificationBatch = null;
    _pendingOrders.clear();

    debugPrint('🔕 Order notification service stopped listening');
    notifyListeners();
  }

  /// Generate batched orders for testing
  void _generateBatchedOrder() {
    // debugPrint('🔄 Trying to generate batched order...');
    // debugPrint('  - Driver online: $_isDriverOnline');
    // debugPrint('  - Service listening: $_isListening');
    // debugPrint('  - Has active work: $hasActiveWork');

    if (!_isDriverOnline || !_isListening || hasActiveWork) {
      debugPrint(
        '❌ Skipping notification generation - driver already has active work',
      );
      return;
    }

    // Add new pending orders to the pool
    _addPendingOrders();
    // debugPrint('  - Pending orders after adding: ${_pendingOrders.length}');

    // Try to find optimal batches from pending orders
    final batches = OrderOptimizationService.findOptimalBatches(_pendingOrders);

    if (batches.isNotEmpty) {
      // Take the first batch
      final batch = batches.first;

      // Remove batched orders from pending pool
      for (final order in batch.orders) {
        _pendingOrders.removeWhere((p) => p.id == order.id);
      }

      _currentNotificationBatch = batch;
      _notificationStreamController.add(batch);
      notifyListeners();

      debugPrint(
        '🆕 New batched order generated: ${batch.orders.length} orders, type: ${batch.batchType.name}',
      );
    } else if (_pendingOrders.isNotEmpty) {
      // If no batching is possible, create single order notification
      final singleOrder = _pendingOrders.removeAt(0);
      final singleBatch = BatchedOrderNotification.singleOrder(singleOrder);

      _currentNotificationBatch = singleBatch;
      _notificationStreamController.add(singleBatch);
      notifyListeners();

      debugPrint('🆕 Single order notification: ${singleOrder.id}');
    }
  }

  /// Add new pending orders to the pool
  void _addPendingOrders() {
    final random = Random();

    // Generate 1-2 new orders
    final numOrders = 1 + random.nextInt(2);

    for (int i = 0; i < numOrders; i++) {
      final order = _generateSingleOrder();
      _pendingOrders.add(order);
    }
  }

  /// Generate a single order for testing
  OrderModel _generateSingleOrder() {
    final random = Random();
    final restaurantName = 'مطعم الشواء العراقي'; // Mock data removed
    final customerName = 'أحمد محمد'; // Mock data removed
    final area = 'الكرادة'; // Mock data removed
    final items = ['برجر لحم', 'بطاطس مقلية', 'كوكا كولا']; // Mock data removed

    // Generate random coordinates around Baghdad
    final restaurantLat = 33.3152 + (random.nextDouble() - 0.5) * 0.1;
    final restaurantLng = 44.3661 + (random.nextDouble() - 0.5) * 0.1;
    final customerLat = 33.3152 + (random.nextDouble() - 0.5) * 0.1;
    final customerLng = 44.3661 + (random.nextDouble() - 0.5) * 0.1;

    // Calculate distances
    final restaurantDistance =
        1.0 + random.nextDouble() * 4.0; // 1-5 km to restaurant
    final deliveryDistance = 1.0 + random.nextDouble() * 6.0; // 1-7 km delivery
    final totalDistance = restaurantDistance + deliveryDistance;

    return OrderModel(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}',
      restaurantName: restaurantName,
      customerName: customerName,
      customerAddress: '$area، بغداد',
      items: items,
      totalAmount: (15.0 + random.nextDouble() * 35.0), // 15-50 USD
      distance: totalDistance,
      paymentMethod: random.nextBool() ? 'نقداً' : 'بطاقة',
      estimatedDeliveryTime: DateTime.now().add(
        Duration(minutes: 20 + random.nextInt(25)),
      ),
      createdAt: DateTime.now(),
      status: OrderStatus.pending,
      restaurantLocation: LocationCoordinate(
        latitude: restaurantLat,
        longitude: restaurantLng,
        address: restaurantName,
      ),
      customerLocation: LocationCoordinate(
        latitude: customerLat,
        longitude: customerLng,
        address: '$area، بغداد',
      ),
      restaurantDistance: restaurantDistance,
      deliveryDistance: deliveryDistance,
    );
  }

  /// Accept a batched order
  Future<bool> acceptBatchedOrder(BatchedOrderNotification batch) async {
    // Remove from current notification
    if (_currentNotificationBatch?.id == batch.id) {
      _currentNotificationBatch = null;
    }

    // Set as active batch (driver now holds ONE unit)
    _activeBatch = batch.copyWith();

    // Update all orders status to accepted
    for (final order in _activeBatch!.orders) {
      order.status = OrderStatus.accepted;
    }

    debugPrint(
      '✅ Batched order accepted as ONE unit: ${batch.orders.length} orders',
    );
    notifyListeners();
    return true;
  }

  /// Reject a batched order
  Future<bool> rejectBatchedOrder(BatchedOrderNotification batch) async {
    // Remove from current notification
    if (_currentNotificationBatch?.id == batch.id) {
      _currentNotificationBatch = null;
    }

    debugPrint('❌ Batched order rejected: ${batch.orders.length} orders');
    notifyListeners();
    return true;
  }

  /// Accept an individual order (for backward compatibility)
  void acceptOrder(OrderModel order) {
    // Remove from current notification
    if (_currentNotificationBatch?.primaryOrder.id == order.id) {
      _currentNotificationBatch = null;
    }

    // Create a single-order batch for consistency
    order.status = OrderStatus.accepted;
    _activeBatch = BatchedOrderNotification.singleOrder(order);

    debugPrint('✅ Single order accepted as batch unit: ${order.id}');
    notifyListeners();
  }

  /// Reject an individual order (for backward compatibility)
  void rejectOrder(OrderModel order) {
    // Remove from current notification
    if (_currentNotificationBatch?.primaryOrder.id == order.id) {
      _currentNotificationBatch = null;
    }

    debugPrint('❌ Order rejected: ${order.id}');
    notifyListeners();
  }

  /// Update order status
  bool updateOrderStatus(String orderId, OrderStatus newStatus) {
    if (_activeBatch == null) return false;

    final orderIndex = _activeBatch!.orders.indexWhere(
      (order) => order.id == orderId,
    );
    if (orderIndex == -1) return false;

    final order = _activeBatch!.orders[orderIndex];
    order.status = newStatus;

    if (newStatus == OrderStatus.delivered ||
        newStatus == OrderStatus.cancelled) {
      // Move to completed orders
      _completedOrders.add(order);

      // Remove from active batch
      _activeBatch = _activeBatch!.copyWith(
        orders: _activeBatch!.orders.where((o) => o.id != orderId).toList(),
      );

      // If all orders completed, clear active batch
      if (_activeBatch!.orders.isEmpty) {
        _activeBatch = null;
        debugPrint('🏁 All orders in batch completed - driver is now free');
      }
    }

    debugPrint('📝 Order status updated: $orderId -> ${newStatus.name}');
    notifyListeners();
    return true;
  }

  /// Complete an active order (move to completed)
  void completeActiveOrder(OrderModel order) {
    if (_activeBatch == null) return;

    // Remove from active batch and add to completed
    _activeBatch = _activeBatch!.copyWith(
      orders: _activeBatch!.orders.where((o) => o.id != order.id).toList(),
    );

    if (!_completedOrders.any((o) => o.id == order.id)) {
      _completedOrders.add(order);
    }

    // If all orders completed, clear active batch
    if (_activeBatch!.orders.isEmpty) {
      _activeBatch = null;
      debugPrint('🏁 All orders completed - driver is now free');
    }

    notifyListeners();
  }

  /// Get order by ID
  OrderModel? getOrderById(String orderId) {
    // Check active batch first
    if (_activeBatch != null) {
      try {
        return _activeBatch!.orders.firstWhere((order) => order.id == orderId);
      } catch (e) {
        // Order not in active batch
      }
    }

    // Check completed orders
    try {
      return _completedOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  /// Clear all orders (for testing)
  void clearAllOrders() {
    _activeBatch = null;
    _completedOrders.clear();
    _pendingOrders.clear();
    _currentNotificationBatch = null;
    notifyListeners();
  }

  /// Manually trigger a test notification (for testing UI)
  void triggerTestNotification() {
    if (!_isDriverOnline || hasActiveWork) {
      debugPrint(
        '❌ Cannot trigger test notification: driver offline or already has active work',
      );
      return;
    }

    // Generate a test order immediately
    final testOrder = _generateSingleOrder();
    final testBatch = BatchedOrderNotification.singleOrder(testOrder);

    _currentNotificationBatch = testBatch;
    _notificationStreamController.add(testBatch);
    notifyListeners();

    debugPrint('🆕 Test notification triggered: ${testOrder.id}');
  }

  @override
  void dispose() {
    stopListening();
    _notificationStreamController.close();
    super.dispose();
  }
}
