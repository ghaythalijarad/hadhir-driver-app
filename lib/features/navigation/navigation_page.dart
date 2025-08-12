import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/order_marker.dart' as order_marker;
import '../../models/order_model.dart';
import '../../services/location_service.dart';
import '../../services/order_notification_service.dart';
import '../../services/routing_service.dart';
import '../../utils/coordinates.dart';

class NavigationPage extends StatefulWidget {
  final OrderModel order;
  final VoidCallback? onNavigationComplete;
  final VoidCallback? onNavigationCancelled;

  const NavigationPage({
    super.key,
    required this.order,
    this.onNavigationComplete,
    this.onNavigationCancelled,
  });

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  LocationService? _locationService;
  RoutingService? _routingService;

  // Navigation state
  order_marker.OrderMarker? _activeNavigationOrder;
  final bool _isNavigatingToRestaurant = true;
  RouteResult? _currentRoute;
  bool _isLoadingRoute = false;

  // Timer for periodic location updates
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _locationService = context.read<LocationService>();
    _routingService = RoutingService();

    // Ensure location service is initialized
    if (_locationService != null) {
      await _locationService!.initialize();
      await _locationService!.getCurrentLocation();
    }

    // Start periodic location updates
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (_locationService != null) {
        await _locationService!.getCurrentLocation();
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _initializeNavigation() {
    // Convert OrderModel to OrderMarker for navigation
    _activeNavigationOrder = order_marker.OrderMarker(
      id: widget.order.id,
      location: LatLng(
        widget.order.restaurantLocation.latitude,
        widget.order.restaurantLocation.longitude,
      ),
      restaurantName: widget.order.restaurantName,
      customerName: widget.order.customerName,
      address: widget.order.customerAddress,
      estimatedEarnings: widget.order.totalAmount,
      status: OrderStatus.accepted,
      type: order_marker.OrderType.delivery,
      items: widget.order.items,
      distance: widget.order.distance,
      estimatedTime: widget.order.estimatedDeliveryTime
          .difference(DateTime.now())
          .inMinutes,
      createdAt: widget.order.createdAt,
      totalAmount: widget.order.totalAmount,
      paymentMethod: widget.order.paymentMethod,
      acceptedAt: DateTime.now(),
    );

    // Calculate initial route
    _fetchAndDisplayRoute();
  }

  Future<void> _fetchAndDisplayRoute() async {
    if (_activeNavigationOrder == null) {
      return;
    }

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Use fallback location if real location isn't available
      final driverLocation =
          _locationService?.getLocationOrDefault() ??
          const LatLng(33.3152, 44.3661); // Baghdad fallback

      final destination = _isNavigatingToRestaurant
          ? _activeNavigationOrder!.location
          : LatLng(
              widget.order.customerLocation.latitude,
              widget.order.customerLocation.longitude,
            );

      final routeResult = await _routingService!.getRoute(
        start: driverLocation,
        end: destination,
      );

      if (routeResult != null && mounted) {
        setState(() {
          _currentRoute = routeResult;
          _isLoadingRoute = false;
        });

        _showRouteCalculatedMessage(routeResult);
      } else {
        // Fallback to straight line route - convert to Point for calculation
        final driverPoint = Point(
          coordinates: Position(
            driverLocation.longitude,
            driverLocation.latitude,
          ),
        );
        final destPoint = Point(
          coordinates: Position(destination.longitude, destination.latitude),
        );
        _createFallbackRoute(driverPoint, destPoint);
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _createFallbackRoute(Point start, Point end) {
    final distance = _calculateDistance(start, end) / 1000; // Convert to km
    final estimatedTime = (distance / 30 * 60).round(); // 30km/h average

    final fallbackRoute = RouteResult(
      points: [
        RoutePoint(
          latitude: start.coordinates.lat.toDouble(),
          longitude: start.coordinates.lng.toDouble(),
        ),
        RoutePoint(
          latitude: end.coordinates.lat.toDouble(),
          longitude: end.coordinates.lng.toDouble(),
        ),
      ],
      distanceKm: distance,
      durationMinutes: estimatedTime.toDouble(),
      geometry: '',
    );

    if (mounted) {
      setState(() {
        _currentRoute = fallbackRoute;
        _isLoadingRoute = false;
      });

      _showRouteCalculatedMessage(fallbackRoute);
    }
  }

  double _calculateDistance(Point point1, Point point2) {
    const double earthRadius = 6371000; // meters
    final double lat1Rad = point1.coordinates.lat.toDouble() * (3.14159 / 180);
    final double lat2Rad = point2.coordinates.lat.toDouble() * (3.14159 / 180);
    final double deltaLatRad =
        (point2.coordinates.lat.toDouble() -
            point1.coordinates.lat.toDouble()) *
        (3.14159 / 180);
    final double deltaLngRad =
        (point2.coordinates.lng.toDouble() -
            point1.coordinates.lng.toDouble()) *
        (3.14159 / 180);

    final double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  void _showRouteCalculatedMessage(RouteResult route) {
    final destination = _isNavigatingToRestaurant
        ? widget.order.restaurantName
        : widget.order.customerName;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Route to $destination: ${route.distanceKm.toStringAsFixed(1)}km, ${route.durationMinutes.toStringAsFixed(0)} minutes',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _cancelNavigation() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Close Navigation'),
        content: const Text(
          'Navigation will be closed. You can continue updating your order status from the Orders tab.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Stay Here'),
          ),
          TextButton(
            onPressed: () {
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
              _closeNavigationAndShowGuidance();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Go to Orders Tab'),
          ),
        ],
      ),
    );
  }

  void _closeNavigationAndShowGuidance() {
    if (!mounted) return;

    // Call cancellation callback if provided
    widget.onNavigationCancelled?.call();

    // Navigate back to home with Orders tab using pushReplacement to avoid stack issues
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && context.canPop()) {
        context.go('/?tab=1'); // Tab index 1 is Orders tab

        // Show guidance message after navigation
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Continue managing your order from the Orders tab below',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        });
      }
    });
  }

  Widget _buildProgressionButton() {
    final orderNotificationService = context.read<OrderNotificationService>();
    final order = widget.order;
    String buttonText = '';
    OrderStatus? nextStatus;

    switch (order.status) {
      case OrderStatus.accepted:
        buttonText = 'Arrived at Restaurant';
        nextStatus = OrderStatus.arrivedAtRestaurant;
        break;
      case OrderStatus.arrivedAtRestaurant:
        buttonText = 'Order Picked Up';
        nextStatus = OrderStatus.pickedUp;
        break;
      case OrderStatus.pickedUp:
        buttonText = 'Arrived to Customer';
        nextStatus = OrderStatus.arrivedToCustomer;
        break;
      case OrderStatus.arrivedToCustomer:
        buttonText = 'Delivered to Customer';
        nextStatus = OrderStatus.delivered;
        break;
      default:
        return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: () {
        orderNotificationService.updateOrderStatus(order.id, nextStatus!);
        setState(() {
          order.status = nextStatus!;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      child: Text(buttonText),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderNotificationService = Provider.of<OrderNotificationService>(
      context,
    );
    final hasNewOrderNotification =
        orderNotificationService.currentNotificationBatch != null &&
        orderNotificationService.activeOrders.length < 2;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNavigatingToRestaurant
              ? 'Going to Restaurant'
              : 'Going to Customer',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (hasNewOrderNotification)
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_active),
                  onPressed: () {
                    // Navigate to Home tab to accept the new batched order
                    context.go('/');
                  },
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${orderNotificationService.currentNotificationBatch?.orders.length ?? 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelNavigation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full screen map
          _buildNavigationMap(),

          // Navigation info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildNavigationPanel(),
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
        ],
      ),
    );
  }

  Widget _buildNavigationPanel() {
    if (_activeNavigationOrder == null) {
      return const SizedBox.shrink();
    }

    final order = _activeNavigationOrder!;
    final destination = _isNavigatingToRestaurant
        ? order.restaurantName
        : order.customerName;
    final destinationAddress = _isNavigatingToRestaurant
        ? 'Restaurant Location'
        : order.address;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navigation header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isNavigatingToRestaurant
                      ? AppColors.primary
                      : AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isNavigatingToRestaurant ? Icons.restaurant : Icons.home,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      destinationAddress,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentRoute != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_currentRoute!.distanceKm.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${_currentRoute!.durationMinutes.toStringAsFixed(0)} min',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Order details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        order.items.join(', '),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${order.totalAmount.toStringAsFixed(0)} IQD',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          _buildProgressionButton(),

          // Navigation instructions
          if (_currentRoute != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Follow the route shown on the map to reach your destination',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationMap() {
    if (_locationService?.currentLocation == null ||
        _activeNavigationOrder == null) {
      return Container(
        color: AppColors.grey100,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final driverLocation = Point(
      coordinates: Position(
        _locationService!.currentLocation!.longitude,
        _locationService!.currentLocation!.latitude,
      ),
    );

    // Create destination point
    final destinationLocation = _isNavigatingToRestaurant
        ? Point(
            coordinates: Position(
              _activeNavigationOrder!.location.longitude,
              _activeNavigationOrder!.location.latitude,
            ),
          )
        : Point(
            coordinates: Position(
              widget.order.customerLocation.longitude,
              widget.order.customerLocation.latitude,
            ),
          );

    // Create markers
    final markers = <PointAnnotationOptions>[
      PointAnnotationOptions(geometry: driverLocation),
      PointAnnotationOptions(geometry: destinationLocation),
    ];

    // Create polylines if route exists
    final polylines = <PolylineAnnotationOptions>[];
    if (_currentRoute != null) {
      final routePoints = _currentRoute!.points
          .map((point) => Position(point.longitude, point.latitude))
          .toList();

      polylines.add(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: routePoints),
          lineColor: AppColors.primary.toARGB32(),
          lineWidth: 5.0,
        ),
      );
    }

    return MapWidget(
      key: ValueKey("navigationMapWidget"),
      cameraOptions: CameraOptions(center: driverLocation, zoom: 14.0),
      styleUri: MapboxStyles.STANDARD,
      textureView: true,
      onMapCreated: (MapboxMap mapboxMap) async {
        // Add markers and polylines
        final pointManager = await mapboxMap.annotations
            .createPointAnnotationManager();
        final polylineManager = await mapboxMap.annotations
            .createPolylineAnnotationManager();

        // Convert PointAnnotation to PointAnnotationOptions
        final markerOptions = markers
            .map((marker) => PointAnnotationOptions(geometry: marker.geometry))
            .toList();

        await pointManager.createMulti(markerOptions);

        if (polylines.isNotEmpty) {
          // Convert PolylineAnnotation to PolylineAnnotationOptions
          final polylineOptions = polylines
              .map(
                (polyline) => PolylineAnnotationOptions(
                  geometry: polyline.geometry,
                  lineColor: polyline.lineColor,
                  lineWidth: polyline.lineWidth,
                ),
              )
              .toList();

          await polylineManager.createMulti(polylineOptions);
        }
      },
    );
  }
}
