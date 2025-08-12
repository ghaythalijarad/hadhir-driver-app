import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Service to track and analyze order demand in different areas with minimal clustering
class DemandAnalysisService extends ChangeNotifier {
  // Track orders by location over time
  final Map<String, List<DemandDataPoint>> _demandHistory = {};
  final Map<String, double> _currentDemandLevels = {};

  // Live order streaming and clustering - simplified
  Timer? _clusteringTimer;
  StreamController<String>? _heatMapController;

  // Reduced predefined hotspot zones for Baghdad
  final List<DemandZone> _staticZones = [
    DemandZone(
      id: 'al_mansour',
      name: 'Al-Mansour',
      center: Point(coordinates: Position(44.3400, 33.3250)),
      radius: 1200.0,
      baseMultiplier: 2.8,
    ),
    DemandZone(
      id: 'karrada',
      name: 'Karrada',
      center: Point(coordinates: Position(44.3900, 33.3100)),
      radius: 1000.0,
      baseMultiplier: 2.5,
    ),
    DemandZone(
      id: 'arasat',
      name: 'Arasat',
      center: Point(coordinates: Position(44.3750, 33.3300)),
      radius: 800.0,
      baseMultiplier: 2.9,
    ),
  ];

  Timer? _demandUpdateTimer;
  Timer? _simulationTimer;

  DemandAnalysisService() {
    _initializeDemandTracking();
  }

  void _initializeDemandTracking() {
    // Initialize demand history for each zone
    for (final zone in _staticZones) {
      _demandHistory[zone.id] = [];
      _currentDemandLevels[zone.id] = zone.baseMultiplier;
    }

    // Initialize heat map stream controller
    _heatMapController = StreamController<String>.broadcast();

    // Start very conservative simulation
    _startMinimalSimulation();
  }

  void _startMinimalSimulation() {
    // Very reduced simulation - only during peak hours
    Timer.periodic(const Duration(minutes: 5), (timer) {
      final hour = DateTime.now().hour;
      final isPeakTime =
          (hour >= 12 && hour <= 14) || (hour >= 19 && hour <= 21);

      if (isPeakTime) {
        _simulateMinimalDemand();
      }
    });

    // Analysis every 2 minutes
    _demandUpdateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _updateDemandLevels();
      notifyListeners();
    });
  }

  void _simulateMinimalDemand() {
    final now = DateTime.now();
    final random = Random();

    // Only generate for one random high-demand zone
    final activeZones = _staticZones
        .where((z) => z.baseMultiplier >= 2.7)
        .toList();
    if (activeZones.isEmpty) return;

    final selectedZone = activeZones[random.nextInt(activeZones.length)];

    // Very low chance of generating orders
    if (random.nextDouble() > 0.2) return; // 20% chance only

    _addDemandDataPoint(selectedZone.id, now, DemandEventType.orderReceived);
  }

  void _updateDemandLevels() {
    final now = DateTime.now();
    final last30Minutes = now.subtract(const Duration(minutes: 30));

    for (final zone in _staticZones) {
      final recentEvents =
          _demandHistory[zone.id]
              ?.where((point) => point.timestamp.isAfter(last30Minutes))
              .length ??
          0;

      // Very conservative demand calculation
      double demandLevel = zone.baseMultiplier + (recentEvents * 0.05);

      // Apply smoothing
      final currentLevel = _currentDemandLevels[zone.id] ?? zone.baseMultiplier;
      _currentDemandLevels[zone.id] =
          (currentLevel * 0.8) + (demandLevel * 0.2);

      // Tight bounds to prevent excessive demand
      _currentDemandLevels[zone.id] = _currentDemandLevels[zone.id]!.clamp(
        2.0,
        3.2,
      );
    }
  }

  void _addDemandDataPoint(
    String zoneId,
    DateTime timestamp,
    DemandEventType eventType,
  ) {
    if (!_demandHistory.containsKey(zoneId)) {
      _demandHistory[zoneId] = [];
    }

    _demandHistory[zoneId]!.add(
      DemandDataPoint(timestamp: timestamp, eventType: eventType),
    );

    // Keep only last 30 minutes of data
    final cutoff = timestamp.subtract(const Duration(minutes: 30));
    _demandHistory[zoneId]!.removeWhere(
      (point) => point.timestamp.isBefore(cutoff),
    );
  }

  /// Get current demand hotspots for map display - heavily filtered
  List<Map<String, dynamic>> getCurrentDemandHotspots() {
    final hotspots = <Map<String, dynamic>>[];

    for (final zone in _staticZones) {
      final demandLevel = _currentDemandLevels[zone.id] ?? zone.baseMultiplier;

      // Only show zones with high demand and only during peak hours
      final hour = DateTime.now().hour;
      final isPeakTime =
          (hour >= 12 && hour <= 14) || (hour >= 19 && hour <= 21);

      if (!isPeakTime || demandLevel < 2.7) continue;

      final intensity = _getDemandIntensity(demandLevel);

      hotspots.add({
        'id': zone.id,
        'name': zone.name,
        'position': zone.center,
        'lat': zone.center.coordinates.lat,
        'lng': zone.center.coordinates.lng,
        'radius': zone.radius * 0.6, // Much smaller radius
        'demandLevel': demandLevel,
        'intensity': intensity.label,
        'color': intensity.color,
        'orderCount': _getRecentOrderCount(zone.id),
        'trend': 'stable',
        'multiplier': (demandLevel * 100).round() / 100,
      });
    }

    // Sort and return only top 2
    hotspots.sort(
      (a, b) =>
          (b['demandLevel'] as double).compareTo(a['demandLevel'] as double),
    );

    return hotspots.take(2).toList(); // Maximum 2 zones
  }

  DemandIntensity _getDemandIntensity(double level) {
    if (level >= 3.0) {
      return DemandIntensity('Very Busy', const Color(0xFFB71C1C), 5);
    } else if (level >= 2.8) {
      return DemandIntensity('Busy', const Color(0xFFD32F2F), 4);
    } else {
      return DemandIntensity('Moderate', const Color(0xFFE57373), 3);
    }
  }

  int _getRecentOrderCount(String zoneId) {
    final now = DateTime.now();
    final last15Minutes = now.subtract(const Duration(minutes: 15));

    return _demandHistory[zoneId]
            ?.where((point) => point.timestamp.isAfter(last15Minutes))
            .length ??
        0;
  }

  // Minimal live clustering - return empty most of the time
  List<Map<String, dynamic>> getLiveClusters() {
    return []; // Disable live clusters to reduce map clutter
  }

  Map<String, dynamic> getClusterMetrics() {
    return {
      'total_live_orders': 0,
      'active_clusters': 0,
      'high_intensity_clusters': 0,
      'average_order_value': 0.0,
      'last_update': DateTime.now().toIso8601String(),
    };
  }

  List<Map<String, dynamic>> getLiveOrders() {
    return [];
  }

  Stream<String> get heatMapStream => _heatMapController!.stream;

  /// Get top demand zones for recommendations
  List<Map<String, dynamic>> getTopDemandZones() {
    final hotspots = getCurrentDemandHotspots();
    return hotspots.take(2).toList();
  }

  // Stub methods for compatibility
  void addLiveOrder({
    required String id,
    required String customerId,
    required double latitude,
    required double longitude,
    required double estimatedValue,
  }) {
    // Minimal implementation - don't add to reduce clutter
  }

  void removeLiveOrder(String orderId) {
    // Stub implementation
  }

  void recordOrderAccepted(Point location) {
    // Stub implementation
  }

  void recordOrderCompleted(Point location) {
    // Stub implementation
  }

  void clearLiveData() {
    // Stub implementation
    notifyListeners();
  }

  @override
  void dispose() {
    _demandUpdateTimer?.cancel();
    _simulationTimer?.cancel();
    _clusteringTimer?.cancel();
    _heatMapController?.close();
    super.dispose();
  }
}

class DemandZone {
  final String id;
  final String name;
  final Point center;
  final double radius;
  final double baseMultiplier;

  DemandZone({
    required this.id,
    required this.name,
    required this.center,
    required this.radius,
    required this.baseMultiplier,
  });
}

class DemandDataPoint {
  final DateTime timestamp;
  final DemandEventType eventType;

  DemandDataPoint({required this.timestamp, required this.eventType});
}

class LiveOrder {
  final String id;
  final String customerId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double estimatedValue;
  final String zoneId;

  LiveOrder({
    required this.id,
    required this.customerId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.estimatedValue,
    required this.zoneId,
  });
}

class OrderCluster {
  final String id;
  final double centerLatitude;
  final double centerLongitude;
  final List<LiveOrder> orders;
  final double totalValue;
  int intensity;

  OrderCluster({
    required this.id,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.orders,
    required this.totalValue,
    required this.intensity,
  });
}

enum DemandEventType { orderReceived, orderAccepted, orderCompleted }

class DemandIntensity {
  final String label;
  final Color color;
  final int level;

  DemandIntensity(this.label, this.color, this.level);
}
