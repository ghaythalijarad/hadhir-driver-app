import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../utils/coordinates.dart';

// Baghdad specific coordinates and areas
class BaghdadLocations {
  // Major areas in Baghdad with realistic coordinates
  static const Map<String, LatLng> restaurants = {
    'McDonald\'s Karrada': LatLng(33.3085, 44.3937), // Karrada area
    'KFC Mansour': LatLng(33.3354, 44.3412), // Mansour Mall
    'Pizza Hut Jadiriya': LatLng(33.2862, 44.3777), // Jadiriya
    'Burger King Zawra': LatLng(33.3167, 44.3719), // Zawra Park area
    'Subway Arasat': LatLng(33.3240, 44.3951), // Arasat area
    'Tim Hortons Hay Al-Jamia': LatLng(33.2654, 44.3413), // University area
    'Domino\'s Kadhimiya': LatLng(33.3789, 44.3396), // Kadhimiya
    'Starbucks Masbah': LatLng(33.3045, 44.3525), // Masbah area
  };

  static const Map<String, LatLng> neighborhoods = {
    'Karrada': LatLng(33.3085, 44.3937),
    'Mansour': LatLng(33.3354, 44.3412),
    'Jadiriya': LatLng(33.2862, 44.3777),
    'Hay Al-Jamia': LatLng(33.2654, 44.3413),
    'Sadr City': LatLng(33.3547, 44.4547),
    'Kadhimiya': LatLng(33.3789, 44.3396),
    'Adhamiya': LatLng(33.3717, 44.3842),
    'Dora': LatLng(33.2354, 44.3521),
    'New Baghdad': LatLng(33.2917, 44.4438),
    'Zayouna': LatLng(33.3183, 44.4267),
    'Masbah': LatLng(33.3045, 44.3525),
    'Arasat': LatLng(33.3240, 44.3951),
  };

  // Central Baghdad coordinates for driver starting position
  static const LatLng driverStartPosition = LatLng(
    33.3152,
    44.3661,
  ); // Baghdad center

  /// Get a random restaurant location
  static MapEntry<String, LatLng> getRandomRestaurant() {
    final restaurantsList = restaurants.entries.toList();
    final random = Random();
    return restaurantsList[random.nextInt(restaurantsList.length)];
  }

  /// Get a random customer location
  static MapEntry<String, LatLng> getRandomCustomerLocation() {
    final neighborhoodsList = neighborhoods.entries.toList();
    final random = Random();
    final baseLocation =
        neighborhoodsList[random.nextInt(neighborhoodsList.length)];

    // Add small random offset to simulate specific address within neighborhood
    final randomOffset = 0.005; // ~500m radius
    final latOffset = (random.nextDouble() - 0.5) * randomOffset;
    final lngOffset = (random.nextDouble() - 0.5) * randomOffset;

    return MapEntry(
      '${baseLocation.key} Area',
      LatLng(
        baseLocation.value.latitude + latOffset,
        baseLocation.value.longitude + lngOffset,
      ),
    );
  }
}

class RoutePoint {
  final double latitude;
  final double longitude;

  RoutePoint({required this.latitude, required this.longitude});

  LatLng toLatLng() => LatLng(latitude, longitude);
  
  Point toPoint() => Point(coordinates: Position(longitude, latitude));
}

// Helper functions for coordinate conversion
LatLng pointToLatLng(Point point) {
  return LatLng(point.coordinates.lat.toDouble(), point.coordinates.lng.toDouble());
}

Point latLngToPoint(LatLng latLng) {
  return Point(coordinates: Position(latLng.longitude, latLng.latitude));
}

class RouteResult {
  final List<RoutePoint> points;
  final double distanceKm;
  final double durationMinutes;
  final String geometry;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.geometry,
  });
}

class RoutingService {
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  /// Get route between two points using OSRM (OpenStreetMap Routing Machine)
  Future<RouteResult?> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      // OSRM format: longitude,latitude (note the order!)
      final startCoord = '${start.longitude},${start.latitude}';
      final endCoord = '${end.longitude},${end.latitude}';

      final url =
          '$_osrmBaseUrl/route/v1/driving/$startCoord;$endCoord'
          '?steps=true&geometries=geojson&overview=full';

      debugPrint('Fetching route from OSRM: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final distance = route['distance'] / 1000.0; // Convert to km
          final duration = route['duration'] / 60.0; // Convert to minutes

          // Extract route points from geometry
          List<RoutePoint> points = [];
          if (geometry['coordinates'] != null) {
            for (final coord in geometry['coordinates']) {
              points.add(
                RoutePoint(
                  longitude: coord[0].toDouble(),
                  latitude: coord[1].toDouble(),
                ),
              );
            }
          }

          return RouteResult(
            points: points,
            distanceKm: distance,
            durationMinutes: duration,
            geometry: json.encode(geometry),
          );
        }
      }

      debugPrint('OSRM routing failed with status: ${response.statusCode}');
      debugPrint('Response: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error fetching route: $e');
      return null;
    }
  }

  /// Get route with multiple waypoints (driver -> restaurant -> customer) - Mapbox Point version
  Future<Map<String, RouteResult?>> getDeliveryRoute({
    Point? driverLocation,
    Point? restaurantLocation,
    Point? customerLocation,
    LatLng? driverLocationLatLng,
    LatLng? restaurantLocationLatLng,
    LatLng? customerLocationLatLng,
  }) async {
    try {
      // Convert Point to LatLng if needed
      final LatLng driverLatLng = driverLocation != null 
          ? pointToLatLng(driverLocation)
          : driverLocationLatLng!;
      final LatLng restaurantLatLng = restaurantLocation != null 
          ? pointToLatLng(restaurantLocation)
          : restaurantLocationLatLng!;
      final LatLng customerLatLng = customerLocation != null 
          ? pointToLatLng(customerLocation)
          : customerLocationLatLng!;

      // Get both route segments
      final driverToRestaurant = await getRoute(
        start: driverLatLng,
        end: restaurantLatLng,
      );

      final restaurantToCustomer = await getRoute(
        start: restaurantLatLng,
        end: customerLatLng,
      );

      return {
        'driverToRestaurant': driverToRestaurant,
        'restaurantToCustomer': restaurantToCustomer,
      };
    } catch (e) {
      debugPrint('Error fetching delivery route: $e');
      return {'driverToRestaurant': null, 'restaurantToCustomer': null};
    }
  }

  /// Fallback: Create straight line route if API fails
  RouteResult createStraightLineRoute({
    required LatLng start,
    required LatLng end,
  }) {
    final distance =
        geo.Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000.0; // Convert to km
    final duration = distance / 30.0 * 60; // Assume 30 km/h average speed

    return RouteResult(
      points: [
        RoutePoint(latitude: start.latitude, longitude: start.longitude),
        RoutePoint(latitude: end.latitude, longitude: end.longitude),
      ],
      distanceKm: distance,
      durationMinutes: duration,
      geometry: '',
    );
  }
}
