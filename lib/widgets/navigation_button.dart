import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../models/order_model.dart';
import '../services/mapbox_navigation_service.dart';

class NavigationButton extends StatelessWidget {
  final OrderModel order;
  final String navigationType; // 'restaurant' or 'customer'
  final VoidCallback? onNavigationStart;

  const NavigationButton({
    super.key,
    required this.order,
    required this.navigationType,
    this.onNavigationStart,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MapboxNavigationService>(
      builder: (context, navigationService, child) {
        final isNavigating = navigationService.isNavigating;
        // canNavigate is calculated but not used in current UI logic
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isNavigating ? null : () => _startNavigation(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: navigationType == 'restaurant' 
                  ? AppColors.primary 
                  : AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(
              navigationType == 'restaurant' 
                  ? Icons.restaurant 
                  : Icons.home,
              size: 20,
            ),
            label: Text(
              isNavigating 
                  ? 'Navigation Active'
                  : 'Navigate to ${navigationType == 'restaurant' ? 'Restaurant' : 'Customer'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startNavigation(BuildContext context) async {
    // navigationService is available but not used in current dialog logic
    
    // Show options dialog for navigation
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Navigation to ${navigationType == 'restaurant' ? 'Restaurant' : 'Customer'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              navigationType == 'restaurant' 
                  ? 'Navigate to ${order.restaurantName}?'
                  : 'Navigate to ${order.customerName}?',
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose your navigation option:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'in_app'),
            child: const Text('In-App Navigation'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'external'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Google Maps'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      if (result == 'external') {
        await _launchExternalNavigation(context);
      } else if (result == 'in_app') {
        await _startInAppNavigation(context);
      }
    }
  }

  Future<void> _startInAppNavigation(BuildContext context) async {
    onNavigationStart?.call();
    
    // Navigate to the full navigation page
    context.push('/navigation', extra: {
      'order': order,
      'navigationType': navigationType,
    });
  }

  Future<void> _launchExternalNavigation(BuildContext context) async {
    final navigationService = context.read<MapboxNavigationService>();
    
    final destination = navigationType == 'restaurant'
        ? order.restaurantLatLng
        : order.customerLatLng;
    
    final destinationName = navigationType == 'restaurant'
        ? order.restaurantName
        : order.customerName;
    
    final success = await navigationService.launchExternalNavigation(
      destination,
      destinationName: destinationName,
    );
    
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch external navigation app'),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Launched navigation to $destinationName'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
