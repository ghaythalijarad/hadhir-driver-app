import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/riverpod/locale_provider.dart';
import '../../../config/app_config.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  bool _pushNotifications = true;
  bool _orderNotifications = true;
  bool _promotionNotifications = false;
  bool _locationServices = true;
  bool _backgroundLocation = true;
  String _selectedTheme = 'System';

  // Developer settings state
  bool _forceProductionMode = false;
  bool _useMockData = false;

  @override
  void initState() {
    super.initState();
    _loadDeveloperSettings();
  }

  void _loadDeveloperSettings() async {
    await AppConfig.initialize();
    setState(() {
      _forceProductionMode = AppConfig.forceProductionMode;
      _useMockData = AppConfig.useMockData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeNotifierProvider);
    final localizations = AppLocalizations.of(context)!;
    final languageOptions = [
      localizations.arabic,
      localizations.english,
      ref.watch(languageNameProvider('ku')), // Add Kurdish option
    ];
    String getLanguageLabel(Locale locale) {
      switch (locale.languageCode) {
        case 'ar':
          return localizations.arabic;
        case 'ku':
          return ref.watch(languageNameProvider('ku'));
        case 'en':
        default:
          return localizations.english;
      }
    }

    String currentLanguageLabel = getLanguageLabel(currentLocale);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'App Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Notifications Section
            _buildSection(
              title: 'Notifications',
              children: [
                _buildSwitchTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications from the app',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Order Notifications',
                  subtitle: 'Get notified about new delivery orders',
                  value: _orderNotifications,
                  onChanged: (value) {
                    setState(() {
                      _orderNotifications = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Promotion Notifications',
                  subtitle:
                      'Receive notifications about promotions and bonuses',
                  value: _promotionNotifications,
                  onChanged: (value) {
                    setState(() {
                      _promotionNotifications = value;
                    });
                  },
                ),
              ],
            ),

            // Location Section
            _buildSection(
              title: 'Location Services',
              children: [
                _buildSwitchTile(
                  title: 'Location Services',
                  subtitle: 'Allow app to access your location',
                  value: _locationServices,
                  onChanged: (value) {
                    setState(() {
                      _locationServices = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Background Location',
                  subtitle: 'Track location in background for deliveries',
                  value: _backgroundLocation,
                  onChanged: (value) {
                    setState(() {
                      _backgroundLocation = value;
                    });
                  },
                ),
              ],
            ),

            // Language & Region Section
            _buildSection(
              title: localizations.language,
              children: [
                _buildDropdownTile(
                  title: localizations.language,
                  subtitle: localizations.language,
                  value: currentLanguageLabel,
                  options: languageOptions,
                  onChanged: (value) {
                    final localeNotifier = ref.read(localeNotifierProvider.notifier);
                    if (value == localizations.arabic) {
                      localeNotifier.setArabic();
                    } else if (value == localizations.english) {
                      localeNotifier.setEnglish();
                    } else if (value == ref.watch(languageNameProvider('ku'))) {
                      localeNotifier.setKurdish();
                    }
                    setState(() {}); // To update the dropdown UI
                  },
                ),
              ],
            ),

            // Appearance Section
            _buildSection(
              title: 'Appearance',
              children: [
                _buildDropdownTile(
                  title: 'Theme',
                  subtitle: 'App appearance theme',
                  value: _selectedTheme,
                  options: ['Light', 'Dark', 'System'],
                  onChanged: (value) {
                    setState(() {
                      _selectedTheme = value!;
                    });
                  },
                ),
              ],
            ),

            // Privacy Section
            _buildSection(
              title: 'Privacy',
              children: [
                _buildTappableTile(
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    _showPrivacyPolicy();
                  },
                ),
                _buildTappableTile(
                  title: 'Data Usage',
                  subtitle: 'Manage your data preferences',
                  icon: Icons.data_usage,
                  onTap: () {
                    _showDataUsage();
                  },
                ),
              ],
            ),

            // Security Section
            _buildSection(
              title: 'Security',
              children: [
                _buildTappableTile(
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  icon: Icons.lock_outline,
                  onTap: () {
                    _showChangePassword();
                  },
                ),
                _buildTappableTile(
                  title: 'Two-Factor Authentication',
                  subtitle: 'Enable 2FA for extra security',
                  icon: Icons.security,
                  onTap: () {
                    _showTwoFactorAuth();
                  },
                ),
              ],
            ),

            // Storage Section
            _buildSection(
              title: 'Storage',
              children: [
                _buildTappableTile(
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  icon: Icons.storage,
                  onTap: () {
                    _showClearCache();
                  },
                ),
                _buildTappableTile(
                  title: 'Download Settings',
                  subtitle: 'Manage offline data downloads',
                  icon: Icons.download,
                  onTap: () {
                    _showDownloadSettings();
                  },
                ),
              ],
            ),

            // Developer Settings Section
            _buildSection(
              title: 'Developer Settings',
              children: [
                _buildSwitchTile(
                  title: 'Force Production Mode',
                  subtitle: _forceProductionMode 
                      ? '🚀 AWS Cognito integration enabled'
                      : '🧪 Using mock data for registration',
                  value: _forceProductionMode,
                  onChanged: (value) {
                    AppConfig.setForceProductionMode(value).then((_) {
                      setState(() {
                        _forceProductionMode = value;
                        if (value) _useMockData = false;
                      });
                      AppConfig.printConfig();
                      _showProductionModeDialog(value);
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Use Mock Data',
                  subtitle: _useMockData 
                      ? 'Registration uses mock responses'
                      : 'Registration uses real backend',
                  value: _useMockData,
                  onChanged: _forceProductionMode ? null : (value) {
                    AppConfig.setUseMockData(value).then((_) {
                      setState(() {
                        _useMockData = value;
                      });
                    });
                  },
                ),
                _buildTappableTile(
                  title: 'Current Configuration',
                  subtitle: AppConfig.enableAWSIntegration 
                      ? 'AWS Integration: Active' 
                      : 'AWS Integration: Disabled',
                  icon: AppConfig.enableAWSIntegration 
                      ? Icons.cloud_done 
                      : Icons.cloud_off,
                  onTap: () {
                    _showConfigurationInfo();
                  },
                ),
                _buildTappableTile(
                  title: 'Test Registration',
                  subtitle: 'Test the current registration setup',
                  icon: Icons.bug_report,
                  onTap: () {
                    _testRegistrationMode();
                  },
                ),
              ],
            ),

            // About Section
            _buildSection(
              title: 'About',
              children: [
                _buildTappableTile(
                  title: 'App Version',
                  subtitle: '1.0.0 (Build 1)',
                  icon: Icons.info_outline,
                  onTap: () {
                    _showVersionInfo();
                  },
                ),
                _buildTappableTile(
                  title: 'Terms of Service',
                  subtitle: 'Read our terms of service',
                  icon: Icons.description,
                  onTap: () {
                    _showTermsOfService();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: Container(),
        items: options.map((option) {
          return DropdownMenuItem<String>(value: option, child: Text(option));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTappableTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
      onTap: onTap,
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy for Hadhir Driver App\n\n'
            '1. Information Collection\n'
            'We collect information necessary for delivery services including location data, contact information, and payment details.\n\n'
            '2. Data Usage\n'
            'Your data is used to facilitate deliveries, process payments, and improve our services.\n\n'
            '3. Data Sharing\n'
            'We do not share personal information with third parties without consent, except as required by law.\n\n'
            '4. Data Security\n'
            'We implement industry-standard security measures to protect your data.',
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

  void _showDataUsage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Data Usage'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data collected by the app:'),
            SizedBox(height: 12),
            Text('• Location data for navigation and delivery tracking'),
            Text('• Contact information for account management'),
            Text('• Vehicle information for delivery assignments'),
            Text('• Payment information for earnings processing'),
            Text('• Device information for app optimization'),
            SizedBox(height: 12),
            Text('You can manage your data preferences in the app settings.'),
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

  void _showChangePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement password change logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorAuth() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Two-Factor Authentication'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enhance your account security with two-factor authentication.',
            ),
            SizedBox(height: 16),
            Text('Available methods:'),
            SizedBox(height: 8),
            Text('• SMS verification'),
            Text('• Email verification'),
            Text('• Authenticator app'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('2FA setup feature coming soon'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Setup'),
          ),
        ],
      ),
    );
  }

  void _showClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear temporary files and may free up storage space. '
          'You may need to re-download some data when using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDownloadSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Download Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage offline data downloads:'),
            SizedBox(height: 16),
            Text('• Map data for offline navigation'),
            Text('• Delivery area information'),
            Text('• Restaurant location data'),
            SizedBox(height: 16),
            Text('Download over WiFi only to save mobile data.'),
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

  void _showVersionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('App Version'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hadhir Driver'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            Text('Build: 1 (2024.12.15)'),
            SizedBox(height: 16),
            Text('© 2024 Hadhir Delivery'),
            SizedBox(height: 16),
            Text('For support, contact: support@hadhir.com'),
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

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service for Hadhir Driver App\n\n'
            '1. Acceptance of Terms\n'
            'By using this application, you agree to be bound by these terms.\n\n'
            '2. Driver Responsibilities\n'
            'Drivers must provide safe, reliable, and timely delivery services.\n\n'
            '3. Payment Terms\n'
            'Payments will be processed according to our payment schedule and policies.\n\n'
            '4. Service Standards\n'
            'Maintain professional conduct and follow all traffic laws while delivering.\n\n'
            '5. Account Termination\n'
            'We reserve the right to terminate accounts for violations of these terms.',
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

  // Developer Settings Methods
  void _showProductionModeDialog(bool enabled) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enabled ? '🚀 Production Mode Enabled' : '🧪 Development Mode Enabled'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(enabled 
                ? 'AWS Cognito integration is now active. Registration data will be saved to AWS Cognito and DynamoDB.'
                : 'Registration will use mock data. No data will be saved to AWS services.'),
            const SizedBox(height: 16),
            Text('Backend URL: ${AppConfig.backendBaseUrl}'),
            Text('AWS Integration: ${AppConfig.enableAWSIntegration ? "Enabled" : "Disabled"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showConfigurationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Current Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Environment: ${AppConfig.environment}'),
            Text('Backend URL: ${AppConfig.backendBaseUrl}'),
            Text('Force Production: ${AppConfig.forceProductionMode}'),
            Text('Use Mock Data: ${AppConfig.useMockData}'),
            Text('AWS Integration: ${AppConfig.enableAWSIntegration ? "✅ Active" : "❌ Disabled"}'),
            const SizedBox(height: 16),
            const Text('AWS Configuration:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...AppConfig.awsConfig.entries.map((e) => Text('${e.key}: ${e.value}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppConfig.printConfig();
            },
            child: const Text('Print to Console'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _testRegistrationMode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧪 Test Registration Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Mode: ${AppConfig.enableAWSIntegration ? "AWS Integration" : "Mock Data"}'),
            const SizedBox(height: 16),
            Text(AppConfig.enableAWSIntegration 
                ? 'Registration will attempt to:\n• Create user in AWS Cognito\n• Save profile to DynamoDB\n• Send SMS verification'
                : 'Registration will:\n• Use mock responses\n• Not save real data\n• Return fake tokens'),
            const SizedBox(height: 16),
            const Text('To test registration:'),
            const Text('1. Go to registration screen'),
            const Text('2. Fill in the form'),
            const Text('3. Submit registration'),
            const Text('4. Check console logs for details'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
