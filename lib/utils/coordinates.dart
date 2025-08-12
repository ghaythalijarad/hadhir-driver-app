// Shared coordinate utilities for the app
// Local LatLng implementation compatible with Mapbox
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  /// Convert to Mapbox Point coordinates
  Point toMapboxPoint() => Point(coordinates: Position(longitude, latitude));

  /// Convert to Map format for backward compatibility
  Map<String, double> toMap() => {'lng': longitude, 'lat': latitude};
}
