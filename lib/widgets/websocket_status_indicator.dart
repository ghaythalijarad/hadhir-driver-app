import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../services/realtime_communication_service.dart';

class WebSocketStatusIndicator extends StatelessWidget {
  final bool showLabel;
  final double size;

  const WebSocketStatusIndicator({
    super.key,
    this.showLabel = true,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeCommunicationService>(
      builder: (context, service, child) {
        final isConnected = service.isConnected;
        final isOnline = service.isOnline;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _getStatusColor(isConnected, isOnline),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor(isConnected, isOnline).withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: isConnected
                  ? Container(
                      width: size * 0.6,
                      height: size * 0.6,
                      margin: EdgeInsets.all(size * 0.2),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            if (showLabel) ...[
              const SizedBox(width: 8),
              Text(
                _getStatusText(isConnected, isOnline),
                style: TextStyle(
                  color: _getStatusColor(isConnected, isOnline),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Color _getStatusColor(bool isConnected, bool isOnline) {
    if (!isConnected) {
      return AppColors.error;
    } else if (isOnline) {
      return AppColors.success;
    } else {
      return AppColors.warning;
    }
  }

  String _getStatusText(bool isConnected, bool isOnline) {
    if (!isConnected) {
      return 'غير متصل';
    } else if (isOnline) {
      return 'متاح';
    } else {
      return 'متصل';
    }
  }
}

class WebSocketStatusBanner extends StatelessWidget {
  const WebSocketStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeCommunicationService>(
      builder: (context, service, child) {
        if (service.isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.error,
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off,
                color: AppColors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'لا يوجد اتصال بالخادم المركزي',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Try to reconnect
                  service.goOnline();
                },
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ConnectionStatusDialog extends StatelessWidget {
  const ConnectionStatusDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeCommunicationService>(
      builder: (context, service, child) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi, color: AppColors.primary),
              SizedBox(width: 12),
              Text(
                'حالة الاتصال',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusItem(
                'الاتصال بالخادم',
                service.isConnected,
                service.isConnected ? 'متصل' : 'غير متصل',
              ),
              const SizedBox(height: 12),
              _buildStatusItem(
                'حالة السائق',
                service.isOnline,
                service.isOnline ? 'متاح للطلبات' : 'غير متاح',
              ),
              const SizedBox(height: 12),
              _buildStatusItem(
                'الطلبات النشطة',
                service.activeOrders.isNotEmpty,
                '${service.activeOrders.length} طلب',
              ),
              if (!service.isConnected) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: AppColors.error,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لن تتمكن من استقبال الطلبات الجديدة بدون اتصال',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (!service.isConnected)
              TextButton(
                onPressed: () {
                  service.goOnline();
                },
                child: const Text('إعادة الاتصال'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusItem(String label, bool isActive, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? AppColors.success : AppColors.grey400,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
