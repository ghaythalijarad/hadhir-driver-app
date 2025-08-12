import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/batched_order_model.dart';
import '../../services/order_notification_service.dart' as service;

part 'notification_provider.g.dart';

class NotificationState {
  final List<BatchedOrderNotification> pendingNotifications;
  final bool isLoading;
  final String? errorMessage;

  const NotificationState({
    this.pendingNotifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<BatchedOrderNotification>? pendingNotifications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationState(
      pendingNotifications: pendingNotifications ?? this.pendingNotifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

@Riverpod(keepAlive: true)
class Notifications extends _$Notifications {
  late service.OrderNotificationService _notificationService;
  StreamSubscription<BatchedOrderNotification>? _notificationSubscription;

  @override
  NotificationState build() {
    _notificationService = service.OrderNotificationService();
    _notificationService.initialize(); // Initialize the service

    ref.onDispose(() {
      _notificationService.dispose();
      _stopNotificationListener();
    });

    return const NotificationState();
  }

  Future<void> initialize() async {
    _setLoading(true);

    try {
      // Initialization is now in build(), just start listening
      _startNotificationListener();

      debugPrint('🔔 Notification provider initialized successfully');
    } catch (e) {
      _setError('خطأ في تهيئة خدمة الإشعارات: ${e.toString()}');
      debugPrint('❌ Error initializing notification provider: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _startNotificationListener() {
    _stopNotificationListener();

    try {
      _notificationSubscription =
          _notificationService.orderNotificationStream.listen(
        (notification) {
          debugPrint(
            '📬 New order notification received: ${notification.id}',
          );

          // Add to pending notifications
          state = state.copyWith(
            pendingNotifications: [
              ...state.pendingNotifications,
              notification,
            ],
          );
        },
        onError: (error) {
          debugPrint('❌ Error in notification stream: $error');
          _setError('خطأ في استقبال الإشعارات: $error');
        },
      );

      debugPrint('🔔 Started notification listener');
    } catch (e) {
      _setError('خطأ في بدء مستمع الإشعارات: ${e.toString()}');
      debugPrint('❌ Error starting notification listener: $e');
    }
  }

  void _stopNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    debugPrint('🔕 Stopped notification listener');
  }

  void removeNotification(String notificationId) {
    final updatedNotifications = state.pendingNotifications
        .where((notification) => notification.id != notificationId)
        .toList();

    state = state.copyWith(pendingNotifications: updatedNotifications);
    debugPrint('🗑️ Removed notification: $notificationId');
  }

  Future<bool> acceptOrderNotification(String notificationId) async {
    _setLoading(true);

    try {
      final notification = state.pendingNotifications.firstWhere(
        (notification) => notification.id == notificationId,
        orElse: () => throw Exception('Notification not found'),
      );

      final result = await _notificationService.acceptBatchedOrder(
        notification,
      );

      if (result) {
        // Remove the notification from pending list
        removeNotification(notificationId);
        return true;
      } else {
        _setError('فشل في قبول الطلب');
        return false;
      }
    } catch (e) {
      _setError('خطأ في قبول الطلب: ${e.toString()}');
      debugPrint('❌ Error accepting order notification: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectOrderNotification(String notificationId) async {
    _setLoading(true);

    try {
      final notification = state.pendingNotifications.firstWhere(
        (notification) => notification.id == notificationId,
        orElse: () => throw Exception('Notification not found'),
      );

      final result = await _notificationService.rejectBatchedOrder(
        notification,
      );

      if (result) {
        // Remove the notification from pending list
        removeNotification(notificationId);
        return true;
      } else {
        _setError('فشل في رفض الطلب');
        return false;
      }
    } catch (e) {
      _setError('خطأ في رفض الطلب: ${e.toString()}');
      debugPrint('❌ Error rejecting order notification: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void _setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }
}
