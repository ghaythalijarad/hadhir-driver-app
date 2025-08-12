import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/environment.dart';
import '../models/order_model.dart';

enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

enum MessageType {
  // Authentication & Connection
  driverConnect,
  driverDisconnect,
  driverAuthenticate,

  // Driver Status Updates
  driverLocationUpdate,
  driverStatusUpdate,
  driverOnline,
  driverOffline,

  // Order Lifecycle (Cross-app communication)
  newOrderAssignment,        // Platform → Driver: New order assigned
  orderAccepted,            // Driver → Platform → Customer + Merchant
  orderRejected,            // Driver → Platform → Customer + Merchant  
  orderPickedUp,            // Driver → Platform → Customer + Merchant
  orderDelivered,           // Driver → Platform → Customer + Merchant
  orderCancelled,           // Any app → Platform → All relevant apps
  orderStatusUpdate,        // Driver → Platform → Customer + Merchant

  // Real-time Communication (Cross-app)
  merchantMessage,          // Merchant → Platform → Driver
  customerMessage,          // Customer → Platform → Driver
  platformMessage,          // Platform → Driver
  driverMessage,            // Driver → Platform → Customer/Merchant
  emergencyAlert,           // Driver → Platform → All apps

  // System Events
  heartbeat,
  systemNotification,
  configUpdate,
  
  // Ecosystem-wide events
  orderCreated,             // Customer → Platform → Available drivers
  merchantAccepted,         // Merchant → Platform → Assigned driver
  driverAssigned,           // Platform → Driver + Customer + Merchant
  deliveryTracking,         // Driver → Platform → Customer
}

class WebSocketMessage {
  final MessageType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? targetId;
  final String messageId;

  WebSocketMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.targetId,
    String? messageId,
  }) : timestamp = timestamp ?? DateTime.now(),
       messageId =
           messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'target_id': targetId,
    'message_id': messageId,
  };

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.systemNotification,
      ),
      data: json['data'] ?? {},
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      targetId: json['target_id'],
      messageId: json['message_id'],
    );
  }
}

class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;

  // Connection state
  WebSocketStatus _status = WebSocketStatus.disconnected;
  String? _driverId;
  String? _authToken;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Message handlers
  final Map<MessageType, List<Function(WebSocketMessage)>> _messageHandlers =
      {};
  final List<WebSocketMessage> _messageQueue = [];

  // Getters
  WebSocketStatus get status => _status;
  bool get isConnected => _status == WebSocketStatus.connected;
  String? get driverId => _driverId;

  // Callbacks
  Function(OrderModel)? onNewOrderAssignment;
  Function(String, String)? onMerchantMessage;
  Function(String, String)? onCustomerMessage;
  Function(String)? onEmergencyAlert;
  Function(Map<String, dynamic>)? onSystemNotification;

  /// Initialize WebSocket service
  Future<void> initialize({
    required String driverId,
    required String authToken,
  }) async {
    debugPrint('🔌 Initializing WebSocket Service...');

    _driverId = driverId;
    _authToken = authToken;

    // Set up message handlers
    _setupMessageHandlers();

    // Connect to WebSocket
    await connect();

    debugPrint('✅ WebSocket Service initialized');
  }

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_status == WebSocketStatus.connecting ||
        _status == WebSocketStatus.connected) {
      return;
    }

    try {
      _setStatus(WebSocketStatus.connecting);
      debugPrint('🔌 Connecting to WebSocket server...');

      // WebSocket URL without authentication parameters in handshake
      final baseUrl = Environment.webSocketUrl;
      // Use Uri.parse and ensure the scheme is correct.
      final uri = Uri.parse(baseUrl.replaceFirst('http', 'ws'));
      debugPrint('🔗 Connecting WebSocket to: $uri');


      // Establish the connection
      _channel = IOWebSocketChannel.connect(
        uri,
        connectTimeout: const Duration(seconds: 15),
      );

      // Listen to messages with better error handling
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: false, // Don't cancel on error, handle gracefully
      );

      // Start heartbeat
      _startHeartbeat();

      _setStatus(WebSocketStatus.connected);

      // Send driver authentication payload after connection
      final authPayload = WebSocketMessage(
        type: MessageType.driverAuthenticate,
        data: {'driver_id': _driverId, 'auth_token': _authToken},
      );
      _channel!.sink.add(jsonEncode(authPayload.toJson()));

      // Send queued messages
      await _sendQueuedMessages();

      debugPrint('✅ WebSocket connected successfully to production endpoint');
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      _setStatus(WebSocketStatus.error);
      // Do not reconnect automatically; user can manually retry.
      return;
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    debugPrint('🔌 Disconnecting from WebSocket...');

    _heartbeatTimer?.cancel();
    _subscription?.cancel();

    if (_channel != null) {
      await _sendMessage(
        WebSocketMessage(
          type: MessageType.driverDisconnect,
          data: {'driver_id': _driverId},
        ),
      );

      await _channel!.sink.close();
      _channel = null;
    }

    _setStatus(WebSocketStatus.disconnected);
    debugPrint('✅ WebSocket disconnected');
  }

  /// Send driver location update
  Future<void> sendLocationUpdate({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    double? accuracy,
  }) async {
    await _sendMessage(
      WebSocketMessage(
        type: MessageType.driverLocationUpdate,
        data: {
          'driver_id': _driverId,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
            'heading': heading,
            'speed': speed,
            'accuracy': accuracy,
          },
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  /// Send driver status update (online/offline/busy)
  Future<void> sendStatusUpdate({
    required String status,
    String? currentZone,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendMessage(
      WebSocketMessage(
        type: MessageType.driverStatusUpdate,
        data: {
          'driver_id': _driverId,
          'status': status,
          'current_zone': currentZone,
          'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  /// Accept an order
  Future<void> acceptOrder(String orderId) async {
    await _sendMessage(
      WebSocketMessage(
        type: MessageType.orderAccepted,
        data: {
          'driver_id': _driverId,
          'order_id': orderId,
          'accepted_at': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  /// Reject an order
  Future<void> rejectOrder(String orderId, {String? reason}) async {
    await _sendMessage(
      WebSocketMessage(
        type: MessageType.orderRejected,
        data: {
          'driver_id': _driverId,
          'order_id': orderId,
          'reason': reason ?? 'Driver declined',
          'rejected_at': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  /// Update order status
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    Map<String, dynamic>? metadata,
  }) async {
    await _sendMessage(
      WebSocketMessage(
        type: MessageType.orderStatusUpdate,
        data: {
          'driver_id': _driverId,
          'order_id': orderId,
          'status': status,
          'metadata': metadata ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  /// Send message to merchant
  Future<void> sendMessageToMerchant({
    required String merchantId,
    required String message,
    String? orderId,
  }) async {
    await _sendMessage(
      WebSocketMessage(
        type: MessageType.merchantMessage,
        targetId: merchantId,
        data: {
          'driver_id': _driverId,
          'merchant_id': merchantId,
          'order_id': orderId,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  /// Send message to customer
  Future<void> sendMessageToCustomer({
    required String customerId,
    required String message,
    String? orderId,
  }) async {
    await _sendMessage(
      WebSocketMessage(
        type: MessageType.customerMessage,
        targetId: customerId,
        data: {
          'driver_id': _driverId,
          'customer_id': customerId,
          'order_id': orderId,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  /// Send emergency alert
  Future<void> sendEmergencyAlert({
    required String alertType,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    await _sendMessage(
      WebSocketMessage(
        type: MessageType.emergencyAlert,
        data: {
          'driver_id': _driverId,
          'alert_type': alertType,
          'location': {'latitude': latitude, 'longitude': longitude},
          'description': description,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );
  }

  /// Subscribe to specific message types
  void subscribe(MessageType messageType, Function(WebSocketMessage) handler) {
    _messageHandlers[messageType] ??= [];
    _messageHandlers[messageType]!.add(handler);
  }

  /// Unsubscribe from message types
  void unsubscribe(
    MessageType messageType,
    Function(WebSocketMessage) handler,
  ) {
    _messageHandlers[messageType]?.remove(handler);
  }

  /// Send message through WebSocket
  Future<void> _sendMessage(WebSocketMessage message) async {
    if (!isConnected) {
      debugPrint(
        '⚠️ WebSocket not connected, queuing message: ${message.type.name}',
      );
      _messageQueue.add(message);
      return;
    }

    try {
      final jsonMessage = jsonEncode(message.toJson());
      _channel!.sink.add(jsonMessage);
      debugPrint('📤 Sent message: ${message.type.name}');
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
      _messageQueue.add(message); // Queue failed messages
    }
  }

  Future<void> _sendQueuedMessages() async {
    while (_messageQueue.isNotEmpty && isConnected) {
      final message = _messageQueue.removeAt(0);
      sendMessage(message);
      debugPrint('📤 Sent queued message: ${message.type.name}');
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> json = jsonDecode(data.toString());
      final message = WebSocketMessage.fromJson(json);

      debugPrint('📥 Received message: ${message.type.name}');

      // Handle specific message types
      switch (message.type) {
        case MessageType.newOrderAssignment:
          _handleNewOrderAssignment(message);
          break;
        case MessageType.merchantMessage:
          _handleMerchantMessage(message);
          break;
        case MessageType.customerMessage:
          _handleCustomerMessage(message);
          break;
        case MessageType.emergencyAlert:
          _handleEmergencyAlert(message);
          break;
        case MessageType.systemNotification:
          _handleSystemNotification(message);
          break;
        case MessageType.heartbeat:
          // Heartbeat acknowledged
          break;
        default:
          break;
      }

      // Call registered handlers
      final handlers = _messageHandlers[message.type];
      if (handlers != null) {
        for (final handler in handlers) {
          try {
            handler(message);
          } catch (e) {
            debugPrint('❌ Message handler error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to handle message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(error) {
    debugPrint('❌ WebSocket error: $error');
    _setStatus(WebSocketStatus.error);
    // Do not auto-reconnect after error; allow manual retry
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    debugPrint('⚠️ WebSocket disconnected');
    _setStatus(WebSocketStatus.disconnected);
    // Do not auto-reconnect after disconnection
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (isConnected) {
        final heartbeatMessage = WebSocketMessage(
          type: MessageType.heartbeat,
          data: {'timestamp': DateTime.now().toIso8601String()},
        );
        _channel!.sink.add(jsonEncode(heartbeatMessage.toJson()));
      }
    });
  }

  /// Send a message through the WebSocket.
  void sendMessage(WebSocketMessage message) {
    if (isConnected) {
      _channel!.sink.add(jsonEncode(message.toJson()));
    } else {
      _messageQueue.add(message);
      debugPrint('⚠️ WebSocket not connected. Queued message: ${message.type.name}');
      // Do not automatically reconnect here to avoid loops.
      // Reconnection should be handled manually or with a more robust strategy.
    }
  }

  /// Register a handler for a specific message type.
  void on(MessageType type, Function(WebSocketMessage) handler) {
    if (!_messageHandlers.containsKey(type)) {
      _messageHandlers[type] = [];
    }
    _messageHandlers[type]!.add(handler);
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Set up built-in handlers
    subscribe(MessageType.newOrderAssignment, (message) {
      _handleNewOrderAssignment(message);
    });
  }

  /// Handle new order assignment
  void _handleNewOrderAssignment(WebSocketMessage message) {
    try {
      final orderData = message.data['order'];
      if (orderData != null) {
        final order = OrderModel.fromJson(orderData);
        onNewOrderAssignment?.call(order);
      }
    } catch (e) {
      debugPrint('❌ Failed to handle new order assignment: $e');
    }
  }

  /// Handle merchant message
  void _handleMerchantMessage(WebSocketMessage message) {
    final merchantId = message.data['merchant_id'];
    final messageContent = message.data['message'];

    if (merchantId != null && messageContent != null) {
      onMerchantMessage?.call(merchantId, messageContent);
    }
  }

  /// Handle customer message
  void _handleCustomerMessage(WebSocketMessage message) {
    final customerId = message.data['customer_id'];
    final messageContent = message.data['message'];

    if (customerId != null && messageContent != null) {
      onCustomerMessage?.call(customerId, messageContent);
    }
  }

  /// Handle emergency alert
  void _handleEmergencyAlert(WebSocketMessage message) {
    final alertType = message.data['alert_type'];
    if (alertType != null) {
      onEmergencyAlert?.call(alertType);
    }
  }

  /// Handle system notification
  void _handleSystemNotification(WebSocketMessage message) {
    onSystemNotification?.call(message.data);
  }

  /// Set connection status
  void _setStatus(WebSocketStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
      debugPrint('🔌 WebSocket status changed: ${status.name}');
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    disconnect();
    _messageHandlers.clear();
    _messageQueue.clear();
    super.dispose();
  }
}
