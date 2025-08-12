import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../app_colors.dart';
import '../models/order_model.dart';
import '../services/mapbox_navigation_service.dart';
import '../utils/coordinates.dart';

class MapboxNavigationWidget extends StatefulWidget {
  final OrderModel order;
  final String navigationType; // 'restaurant' or 'customer'
  final VoidCallback? onNavigationComplete;
  final VoidCallback? onNavigationCancel;

  const MapboxNavigationWidget({
    super.key,
    required this.order,
    required this.navigationType,
    this.onNavigationComplete,
    this.onNavigationCancel,
  });

  @override
  State<MapboxNavigationWidget> createState() => _MapboxNavigationWidgetState();
}

class _MapboxNavigationWidgetState extends State<MapboxNavigationWidget> {
  late MapboxNavigationService _navigationService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _navigationService = context.read<MapboxNavigationService>();
    _startNavigation();
  }

  Future<void> _startNavigation() async {
    setState(() {
      _isLoading = true;
    });

    bool success = false;
    
    if (widget.navigationType == 'restaurant') {
      success = await _navigationService.startNavigationToRestaurant(widget.order);
    } else {
      success = await _navigationService.startNavigationToCustomer(widget.order);
    }

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      _showErrorDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigation Error'),
        content: const Text('Failed to start navigation. Please try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onNavigationCancel?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map View for in-app navigation
          if (!_isLoading && _navigationService.isNavigating)
            _buildNavigationMap(),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'Starting Navigation...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Navigation controls overlay
          if (_navigationService.isNavigating)
            _buildNavigationControls(),
            
          // External navigation button
          if (_navigationService.isNavigating)
            _buildExternalNavigationButton(),
        ],
      ),
    );
  }

  /// Build the in-app navigation map
  Widget _buildNavigationMap() {
    if (!_navigationService.isNavigating || _navigationService.currentRoute == null) {
      return Container(
        color: AppColors.grey100,
        child: const Center(
          child: Text('Preparing navigation...'),
        ),
      );
    }

    final route = _navigationService.currentRoute!;
    final currentLocation = _navigationService.currentLocation;
    
    if (currentLocation == null) {
      return Container(
        color: AppColors.grey100,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Create map points
    final driverPoint = Point(
      coordinates: Position(currentLocation.longitude, currentLocation.latitude),
    );
    
    final destinationPoint = widget.navigationType == 'restaurant'
        ? Point(coordinates: Position(
            widget.order.restaurantLocation.longitude,
            widget.order.restaurantLocation.latitude,
          ))
        : Point(coordinates: Position(
            widget.order.customerLocation.longitude,
            widget.order.customerLocation.latitude,
          ));

    // Create route polyline
    final routePoints = route.points
        .map((p) => Position(p.longitude, p.latitude))
        .toList();

    return MapWidget(
      key: const ValueKey("navigationMapWidget"),
      cameraOptions: CameraOptions(
        center: driverPoint,
        zoom: 16.0,
      ),
      styleUri: MapboxStyles.STANDARD,
      onMapCreated: (MapboxMap mapboxMap) async {
        // Add markers
        final pointManager = await mapboxMap.annotations.createPointAnnotationManager();
        await pointManager.createMulti([
          PointAnnotationOptions(geometry: driverPoint),
          PointAnnotationOptions(geometry: destinationPoint),
        ]);

        // Add route polyline
        final polylineManager = await mapboxMap.annotations.createPolylineAnnotationManager();
        await polylineManager.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: routePoints),
            lineColor: AppColors.primary.toARGB32(),
            lineWidth: 5.0,
          ),
        );
      },
    );
  }

  Widget _buildNavigationControls() {
    return Consumer<MapboxNavigationService>(
      builder: (context, navService, child) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Destination info
                Row(
                  children: [
                    Icon(
                      widget.navigationType == 'restaurant'
                          ? Icons.restaurant
                          : Icons.home,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.navigationType == 'restaurant'
                            ? 'Navigating to ${widget.order.restaurantName}'
                            : 'Navigating to Customer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _showCancelDialog,
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Navigation info
                Row(
                  children: [
                    if (navService.getFormattedDistanceRemaining().isNotEmpty) ...[
                      Icon(Icons.navigation, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        navService.getFormattedDistanceRemaining(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (navService.getFormattedDurationRemaining().isNotEmpty) ...[
                      Icon(Icons.access_time, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        navService.getFormattedDurationRemaining(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Next instruction
                if (navService.nextInstruction != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.turn_right,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            navService.nextInstruction!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build external navigation button
  Widget _buildExternalNavigationButton() {
    return Positioned(
      bottom: 120,
      right: 16,
      child: FloatingActionButton(
        onPressed: _launchExternalNavigation,
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        heroTag: "externalNav",
        child: const Icon(Icons.navigation),
      ),
    );
  }

  /// Launch external navigation
  Future<void> _launchExternalNavigation() async {
    final destination = widget.navigationType == 'restaurant'
        ? LatLng(
            widget.order.restaurantLocation.latitude,
            widget.order.restaurantLocation.longitude,
          )
        : LatLng(
            widget.order.customerLocation.latitude,
            widget.order.customerLocation.longitude,
          );
    
    final destinationName = widget.navigationType == 'restaurant'
        ? widget.order.restaurantName
        : widget.order.customerName;
    
    final success = await _navigationService.launchExternalNavigation(
      destination,
      destinationName: destinationName,
    );
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch external navigation app'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Navigation'),
        content: const Text('Are you sure you want to cancel navigation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelNavigation();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelNavigation() async {
    await _navigationService.cancelNavigation();
    if (mounted) {
      widget.onNavigationCancel?.call();
    }
  }

  @override
  void dispose() {
    // Clean up navigation if still active
    if (_navigationService.isNavigating) {
      _navigationService.stopNavigation();
    }
    super.dispose();
  }
}

/// Native Mapbox Navigation View widget - Simplified fallback
class MapboxNavigationView extends StatelessWidget {
  const MapboxNavigationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Navigation Active',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Use the external navigation button to launch Google Maps',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
