import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'location_provider.dart';

part 'app_controller_provider.g.dart';

enum DriverStatus { offline, online, onDuty }

class AppState {
  final DriverStatus driverStatus;
  final String? selectedZone;
  final DateTime? shiftStartTime;
  final bool isLoading;
  final String? errorMessage;
  final bool isLocationServiceEnabled;
  final bool hasPermission;

  const AppState({
    this.driverStatus = DriverStatus.offline,
    this.selectedZone,
    this.shiftStartTime,
    this.isLoading = false,
    this.errorMessage,
    this.isLocationServiceEnabled = false,
    this.hasPermission = false,
  });

  AppState copyWith({
    DriverStatus? driverStatus,
    String? selectedZone,
    DateTime? shiftStartTime,
    bool? isLoading,
    String? errorMessage,
    bool? isLocationServiceEnabled,
    bool? hasPermission,
  }) {
    return AppState(
      driverStatus: driverStatus ?? this.driverStatus,
      selectedZone: selectedZone ?? this.selectedZone,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isLocationServiceEnabled:
          isLocationServiceEnabled ?? this.isLocationServiceEnabled,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }

  bool get canStartShift =>
      driverStatus == DriverStatus.offline &&
      isLocationServiceEnabled &&
      hasPermission;

  bool get isOnShift => driverStatus != DriverStatus.offline;

  Duration get shiftDuration {
    if (shiftStartTime == null) return Duration.zero;
    return DateTime.now().difference(shiftStartTime!);
  }

  String get formattedShiftDuration {
    final duration = shiftDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

@Riverpod(keepAlive: true)
class AppController extends _$AppController {
  Timer? _shiftTimer;

  @override
  AppState build() {
    ref.onDispose(() {
      _shiftTimer?.cancel();
    });

    // Listen to location state changes
    ref.listen(locationProvider, (previous, next) {
      state = state.copyWith(
        isLocationServiceEnabled: next.isLocationServiceEnabled,
        hasPermission: next.hasPermission,
      );
    });

    return const AppState();
  }

  Future<void> initialize(BuildContext context) async {
    _setLoading(true);

    try {
      // Initialize location services
      await ref.read(locationProvider.notifier).initialize();

      // Sync location permissions
      final locationState = ref.read(locationProvider);
      state = state.copyWith(
        isLocationServiceEnabled: locationState.isLocationServiceEnabled,
        hasPermission: locationState.hasPermission,
      );

      debugPrint('🔧 AppController initialized successfully');
    } catch (e) {
      _setError('خطأ في تهيئة التطبيق: ${e.toString()}');
      debugPrint('❌ Error initializing AppController: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> startShift({String? selectedZone}) async {
    if (!state.canStartShift) {
      _setError(
        'لا يمكن بدء الوردية. تأكد من تفعيل خدمات الموقع وإعطاء الإذن المطلوب.',
      );
      return false;
    }

    _setLoading(true);

    try {
      // Setup location tracking if not already set up
      ref.read(locationProvider.notifier).startLocationUpdates();

      // Update app state
      state = state.copyWith(
        driverStatus: DriverStatus.online,
        selectedZone: selectedZone,
        shiftStartTime: DateTime.now(),
        errorMessage: null,
      );

      // Start shift timer for UI updates
      _startShiftTimer();

      debugPrint('🚗 Started shift in zone: ${selectedZone ?? 'default'}');
      return true;
    } catch (e) {
      _setError('خطأ في بدء الوردية: ${e.toString()}');
      debugPrint('❌ Error starting shift: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> endShift() async {
    if (!state.isOnShift) {
      _setError('لست في وردية حالياً.');
      return false;
    }

    _setLoading(true);

    try {
      // Cancel shift timer
      _shiftTimer?.cancel();
      _shiftTimer = null;

      // Update app state
      state = state.copyWith(
        driverStatus: DriverStatus.offline,
        selectedZone: null,
        shiftStartTime: null,
        errorMessage: null,
      );

      debugPrint('🏁 Ended shift');
      return true;
    } catch (e) {
      _setError('خطأ في إنهاء الوردية: ${e.toString()}');
      debugPrint('❌ Error ending shift: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void setDriverStatus(DriverStatus status) {
    if (state.driverStatus == status) return;

    state = state.copyWith(driverStatus: status, errorMessage: null);

    debugPrint('👨‍✈️ Driver status updated to: $status');
  }

  void _startShiftTimer() {
    _shiftTimer?.cancel();
    _shiftTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Force a state update to refresh the UI with the current shift duration
      state = state.copyWith();
    });
  }

  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void _setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }
}
