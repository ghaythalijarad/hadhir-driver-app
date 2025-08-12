import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:provider/provider.dart' as provider;
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import 'app_colors.dart';
import 'config/app_config.dart';
import 'core/app_controller.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart' as legacy_auth;
import 'providers/riverpod/router_provider.dart';
import 'amplifyconfiguration.dart';
import 'services/demand_analysis_service.dart';
import 'services/location_service.dart';
import 'services/mapbox_navigation_service.dart';
import 'services/order_notification_service.dart';
import 'services/order_service.dart';
import 'services/realtime_communication_service.dart';
import 'features/home/enhanced_home_tab_clean.dart';
import 'features/orders/orders_tab.dart';
import 'features/earnings/earnings_tab.dart';
import 'features/more/more_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app configuration with AWS Cognito integration
  await AppConfig.initialize();
  await AppConfig.setAWSIntegration(true); // Enable AWS Cognito
  await AppConfig.setForceProductionMode(false); // Development mode
  AppConfig.printConfig();

  // Initialize Amplify
  await _configureAmplify();

  // Run app
  runApp(const riverpod.ProviderScope(child: MyApp()));
}

Future<void> _configureAmplify() async {
  try {
    if (Amplify.isConfigured) {
      safePrint('Amplify already configured');
      return;
    }

    // Add Cognito Auth plugin
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugin(auth);

    // Configure Amplify with amplify configuration
    await Amplify.configure(amplifyconfig);

    safePrint('Successfully configured Amplify');
  } on Exception catch (e) {
    safePrint('An error occurred configuring Amplify: $e');
  }
}

class LocaleProvider extends riverpod.StateNotifier<Locale> {
  LocaleProvider() : super(const Locale('ar'));

  void setLocale(Locale locale) {
    if (state == locale) return;
    state = locale;
  }
}

final localeProvider = riverpod.StateNotifierProvider<LocaleProvider, Locale>((
  ref,
) {
  return LocaleProvider();
});

class MyApp extends riverpod.ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentLocale = ref.watch(localeProvider);

    // This MultiProvider is for legacy providers. We should migrate these to Riverpod.
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(
          create: (_) => legacy_auth.AuthProvider(),
        ),
        provider.ChangeNotifierProvider(create: (_) => LocationService()),
        provider.ChangeNotifierProvider(create: (_) => OrderService()),
        provider.ChangeNotifierProvider(
          create: (_) => OrderNotificationService(),
        ),
        provider.ChangeNotifierProvider(create: (_) => AppController()),
        provider.ChangeNotifierProvider(create: (_) => DemandAnalysisService()),
        provider.ChangeNotifierProvider(
          create: (_) => MapboxNavigationService(),
        ),
        provider.ChangeNotifierProvider(
          create: (_) => RealtimeCommunicationService(),
        ),
      ],
      child: MaterialApp.router(
        title: 'سائق حاضر',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.accent,
            surface: AppColors.surface,
          ),
          fontFamily: 'Tajawal',
          useMaterial3: true,
        ),
        routerConfig: router,
        locale: currentLocale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: currentLocale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        ),
      ),
    );
  }
}

class DriverHomePage extends StatefulWidget {
  final String? selectedZone;
  final bool shouldStartDash;
  final int initialTabIndex;

  const DriverHomePage({
    super.key,
    this.selectedZone,
    this.shouldStartDash = false,
    this.initialTabIndex = 0,
  });

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppController();
    });
  }

  Future<void> _initializeAppController() async {
    final appController = provider.Provider.of<AppController>(
      context,
      listen: false,
    );
    await appController.initialize(context);

    if (widget.shouldStartDash && widget.selectedZone != null) {
      await appController.startShift(selectedZone: widget.selectedZone);
    }
  }

  Widget _getTabContent(int index) {
    return provider.Consumer<AppController>(
      builder: (context, appController, child) {
        if (!appController.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        switch (index) {
          case 0:
            return const EnhancedHomeTabClean();
          case 1:
            return const OrdersTab();
          case 2:
            return const EarningsTab();
          case 3:
            return MoreTab(
              isDashing: appController.isOnline,
              onDashStatusChanged: (status) {},
            );
          default:
            return Container();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getTabContent(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey500,
          backgroundColor: AppColors.white,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.attach_money_outlined),
              activeIcon: Icon(Icons.attach_money),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_outlined),
              activeIcon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
