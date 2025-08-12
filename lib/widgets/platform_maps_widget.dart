import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../models/order_marker.dart';
import '../utils/coordinates.dart';
import 'map_fallback_widget.dart';
import 'mapbox_widget.dart';

class PlatformMapsWidget extends StatelessWidget {
  final bool isOnline;
  final LatLng initialLocation;
  final double initialZoom;
  final List<PointAnnotationOptions> markers;
  final List<PolylineAnnotationOptions> polylines;
  final List<CircleAnnotationOptions> circles;
  final VoidCallback? onLocationPressed;
  final VoidCallback? onDashPressed;
  final Function(LatLng)? onMapTap;
  final LatLng? driverLocation;
  final List<Map<String, dynamic>> hotspots;
  final OrderMarker? activeNavigationOrder;
  final bool isNavigating;

  const PlatformMapsWidget({
    super.key,
    required this.isOnline,
    required this.initialLocation,
    this.initialZoom = 13.0,
    this.markers = const [],
    this.polylines = const [],
    this.circles = const [],
    this.onLocationPressed,
    this.onDashPressed,
    this.onMapTap,
    this.driverLocation,
    this.hotspots = const [],
    this.activeNavigationOrder,
    this.isNavigating = false,
  });

  bool get _isMapboxSupported {
    if (kIsWeb) return false;

    // Mapbox Flutter plugin supports iOS and Android
    return Platform.isAndroid || Platform.isIOS;
  }

  // Helper method to convert LatLng to Point
  Point _latLngToPoint(LatLng latLng) {
    return Point(coordinates: Position(latLng.longitude, latLng.latitude));
  }

  // Helper method to convert Point to LatLng
  LatLng _pointToLatLng(Point point) {
    return LatLng(
      point.coordinates.lat.toDouble(),
      point.coordinates.lng.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isMapboxSupported) {
      try {
        return MapboxWidget(
          isOnline: isOnline,
          initialLocation: _latLngToPoint(initialLocation),
          initialZoom: initialZoom,
          markers: markers,
          polylines: polylines,
          circles: circles,
          onLocationPressed: onLocationPressed,
          onMapTap: onMapTap != null
              ? (Point point) => onMapTap!(_pointToLatLng(point))
              : null,
          driverLocation: driverLocation != null
              ? _latLngToPoint(driverLocation!)
              : null,
          hotspots: hotspots,
          activeNavigationOrder: activeNavigationOrder,
          isNavigating: isNavigating,
        );
      } catch (e) {
        debugPrint('❌ Mapbox widget error: $e - falling back to MapFallbackWidget');
        return MapFallbackWidget(
          isOnline: isOnline,
          initialLocation: initialLocation,
          driverLocation: driverLocation,
          hotspots: hotspots,
          activeNavigationOrder: activeNavigationOrder,
          isNavigating: isNavigating,
          onLocationPressed: onLocationPressed,
          onDashPressed: onDashPressed,
        );
      }
    } else {
      return MapFallbackWidget(
        isOnline: isOnline,
        initialLocation: initialLocation,
        driverLocation: driverLocation,
        hotspots: hotspots,
        activeNavigationOrder: activeNavigationOrder,
        isNavigating: isNavigating,
        onLocationPressed: onLocationPressed,
        onDashPressed: onDashPressed,
      );
    }
  }
}
