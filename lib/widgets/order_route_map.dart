import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../app_colors.dart';
import '../models/order_model.dart';
import '../services/routing_service.dart';

class OrderRouteMap extends StatefulWidget {
  final OrderModel order;
  final double height;
  final bool isInDialog;
  final Point? driverLocation;

  const OrderRouteMap({
    super.key,
    required this.order,
    this.height = 200,
    this.isInDialog = false,
    this.driverLocation,
  });

  @override
  State<OrderRouteMap> createState() => _OrderRouteMapState();
}

class _OrderRouteMapState extends State<OrderRouteMap> {
  final RoutingService _routingService = RoutingService();
  RouteResult? _driverToRestaurantRoute;
  RouteResult? _restaurantToCustomerRoute;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    // Load route if we have driver location
    if (widget.driverLocation != null) {
      _loadRealRoute();
    }
  }

  Future<void> _loadRealRoute() async {
    if (widget.driverLocation == null) return;

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final restaurantLocation = Point(coordinates: Position(
        widget.order.restaurantLocation.longitude,
        widget.order.restaurantLocation.latitude,
      ));

      final customerLocation = Point(coordinates: Position(
        widget.order.customerLocation.longitude,
        widget.order.customerLocation.latitude,
      ));

      final routes = await _routingService.getDeliveryRoute(
        driverLocation: widget.driverLocation!,
        restaurantLocation: restaurantLocation,
        customerLocation: customerLocation,
      );

      setState(() {
        _driverToRestaurantRoute = routes['driverToRestaurant'];
        _restaurantToCustomerRoute = routes['restaurantToCustomer'];
        _isLoadingRoute = false;
      });
    } catch (e) {
      debugPrint('Error loading route: $e');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widget.isInDialog
            ? _buildStaticRouteView()
            : _buildInteractiveMap(),
      ),
    );
  }

  Widget _buildStaticRouteView() {
    // For dialog display, show a simplified static view
    return Container(
      color: AppColors.grey100,
      child: Stack(
        children: [
          // Background pattern to simulate map
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.grey100, AppColors.grey200],
              ),
            ),
          ),
          // Route visualization
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLocationIcon(
                      Icons.my_location,
                      AppColors.primary,
                      'Driver',
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.grey600,
                      size: 20,
                    ),
                    _buildLocationIcon(
                      Icons.restaurant,
                      AppColors.warning,
                      'Restaurant',
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: AppColors.grey600,
                      size: 20,
                    ),
                    _buildLocationIcon(
                      Icons.home,
                      AppColors.success,
                      'Customer',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.order.formattedDistance} • ${widget.order.formattedTripDuration}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationIcon(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveMap() {
    final driverLocation = widget.driverLocation ?? Point(coordinates: Position(44.3661, 33.3152));
    final restaurantLocation = Point(coordinates: Position(
      widget.order.restaurantLocation.longitude,
      widget.order.restaurantLocation.latitude,
    ));
    final customerLocation = Point(coordinates: Position(
      widget.order.customerLocation.longitude,
      widget.order.customerLocation.latitude,
    ));

    // Calculate center point and zoom to show all locations
    final bounds = _calculateBounds([
      driverLocation,
      restaurantLocation,
      customerLocation,
    ]);

    return Stack(
      children: [
        MapWidget(
          key: ValueKey("orderRouteMapWidget"),
          cameraOptions: CameraOptions(
            center: bounds['center'] as Point,
            zoom: bounds['zoom'] as double,
          ),
          onMapCreated: (MapboxMap mapboxMap) async {
            await _setupMapAnnotations(mapboxMap, driverLocation, restaurantLocation, customerLocation);
          },
        ),
        // Loading indicator
        if (_isLoadingRoute)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        // Route info overlay
        _buildRouteInfoOverlay(),
      ],
    );
  }

  Future<void> _setupMapAnnotations(
    MapboxMap mapboxMap,
    Point driverLocation,
    Point restaurantLocation,
    Point customerLocation,
  ) async {
    await _updateMapAnnotations(mapboxMap);
  }

  Future<void> _updateMapAnnotations(MapboxMap mapboxMap) async {
    // Create annotation managers
    final pointManager = await mapboxMap.annotations.createPointAnnotationManager();
    final polylineManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    // Add location markers
    final driverLocation = widget.driverLocation ?? Point(coordinates: Position(44.3661, 33.3152));
    final restaurantLocation = Point(coordinates: Position(
      widget.order.restaurantLocation.longitude,
      widget.order.restaurantLocation.latitude,
    ));
    final customerLocation = Point(coordinates: Position(
      widget.order.customerLocation.longitude,
      widget.order.customerLocation.latitude,
    ));

    final markers = [
      PointAnnotationOptions(
        geometry: driverLocation,
      ),
      PointAnnotationOptions(
        geometry: restaurantLocation,
      ),
      PointAnnotationOptions(
        geometry: customerLocation,
      ),
    ];

    await pointManager.createMulti(markers);

    // Add route polylines
    await _addRoutePolylines(polylineManager, driverLocation, restaurantLocation, customerLocation);
  }

  Future<void> _addRoutePolylines(
    PolylineAnnotationManager polylineManager,
    Point driverLocation,
    Point restaurantLocation,
    Point customerLocation,
  ) async {
    final polylines = <PolylineAnnotationOptions>[];

    if (_driverToRestaurantRoute != null && _restaurantToCustomerRoute != null) {
      // Use real route data
      final driverToRestaurantPoints = _driverToRestaurantRoute!.points
          .map((p) => Position(p.longitude, p.latitude))
          .toList();
      
      final restaurantToCustomerPoints = _restaurantToCustomerRoute!.points
          .map((p) => Position(p.longitude, p.latitude))
          .toList();

      polylines.add(PolylineAnnotationOptions(
        geometry: LineString(coordinates: driverToRestaurantPoints),
        lineColor: AppColors.primary.toARGB32(),
        lineWidth: 4.0,
      ));

      polylines.add(PolylineAnnotationOptions(
        geometry: LineString(coordinates: restaurantToCustomerPoints),
        lineColor: AppColors.success.toARGB32(),
        lineWidth: 3.0,
      ));
    } else {
      // Fallback to straight lines
      polylines.add(PolylineAnnotationOptions(
        geometry: LineString(coordinates: [
          driverLocation.coordinates,
          restaurantLocation.coordinates,
        ]),
        lineColor: AppColors.primary.toARGB32(),
        lineWidth: 3.0,
      ));

      polylines.add(PolylineAnnotationOptions(
        geometry: LineString(coordinates: [
          restaurantLocation.coordinates,
          customerLocation.coordinates,
        ]),
        lineColor: AppColors.success.toARGB32(),
        lineWidth: 3.0,
      ));
    }

    if (polylines.isNotEmpty) {
      await polylineManager.createMulti(polylines);
    }
  }

  Widget _buildRouteInfoOverlay() {
    if (_isLoadingRoute) return const SizedBox.shrink();

    String routeInfo = '';
    if (_driverToRestaurantRoute != null &&
        _restaurantToCustomerRoute != null) {
      final totalDistance =
          _driverToRestaurantRoute!.distanceKm +
          _restaurantToCustomerRoute!.distanceKm;
      final totalDuration =
          _driverToRestaurantRoute!.durationMinutes +
          _restaurantToCustomerRoute!.durationMinutes;
      routeInfo =
          '${totalDistance.toStringAsFixed(1)} km • ${totalDuration.toStringAsFixed(0)} min';
    } else {
      routeInfo =
          '${widget.order.formattedDistance} • ${widget.order.formattedTripDuration}';
    }

    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                routeInfo,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_driverToRestaurantRoute != null &&
                _restaurantToCustomerRoute != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'مسار حقيقي',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateBounds(List<Point> locations) {
    if (locations.isEmpty) {
      return {
        'center': Point(coordinates: Position(44.3661, 33.3152)),
        'zoom': 13.0
      };
    }

    double minLat = locations.first.coordinates.lat.toDouble();
    double maxLat = locations.first.coordinates.lat.toDouble();
    double minLng = locations.first.coordinates.lng.toDouble();
    double maxLng = locations.first.coordinates.lng.toDouble();

    for (final location in locations) {
      final lat = location.coordinates.lat.toDouble();
      final lng = location.coordinates.lng.toDouble();
      minLat = minLat < lat ? minLat : lat;
      maxLat = maxLat > lat ? maxLat : lat;
      minLng = minLng < lng ? minLng : lng;
      maxLng = maxLng > lng ? maxLng : lng;
    }

    // Add padding
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    // Calculate zoom level based on span
    final latSpan = maxLat - minLat;
    final lngSpan = maxLng - minLng;
    final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

    double zoom = 13.0;
    if (maxSpan > 0.1) {
      zoom = 10.0;
    } else if (maxSpan > 0.05) {
      zoom = 11.0;
    } else if (maxSpan > 0.02) {
      zoom = 12.0;
    } else if (maxSpan > 0.01) {
      zoom = 13.0;
    } else {
      zoom = 14.0;
    }

    return {
      'center': Point(coordinates: Position(centerLng, centerLat)),
      'zoom': zoom
    };
  }
}
