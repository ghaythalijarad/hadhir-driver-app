import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

import '../../features/authentication/demand_map_screen.dart';
import '../../features/authentication/screens/new_driver_signup_screen.dart';
import '../../features/authentication/screens/new_email_verification_screen.dart';
import '../../features/authentication/screens/new_login_screen.dart';
import '../../features/authentication/screens/new_phone_verification_screen.dart';
import '../../features/authentication/screens/new_forgot_password_screen.dart';
import '../../features/authentication/screens/registration_debug_screen.dart';
import '../../features/navigation/navigation_page.dart';
import '../../features/splash/splash_page.dart';
import '../../debug/config_debug_screen.dart';
import '../../debug/email_verification_test_screen.dart';
import '../../debug/comprehensive_email_test.dart';
import '../../debug/sso_email_test_screen.dart';
import '../../main.dart' show DriverHomePage;
import '../../models/order_model.dart';
import 'services_provider.dart';

part 'router_provider.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Use the auth service to check authentication status
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuthenticated = authService.isAuthenticated;

      final isAuthRoute =
          state.uri.path.startsWith('/login') ||
          state.uri.path.startsWith('/register') ||
          state.uri.path.startsWith('/forgot-password') ||
          state.uri.path.startsWith('/verify-phone') ||
          state.uri.path.startsWith('/email-verification');

      final isDebugRoute = 
          state.uri.path.startsWith('/config-debug') ||
          state.uri.path.startsWith('/email-test') ||
          state.uri.path.startsWith('/comprehensive-email-test') ||
          state.uri.path.startsWith('/sso-email-test') ||
          state.uri.path.startsWith('/registration-debug');

      debugPrint(
        '🔀 Router redirect: path=${state.uri.path}, isAuthenticated=$isAuthenticated, isAuthRoute=$isAuthRoute, isDebugRoute=$isDebugRoute',
      );

      // If user is authenticated and trying to access auth routes, redirect to home
      if (isAuthenticated && isAuthRoute) {
        debugPrint('🔀 Redirecting to home (authenticated on auth route)');
        return '/';
      }

      // If user is not authenticated and not on auth/debug route, redirect to login
      if (!isAuthenticated && !isAuthRoute && !isDebugRoute) {
        debugPrint('🔀 Redirecting to login (not authenticated, not debug)');
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const NewLoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const NewDriverSignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const NewForgotPasswordScreen(),
      ),
      // Legacy path support: redirect old '/driver-signup' to new unified '/register'
      GoRoute(
        path: '/driver-signup',
        redirect: (context, state) => '/register',
      ),
      GoRoute(
        path: '/registration-debug',
        builder: (context, state) => const RegistrationDebugScreen(),
      ),
      GoRoute(
        path: '/config-debug',
        builder: (context, state) => const ConfigDebugScreen(),
      ),
      GoRoute(
        path: '/email-test',
        builder: (context, state) => const EmailVerificationTestScreen(),
      ),
      GoRoute(
        path: '/comprehensive-email-test',
        builder: (context, state) => const ComprehensiveEmailTestScreen(),
      ),
      GoRoute(
        path: '/sso-email-test',
        builder: (context, state) => const SSOEmailTestScreen(),
      ),
      GoRoute(
        path: '/verify-phone',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final phone = extra?['phone'] as String? ?? '';
          return NewPhoneVerificationScreen(phoneNumber: phone);
        },
      ),
      // Email verification route
      GoRoute(
        path: '/email-verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] as String? ?? '';
          final delivery = extra?['delivery'] as String?;
          final username =
              extra?['username'] as String? ??
              email; // Fallback to email for safety
          return NewEmailVerificationScreen(
            username: username,
            email: email,
            delivery: delivery,
          );
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final tabParam = state.uri.queryParameters['tab'];
          int initialTab = 0;
          if (tabParam != null) {
            initialTab = int.tryParse(tabParam) ?? 0;
            initialTab = initialTab.clamp(0, 3);
          }

          return DriverHomePage(
            selectedZone: state.uri.queryParameters['zone'],
            shouldStartDash: state.uri.queryParameters['startDash'] == 'true',
            initialTabIndex: initialTab,
          );
        },
      ),
      GoRoute(
        path: '/demand-map',
        builder: (context, state) => const DemandMapScreen(),
      ),
      GoRoute(
        path: '/navigation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final order = extra?['order'] as OrderModel?;
          if (order == null) {
            return const NewLoginScreen();
          }
          return NavigationPage(
            order: order,
            onNavigationComplete: () {
              context.go('/');
            },
            onNavigationCancelled: () {
              context.go('/');
            },
          );
        },
      ),
    ],
  );
}
