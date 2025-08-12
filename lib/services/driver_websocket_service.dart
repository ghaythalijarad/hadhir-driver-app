import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

import '../models/driver_status.dart';

/// WebSocket service for real-time driver connection and order management
class DriverWebSocketService {
  static const String _wsBaseUrl = 'ws://localhost:8001/ws';
  
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _locationUpdateTimer;
  Timer? _reconnectTimer;
  
  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  DriverStatus _status = DriverStatus.offline;
  Position? _lastKnownLocation;
  
  // Streams for UI updates
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<DriverStatus> _statusController = StreamController<DriverStatus>.broadcast();
  final StreamController<Map<String, dynamic>> _orderController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  
  // Public streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<DriverStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get orderStream => _orderController.stream;
  Stream<String> get messageStream => _messageController.stream;
  
  // Getters
  bool get isConnected => _isConnected;
  DriverStatus get status => _status;
  Position? get lastKnownLocation => _lastKnownLocation;

  /// Initialize WebSocket connection
  Future<bool> connect(String authToken) async {
    if (_isConnecting || _isConnected) {
      return _isConnected;
    }

    try {
      _isConnecting = true;
      
      // Get current location
      await _updateLocation();

      // Create WebSocket connection with auth token and location
      final wsUrl = '$_wsBaseUrl/driver?token=$authToken';
      _channel = IOWebSocketChannel.connect(
        wsUrl,
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Send initial connection message with location
      await _sendConnectionMessage();
      
      // Start heartbeat and location updates
      _startHeartbeat();
      _startLocationUpdates();
      
      _isConnected = true;
      _isConnecting = false;
      _connectionController.add(true);
      _addMessage('✅ Connected to driver dispatch system');
      
      return true;
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(false);
      _addMessage('❌ Failed to connect: $e');
      return false;
    }
  }

  /// Disconnect from WebSocket
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    
    _stopHeartbeat();
    _stopLocationUpdates();
    _stopReconnectTimer();
    
    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
    _addMessage('🔌 Disconnected from driver dispatch system');
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Set driver status (online/offline/busy)
  Future<void> setStatus(DriverStatus newStatus) async {
    if (!_isConnected) {
      _addMessage('❌ Not connected. Cannot change status.');
      return;
    }

    try {
      await _sendStatusUpdate(newStatus);
      _status = newStatus;
      _statusController.add(_status);
      
      // Save status to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driver_status', newStatus.toString());
      
      _addMessage('✅ Status updated to: ${_getStatusText(newStatus)}');
    } catch (e) {
      _addMessage('❌ Failed to update status: $e');
    }
  }

  /// Accept an order
  Future<void> acceptOrder(String orderId) async {
    if (!_isConnected) {
      _addMessage('❌ Not connected. Cannot accept order.');
      return;
    }

    try {
      await _sendMessage({
        'type': 'order_accepted',
        'order_id': orderId,
        'driver_location': _lastKnownLocation != null ? {
          'latitude': _lastKnownLocation!.latitude,
          'longitude': _lastKnownLocation!.longitude,
        } : null,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Change status to busy
      await setStatus(DriverStatus.busy);
      _addMessage('✅ Order $orderId accepted');
    } catch (e) {
      _addMessage('❌ Failed to accept order: $e');
    }
  }

  /// Reject an order
  Future<void> rejectOrder(String orderId, String reason) async {
    if (!_isConnected) {
      return;
    }

    try {
      await _sendMessage({
        'type': 'order_rejected',
        'order_id': orderId,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _addMessage('↩️ Order $orderId rejected');
    } catch (e) {
      _addMessage('❌ Failed to reject order: $e');
    }
  }

  /// Update order status (picked_up, delivered, etc.)
  Future<void> updateOrderStatus(String orderId, String status, {Map<String, dynamic>? extra}) async {
    if (!_isConnected) {
      return;
    }

    try {
      await _sendMessage({
        'type': 'order_status_update',
        'order_id': orderId,
        'status': status,
        'driver_location': _lastKnownLocation != null ? {
          'latitude': _lastKnownLocation!.latitude,
          'longitude': _lastKnownLocation!.longitude,
        } : null,
        'timestamp': DateTime.now().toIso8601String(),
        ...?extra,
      });
      
      _addMessage('📦 Order $orderId status updated to: $status');
    } catch (e) {
      _addMessage('❌ Failed to update order status: $e');
    }
  }

  /// Send initial connection message
  Future<void> _sendConnectionMessage() async {
    await _sendMessage({
      'type': 'driver_connect',
      'driver_location': _lastKnownLocation != null ? {
        'latitude': _lastKnownLocation!.latitude,
        'longitude': _lastKnownLocation!.longitude,
      } : null,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send status update
  Future<void> _sendStatusUpdate(DriverStatus status) async {
    await _sendMessage({
      'type': 'driver_status_update',
      'status': status.toString().split('.').last,
      'driver_location': _lastKnownLocation != null ? {
        'latitude': _lastKnownLocation!.latitude,
        'longitude': _lastKnownLocation!.longitude,
      } : null,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send generic message
  Future<void> _sendMessage(Map<String, dynamic> message) async {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  /// Handle incoming messages from the server
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      
      switch (data['type']) {
        case 'connection_confirmed':
          _addMessage('✅ Connection confirmed by server');
          break;
          
        case 'new_order':
          _addMessage('🆕 New order received: ${data['order_id']}');
          _orderController.add(data);
          break;
          
        case 'order_cancelled':
          _addMessage('❌ Order cancelled: ${data['order_id']}');
          _orderController.add(data);
          break;
          
        case 'status_confirmed':
          _addMessage('✅ Status change confirmed');
          break;
          
        case 'error':
          _addMessage('❌ Server error: ${data['message']}');
          break;
          
        case 'ping':
          // Respond to server ping
          _sendMessage({'type': 'pong'});
          break;
          
        case 'location_request':
          // Server requesting location update
          _updateLocationAndSend();
          break;
          
        default:
          _addMessage('📨 Unknown message type: ${data['type']}');
      }
    } catch (e) {
      _addMessage('❌ Error processing message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(error) {
    _isConnected = false;
    _connectionController.add(false);
    _addMessage('❌ WebSocket error: $error');
    _scheduleReconnection();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnection() {
    _isConnected = false;
    _status = DriverStatus.offline;
    
    _connectionController.add(false);
    _statusController.add(_status);
    _addMessage('📴 WebSocket disconnected');
    
    // Cancel timers
    _heartbeatTimer?.cancel();
    _locationUpdateTimer?.cancel();
    
    // Schedule reconnection if we were previously connected
    _scheduleReconnection();
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendMessage({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Start periodic location updates
  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_isConnected && _status == DriverStatus.online) {
        _updateLocationAndSend();
      }
    });
  }

  /// Update current location
  Future<void> _updateLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _addMessage('⚠️ Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _addMessage('⚠️ Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _addMessage('⚠️ Location permissions are permanently denied');
        return;
      }

      _lastKnownLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _addMessage('⚠️ Failed to get location: $e');
    }
  }

  /// Update location and send to server
  Future<void> _updateLocationAndSend() async {
    await _updateLocation();
    if (_lastKnownLocation != null && _isConnected) {
      await _sendMessage({
        'type': 'location_update',
        'latitude': _lastKnownLocation!.latitude,
        'longitude': _lastKnownLocation!.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnection() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        _addMessage('🔄 Attempting to reconnect...');
        connect('');
      }
    });
  }

  /// Add message to stream
  void _addMessage(String message) {
    debugPrint('🚗 DriverWebSocket: $message');
    _messageController.add(message);
  }

  /// Get localized status text
  String _getStatusText(DriverStatus status) {
    switch (status) {
      case DriverStatus.online:
        return 'متاح';
      case DriverStatus.busy:
        return 'مشغول';
      case DriverStatus.offline:
        return 'غير متاح';
    }
  }

  /// Dispose resources
  void dispose() {
    _heartbeatTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _reconnectTimer?.cancel();
    
    _connectionController.close();
    _statusController.close();
    _orderController.close();
    _messageController.close();
    
    _channel?.sink.close();
  }
}
