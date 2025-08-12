import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../app_colors.dart';
import '../models/order_marker.dart';

class MapboxWidget extends StatefulWidget {
  final bool isOnline;
  final Point initialLocation;
  final double initialZoom;
  final List<PointAnnotationOptions> markers;
  final List<PolylineAnnotationOptions> polylines;
  final List<CircleAnnotationOptions> circles;
  final VoidCallback? onLocationPressed;
  final Function(Point)? onMapTap;
  final Point? driverLocation;
  final List<Map<String, dynamic>> hotspots;
  final OrderMarker? activeNavigationOrder;
  final bool isNavigating;

  const MapboxWidget({
    super.key,
    required this.isOnline,
    required this.initialLocation,
    this.initialZoom = 13.0,
    this.markers = const [],
    this.polylines = const [],
    this.circles = const [],
    this.onLocationPressed,
    this.onMapTap,
    this.driverLocation,
    this.hotspots = const [],
    this.activeNavigationOrder,
    this.isNavigating = false,
  });

  @override
  State<MapboxWidget> createState() => _MapboxWidgetState();
}

class _MapboxWidgetState extends State<MapboxWidget> {
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  CircleAnnotationManager? _circleAnnotationManager;

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: ValueKey("mapWidget"),
      cameraOptions: CameraOptions(
        center: widget.initialLocation,
        zoom: widget.initialZoom,
      ),
      styleUri: MapboxStyles.STANDARD,
      textureView: true,
      onMapCreated: _onMapCreated,
      onTapListener: _onMapTap,
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    // Initialize annotation managers
    _pointAnnotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    _polylineAnnotationManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    _circleAnnotationManager = await mapboxMap.annotations
        .createCircleAnnotationManager();

    // Apply initial markers, polylines, and circles
    await _updateAnnotations();

    // Add hotspots if any
    await _addHotspots();
  }

  Future<void> _updateAnnotations() async {
    if (_pointAnnotationManager == null) return;

    // Clear existing annotations
    await _pointAnnotationManager!.deleteAll();
    await _polylineAnnotationManager!.deleteAll();
    await _circleAnnotationManager!.deleteAll();

    // Add markers
    if (widget.markers.isNotEmpty) {
      await _pointAnnotationManager!.createMulti(widget.markers);
    }

    // Add polylines
    if (widget.polylines.isNotEmpty) {
      await _polylineAnnotationManager!.createMulti(widget.polylines);
    }

    // Add circles
    if (widget.circles.isNotEmpty) {
      await _circleAnnotationManager!.createMulti(widget.circles);
    }

    // Add driver location marker if available
    if (widget.driverLocation != null) {
      await _addDriverLocationMarker();
    }
  }

  Future<void> _addDriverLocationMarker() async {
    if (_pointAnnotationManager == null || widget.driverLocation == null) {
      return;
    }

    final driverMarkerOptions = PointAnnotationOptions(
      geometry: widget.driverLocation!,
      iconSize: 1.5,
      iconColor: AppColors.primary.toARGB32(),
    );

    await _pointAnnotationManager!.create(driverMarkerOptions);
  }

  Future<void> _addHotspots() async {
    if (_circleAnnotationManager == null || widget.hotspots.isEmpty) return;

    List<CircleAnnotationOptions> hotspotCircles = [];

    for (int i = 0; i < widget.hotspots.length; i++) {
      final hotspot = widget.hotspots[i];
      final position = hotspot['position'] as Point?;
      final radius = (hotspot['radius'] as double?) ?? 100.0;
      final color = hotspot['color'] as Color? ?? AppColors.primary;

      if (position != null) {
        final circleOptions = CircleAnnotationOptions(
          geometry: position,
          circleRadius: radius,
          circleColor: color.withValues(alpha: 0.3).toARGB32(),
          circleStrokeColor: color.toARGB32(),
          circleStrokeWidth: 2.0,
        );

        hotspotCircles.add(circleOptions);
      }
    }

    if (hotspotCircles.isNotEmpty) {
      await _circleAnnotationManager!.createMulti(hotspotCircles);
    }
  }

  void _onMapTap(MapContentGestureContext context) {
    final point = context.point;
    widget.onMapTap?.call(point);
  }
}

// Extension to convert between coordinate systems
extension PointConversion on Point {
  static Point fromLatLng(double latitude, double longitude) {
    return Point(coordinates: Position(longitude, latitude));
  }
}

// Helper function to convert LatLng coordinates to Mapbox Point
Point latLngToPoint(double latitude, double longitude) {
  return Point(coordinates: Position(longitude, latitude));
}

// Helper function to convert Mapbox Point to latitude/longitude
Map<String, double> pointToLatLng(Point point) {
  return {
    'lat': point.coordinates.lat.toDouble(),
    'lng': point.coordinates.lng.toDouble(),
  };
}
