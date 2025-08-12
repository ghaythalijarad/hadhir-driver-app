import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../models/order_marker.dart';
import '../utils/coordinates.dart';
import 'mapbox_widget.dart';
import 'map_fallback_widget.dart';

class PlatformMapsWidgetMapbox extends StatelessWidget {
  final bool isOnline;
  final Point initialLocation;
  final double initialZoom;
  final List<PointAnnotationOptions> markers;
  final List<PolylineAnnotationOptions> polylines;
  final List<CircleAnnotationOptions> circles;
  final VoidCallback? onLocationPressed;
  final VoidCallback? onDashPressed;
  final Function(Point)? onMapTap;
  final Point? driverLocation;
  final List<Map<String, dynamic>> hotspots;
  final OrderMarker? activeNavigationOrder;
  final bool isNavigating;

  const PlatformMapsWidgetMapbox({
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

  @override
  Widget build(BuildContext context) {
    if (_isMapboxSupported) {
      try {
        return MapboxWidget(
          isOnline: isOnline,
          initialLocation: initialLocation,
          initialZoom: initialZoom,
          markers: markers,
          polylines: polylines,
          circles: circles,
          onLocationPressed: onLocationPressed,
          onMapTap: onMapTap,
          driverLocation: driverLocation,
          hotspots: hotspots,
          activeNavigationOrder: activeNavigationOrder,
          isNavigating: isNavigating,
        );
      } catch (e) {
        debugPrint(
          '❌ Mapbox widget error: $e - falling back to MapFallbackWidget',
        );
        return _buildFallbackWidget();
      }
    } else {
      return _buildFallbackWidget();
    }
  }

  Widget _buildFallbackWidget() {
    // Convert Point back to fallback format for the fallback widget
    final fallbackLocation = _pointToLatLng(initialLocation);
    final fallbackDriverLocation = driverLocation != null 
        ? _pointToLatLng(driverLocation!) 
        : null;

    return MapFallbackWidget(
      isOnline: isOnline,
      initialLocation: LatLng(fallbackLocation['latitude']!, fallbackLocation['longitude']!),
      driverLocation: fallbackDriverLocation != null 
          ? LatLng(fallbackDriverLocation['latitude']!, fallbackDriverLocation['longitude']!)
          : null,
      hotspots: hotspots,
      activeNavigationOrder: activeNavigationOrder,
      isNavigating: isNavigating,
      onLocationPressed: onLocationPressed,
      onDashPressed: onDashPressed,
    );
  }

  Map<String, double> _pointToLatLng(Point point) {
    return {
      'latitude': point.coordinates.lat.toDouble(),
      'longitude': point.coordinates.lng.toDouble(),
    };
  }
}
