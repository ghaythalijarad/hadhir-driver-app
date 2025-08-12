import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/order_model.dart';
import '../../services/order_notification_service.dart';
import '../../widgets/navigation_button.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(status) {
    switch (status) {
      case OrderStatus.accepted:
        return AppColors.primary;
      case OrderStatus.arrivedAtRestaurant:
        return AppColors.warning;
      case OrderStatus.pickedUp:
        return AppColors.accent;
      case OrderStatus.arrivedToCustomer:
        return AppColors.warning;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.failed:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(OrderStatus status, AppLocalizations localizations) {
    switch (status) {
      case OrderStatus.accepted:
        return localizations.acceptOrder;
      case OrderStatus.arrivedAtRestaurant:
        return localizations.arrivedAtRestaurant;
      case OrderStatus.pickedUp:
        return localizations.orderPickedUp;
      case OrderStatus.arrivedToCustomer:
        return localizations.arrivedToCustomer;
      case OrderStatus.delivered:
        return localizations.deliveredToCustomer;
      case OrderStatus.cancelled:
        return localizations.cancelled;
      case OrderStatus.failed:
        return localizations.failed;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final orderNotificationService = Provider.of<OrderNotificationService>(
      context,
    );
    final activeOrders = orderNotificationService.activeOrders;
    final completedOrders = orderNotificationService.completedOrders;

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        title: Text(
          localizations.orders,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primary,
              ),
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.grey600,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Text(localizations.active),
                      if (activeOrders.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${activeOrders.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 18),
                      const SizedBox(width: 8),
                      Text(localizations.completed),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrders(context, activeOrders, orderNotificationService),
          _buildCompletedOrders(completedOrders),
        ],
      ),
    );
  }

  Widget _buildActiveOrders(
    BuildContext context,
    List orders,
    OrderNotificationService notificationService,
  ) {
    final localizations = AppLocalizations.of(context)!;
    if (orders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.cube_box,
                size: 64,
                color: CupertinoColors.inactiveGray,
              ),
              SizedBox(height: 16),
              Text(
                localizations.noActiveOrders,
                style: TextStyle(
                  fontSize: 18,
                  color: CupertinoColors.inactiveGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                localizations.acceptOrderToStart,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.inactiveGray,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ScrollConfiguration(
      behavior: const CupertinoScrollBehavior(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final order = orders[index];
          return Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: CupertinoColors.separator, width: 0.5),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.activeBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          order.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(order.status, localizations),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  order.restaurantName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${localizations.customer}: ${order.customerName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.customerAddress,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.location,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${order.distance.toStringAsFixed(1)}km',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      CupertinoIcons.money_dollar,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${order.totalAmount.toStringAsFixed(0)} IQD',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      CupertinoIcons.time,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${order.estimatedDeliveryTime.hour}:${order.estimatedDeliveryTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Navigation buttons based on order status
                if (order.status == OrderStatus.accepted || 
                    order.status == OrderStatus.arrivedAtRestaurant) ...[
                  NavigationButton(
                    order: order,
                    navigationType: 'restaurant',
                  ),
                  const SizedBox(height: 8),
                ] else if (order.status == OrderStatus.pickedUp || 
                           order.status == OrderStatus.arrivedToCustomer) ...[
                  NavigationButton(
                    order: order,
                    navigationType: 'customer',
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Status progression button
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoButton.filled(
                          borderRadius: BorderRadius.circular(8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          onPressed: () {
                            setState(() {
                              if (order.status == OrderStatus.accepted) {
                                order.status = OrderStatus.arrivedAtRestaurant;
                              } else if (order.status ==
                                  OrderStatus.arrivedAtRestaurant) {
                                order.status = OrderStatus.pickedUp;
                              } else if (order.status == OrderStatus.pickedUp) {
                                order.status = OrderStatus.arrivedToCustomer;
                              } else if (order.status ==
                                  OrderStatus.arrivedToCustomer) {
                                order.status = OrderStatus.delivered;
                                notificationService.completeActiveOrder(order);
                              }
                            });
                          },
                          child: Text(
                            order.status == OrderStatus.accepted
                                ? localizations.arrivedAtRestaurant
                                : order.status ==
                                      OrderStatus.arrivedAtRestaurant
                                ? localizations.orderPickedUp
                                : order.status == OrderStatus.pickedUp
                                ? localizations.arrivedToCustomer
                                : localizations.deliveredToCustomer,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        color: CupertinoColors.activeBlue,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () {
                          GoRouter.of(
                            context,
                          ).go('/navigation', extra: {'order': order});
                        },
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletedOrders(List orders) {
    return Builder(
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        if (orders.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              // Ensures scrollability even when empty
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.check_mark_circled,
                    size: 64,
                    color: CupertinoColors.inactiveGray,
                  ),
                  SizedBox(height: 16),
                  Text(
                    localizations.noCompletedOrders,
                    style: TextStyle(
                      fontSize: 18,
                      color: CupertinoColors.inactiveGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    localizations.yourDeliveryHistory,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.inactiveGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ScrollConfiguration(
          behavior: const CupertinoScrollBehavior(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.id,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.star_fill,
                          color: CupertinoColors.systemYellow,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      order.restaurantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppLocalizations.of(context)!.customer}: ${order.customerName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customerAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location,
                          size: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${order.distance.toStringAsFixed(1)}km',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          CupertinoIcons.money_dollar,
                          size: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${order.totalAmount.toStringAsFixed(0)} IQD',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // OrderModel does not have deliveredAt; use estimatedDeliveryTime as fallback
                      'Completed:  0{order.estimatedDeliveryTime.toString()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.inactiveGray,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
