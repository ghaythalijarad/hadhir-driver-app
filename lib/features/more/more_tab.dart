import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/driver_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/driver_service.dart';
import '../../test_cognito_registration.dart';
import 'screens/account_details_screen.dart';
import 'screens/app_settings_screen.dart';
import 'screens/delivery_equipment_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/identity_verification_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/support_screen.dart';
import 'screens/vehicle_info_screen.dart';

class MoreTab extends StatefulWidget {
  final ValueChanged<bool>? onDashStatusChanged;
  final bool isDashing;

  const MoreTab({super.key, this.onDashStatusChanged, this.isDashing = false});

  @override
  State<MoreTab> createState() => _MoreTabState();
}

class _MoreTabState extends State<MoreTab> {
  DriverProfile? _driverProfile;
  bool _isLoading = true;
  bool _isHotspotActive = false;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    try {
      final profile = await DriverService.getDriverProfile();
      setState(() {
        _driverProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(),
                  _buildSection(
                    title: 'Driver Tools',
                    items: [
                      _buildMenuItem(
                        icon: Icons.account_balance_wallet,
                        title: 'Wallet',
                        subtitle: 'View earnings and balance',
                        onTap: _showWalletDialog,
                      ),
                      _buildMenuItem(
                        icon: Icons.wifi_tethering,
                        title: 'Hotspot',
                        subtitle: _isHotspotActive ? 'Active' : 'Inactive',
                        onTap: _toggleHotspot,
                      ),
                      if (widget.isDashing)
                        _buildMenuItem(
                          icon: Icons.stop_circle,
                          title: 'WIZZ off',
                          subtitle: 'End your dash session',
                          onTap: _showStopDashDialog,
                        ),
                    ],
                  ),
                  _buildSection(
                    title: 'Account',
                    items: [
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        title: 'Account Details',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AccountDetailsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.payment_outlined,
                        title: 'Payment Methods',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PaymentMethodsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Instant Pay',
                        subtitle: 'Get paid instantly',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Instant payment setup would open here',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'Tax Information',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Tax information screen would open here',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Vehicle & Equipment',
                    items: [
                      _buildMenuItem(
                        icon: Icons.directions_car_outlined,
                        title: 'Vehicle Information',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VehicleInfoScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.local_shipping_outlined,
                        title: 'Delivery Equipment',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeliveryEquipmentScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.phone_android_outlined,
                        title: 'Phone Number',
                        subtitle: _driverProfile?.phone ?? 'Not set',
                        onTap: () {
                          _showPhoneUpdateDialog();
                        },
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Safety',
                    items: [
                      _buildMenuItem(
                        icon: Icons.security_outlined,
                        title: 'Safety Toolkit',
                        onTap: () {
                          _showSafetyDialog();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.contact_emergency_outlined,
                        title: 'Emergency Contacts',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmergencyContactsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.verified_user_outlined,
                        title: 'Identity Verification',
                        subtitle: _getVerificationStatus(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const IdentityVerificationScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Support',
                    items: [
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SupportScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.chat_bubble_outline,
                        title: 'Support',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SupportScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.feedback_outlined,
                        title: 'Feedback',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FeedbackScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'Legal',
                    items: [
                      _buildMenuItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () {
                          _showTermsDialog();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          _showPrivacyDialog();
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.gavel_outlined,
                        title: 'Occupational Accident Policy',
                        onTap: () {
                          _showAccidentPolicyDialog();
                        },
                      ),
                    ],
                  ),
                  _buildSection(
                    title: 'App',
                    items: [
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AppSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'Version 1.0.0',
                        onTap: () {
                          _showAboutDialog();
                        },
                      ),
                    ],
                  ),
                  // Debug section (only show in development)
                  _buildSection(
                    title: 'Debug & Testing',
                    items: [
                      _buildMenuItem(
                        icon: Icons.wifi_find_outlined,
                        title: 'Test Backend Connection',
                        subtitle: 'Verify AWS Cognito connectivity',
                        onTap: () async {
                          _showSnackBar(
                            'Testing backend connection...',
                            isLoading: true,
                          );
                          await TestCognitoRegistration.testCognitoConnection();
                          _showSnackBar(
                            'Connection test completed - check console for details',
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.account_circle_outlined,
                        title: 'Test Account Creation',
                        subtitle: 'Create a test Cognito account',
                        onTap: () async {
                          _showSnackBar(
                            'Creating test account...',
                            isLoading: true,
                          );
                          await TestCognitoRegistration.createTestAccount();
                          _showSnackBar(
                            'Account creation test completed - check console',
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: Icons.phone_android_outlined,
                        title: 'Test Phone Registration',
                        subtitle: 'Test phone-based registration',
                        onTap: () async {
                          _showSnackBar(
                            'Testing phone registration...',
                            isLoading: true,
                          );
                          await TestCognitoRegistration.createTestAccountWithPhone();
                          _showSnackBar(
                            'Phone registration test completed - check console',
                          );
                        },
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.all(16),
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        _showSignOutDialog();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AccountDetailsScreen(),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _driverProfile?.name ?? 'Driver Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_driverProfile?.rating.toStringAsFixed(1) ?? '4.9'} • Driver since ${_getJoinedDate()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  String _getJoinedDate() {
    if (_driverProfile?.joinDate != null) {
      final date = _driverProfile!.joinDate;
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
    return 'Nov 2023';
  }

  String _getVerificationStatus() {
    if (_driverProfile?.isVerified == true) {
      return 'Verified';
    }
    return 'Pending verification';
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  void _showPhoneUpdateDialog() {
    final TextEditingController phoneController = TextEditingController();
    // Capture the parent context to safely use after awaits
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Phone Number'),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+964 123 456 7890',
            prefixText: '+964 ',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (phoneController.text.isNotEmpty) {
                Navigator.pop(dialogContext);
                final success = await DriverService.updatePhoneNumber(
                  phoneController.text,
                );
                if (!parentContext.mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Phone number updated successfully'
                          : 'Failed to update phone number',
                    ),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
                if (success) _loadDriverProfile();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showSafetyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Toolkit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.error),
              title: const Text('Emergency Call'),
              subtitle: const Text('Call 911'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Emergency calling feature'),
                    backgroundColor: AppColors.error,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.primary),
              title: const Text('Share Location'),
              subtitle: const Text('Share with emergency contact'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Location sharing enabled')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: AppColors.warning),
              title: const Text('Report Issue'),
              subtitle: const Text('Report safety concern'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report safety issue')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Here would be the Terms of Service content...\n\n'
            'This would contain the full legal terms and conditions for using the Hadhir Driver app.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Here would be the Privacy Policy content...\n\n'
            'This would contain information about how user data is collected, used, and protected.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAccidentPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Occupational Accident Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Here would be the Occupational Accident Policy content...\n\n'
            'This would contain information about accident coverage and procedures.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Hadhir Driver'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: 2024.12.15'),
            SizedBox(height: 8),
            Text('© 2024 Hadhir, Inc.'),
            SizedBox(height: 8),
            Text('Made for Iraqi drivers'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signOut();
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );

      // Use AuthProvider for logout
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) Navigator.pop(context); // Close loading dialog

      // Navigate to enhanced cognito login screen using GoRouter
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الخروج: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Wallet'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Balance',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_getWalletBalance().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildWalletItem('Today\'s Earnings', '\$23.40'),
            _buildWalletItem('This Week', '\$187.25'),
            _buildWalletItem('Last Payout', '\$156.80'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCashOutDialog();
                    },
                    icon: const Icon(Icons.money, size: 18),
                    label: const Text('Cash Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEarningsHistoryDialog();
                    },
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletItem(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showCashOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cash Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select cash out method:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.account_balance,
                color: AppColors.primary,
              ),
              title: const Text('Bank Transfer'),
              subtitle: const Text('Available in 1-3 business days'),
              onTap: () {
                Navigator.pop(context);
                _processCashOut('bank');
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on, color: AppColors.warning),
              title: const Text('Instant Transfer'),
              subtitle: const Text('Available in minutes (\$1.99 fee)'),
              onTap: () {
                Navigator.pop(context);
                _processCashOut('instant');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _processCashOut(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          method == 'instant'
              ? 'Instant cash out initiated. Funds will arrive in minutes.'
              : 'Bank transfer initiated. Funds will arrive in 1-3 business days.',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showEarningsHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Earnings History'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEarningsHistoryItem('Today', '\$23.40', '3 deliveries'),
              _buildEarningsHistoryItem('Yesterday', '\$31.20', '4 deliveries'),
              _buildEarningsHistoryItem('Dec 14', '\$28.75', '3 deliveries'),
              _buildEarningsHistoryItem('Dec 13', '\$45.10', '5 deliveries'),
              _buildEarningsHistoryItem('Dec 12', '\$38.90', '4 deliveries'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsHistoryItem(
    String date,
    String amount,
    String deliveries,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                deliveries,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleHotspot() {
    setState(() {
      _isHotspotActive = !_isHotspotActive;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isHotspotActive
              ? 'Hotspot activated. You\'ll receive more orders in busy areas.'
              : 'Hotspot deactivated. You\'ll receive orders based on normal zones.',
        ),
        backgroundColor: _isHotspotActive
            ? AppColors.success
            : AppColors.warning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showStopDashDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.stop_circle, color: AppColors.error),
            const SizedBox(width: 8),
            const Text('WIZZ off'),
          ],
        ),
        content: const Text(
          'Are you sure you want to stop your dash? You won\'t receive any new delivery opportunities.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopDash();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('WIZZ off'),
          ),
        ],
      ),
    );
  }

  void _stopDash() {
    if (widget.onDashStatusChanged != null) {
      widget.onDashStatusChanged!(false);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dash stopped. Have a great day!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );
  }

  double _getWalletBalance() {
    // Calculate wallet balance based on driver's total deliveries or use a mock value
    // In a real app, this would come from the backend
    if (_driverProfile != null) {
      // Mock calculation: $1.50 per delivery as base balance
      return (_driverProfile!.totalDeliveries * 1.5) + 25.0;
    }
    return 45.50; // Default mock balance
  }

  void _showSnackBar(String message, {bool isLoading = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (isLoading) const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        duration: Duration(seconds: isLoading ? 10 : 3),
        backgroundColor: isLoading ? AppColors.primary : AppColors.success,
      ),
    );
  }
}
