import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../app_colors.dart';

class MapboxDebugScreen extends StatefulWidget {
  const MapboxDebugScreen({super.key});

  @override
  State<MapboxDebugScreen> createState() => _MapboxDebugScreenState();
}

class _MapboxDebugScreenState extends State<MapboxDebugScreen> {
  MapboxMap? _mapController;
  String _status = 'Initializing...';
  String _errorDetails = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox Debug'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.grey100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_status',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_errorDetails.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Error: $_errorDetails',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Map Provider: Mapbox GL JS',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Map View
          Expanded(
            child: MapWidget(
              key: const ValueKey("mapWidget"),
              onMapCreated: (MapboxMap mapboxMap) {
                try {
                  _mapController = mapboxMap;
                  setState(() {
                    _status = '✅ Map Controller Initialized';
                    _errorDetails = '';
                  });
                  debugPrint('✅ Mapbox Debug: Controller initialized successfully');
                  _setupMap();
                } catch (e) {
                  setState(() {
                    _status = '❌ Controller Initialization Failed';
                    _errorDetails = e.toString();
                  });
                  debugPrint('❌ Mapbox Debug: Controller error: $e');
                }
              },
              onTapListener: (context) {
                final point = context.point;
                debugPrint('🗺️ Map tapped at: ${point.coordinates.lat}, ${point.coordinates.lng}');
                setState(() {
                  _status = '🗺️ Map Interactive - Tapped: ${point.coordinates.lat.toStringAsFixed(4)}, ${point.coordinates.lng.toStringAsFixed(4)}';
                });
              },
              onCameraChangeListener: (cameraChangedEventData) {
                setState(() {
                  _status = '📹 Camera Moving - Zoom: ${cameraChangedEventData.cameraState.zoom.toStringAsFixed(1)}';
                });
              },
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _centerOnBaghdad();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Center on Baghdad'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _status = 'Testing map functionality...';
                          });
                          _runMapTests();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Run Tests'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grey600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setupMap() async {
    try {
      // Set initial camera position
      final baghdadCoordinate = Point(coordinates: Position(44.3661, 33.3152));
      await _mapController?.setCamera(
        CameraOptions(
          center: baghdadCoordinate,
          zoom: 13.0,
        ),
      );

      // Add a test marker
      final pointAnnotationManager = await _mapController?.annotations.createPointAnnotationManager();
      await pointAnnotationManager?.create(
        PointAnnotationOptions(
          geometry: baghdadCoordinate,
          textField: "Test Marker",
          textOffset: [0.0, -2.0],
          iconImage: "default_marker",
        ),
      );

      setState(() {
        _status = '✅ Map Setup Complete';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Map Setup Failed';
        _errorDetails = e.toString();
      });
      debugPrint('❌ Mapbox Debug: Setup error: $e');
    }
  }

  void _centerOnBaghdad() async {
    try {
      final baghdadCoordinate = Point(coordinates: Position(44.3661, 33.3152));
      await _mapController?.setCamera(
        CameraOptions(
          center: baghdadCoordinate,
          zoom: 15.0,
        ),
      );
    } catch (e) {
      debugPrint('❌ Mapbox Debug: Center error: $e');
    }
  }

  void _runMapTests() async {
    try {
      // Test 1: Camera movement
      setState(() {
        _status = 'Test 1/3: Camera movement...';
      });
      final coordinate1 = Point(coordinates: Position(44.3661, 33.3152));
      await _mapController?.setCamera(
        CameraOptions(
          center: coordinate1,
          zoom: 12.0,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));

      // Test 2: Zoom
      setState(() {
        _status = 'Test 2/3: Zoom functionality...';
      });
      await _mapController?.setCamera(
        CameraOptions(
          zoom: 16.0,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));

      // Test 3: Different location
      setState(() {
        _status = 'Test 3/3: Location change...';
      });
      final coordinate2 = Point(coordinates: Position(44.4139, 33.2778));
      await _mapController?.setCamera(
        CameraOptions(
          center: coordinate2,
          zoom: 14.0,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _status = '✅ All tests completed successfully!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Test failed';
        _errorDetails = e.toString();
      });
      debugPrint('❌ Mapbox Debug: Test error: $e');
    }
  }
}
