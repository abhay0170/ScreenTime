import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/app_detail/presentation/app_detail_screen.dart';
import '../../features/limits/presentation/add_edit_limit_screen.dart';
import '../../features/limits/presentation/limits_screen.dart';
import '../../features/onboarding/presentation/onboarding_permission_screen.dart';
import '../../features/today/presentation/screens/today_screen.dart';
import '../../features/trends/presentation/trends_screen.dart';
import '../../features/widgets/presentation/widget_config_screen.dart';
import '../../features/widgets/presentation/widgets_screen.dart';
import '../di/providers.dart';
import 'themed_bottom_nav_bar.dart';

/// The 4-tab shell's branches, in the order they appear in the bottom nav.
const _tabPaths = ['/today', '/trends', '/limits', '/widgets'];

final goRouterProvider = Provider<GoRouter>((ref) {
  final usageStatsService = ref.watch(usageStatsServiceProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) async {
      final granted = await usageStatsService.checkPermission();
      final atOnboarding = state.matchedLocation == '/onboarding';

      if (!granted) return atOnboarding ? null : '/onboarding';
      if (atOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPermissionScreen(),
      ),
      // Pushed modally on top of the shell (no bottom nav), rather than
      // nested under the /limits branch.
      GoRoute(
        path: '/limits/add',
        builder: (context, state) =>
            AddEditLimitScreen(initialPackageName: state.extra as String?),
      ),
      GoRoute(
        path: '/limits/edit/:packageName',
        builder: (context, state) => AddEditLimitScreen(
          packageName: state.pathParameters['packageName']!,
        ),
      ),
      GoRoute(
        path: '/app-detail/:packageName',
        builder: (context, state) =>
            AppDetailScreen(packageName: state.pathParameters['packageName']!),
      ),
      // The initial route for the fresh engine BaseWidgetConfigActivity
      // spawns when the user adds a configurable widget — go_router
      // honors the platform's initial route over `initialLocation` above
      // whenever it isn't "/", so this is reached directly on launch.
      GoRoute(
        path: '/widget-config',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? modeAppUsage;
          final appWidgetId =
              int.tryParse(state.uri.queryParameters['appWidgetId'] ?? '') ?? 0;
          return WidgetConfigScreen(mode: mode, appWidgetId: appWidgetId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: ThemedBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _tabPaths[0],
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _tabPaths[1],
                builder: (context, state) => const TrendsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _tabPaths[2],
                builder: (context, state) => const LimitsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: _tabPaths[3],
                builder: (context, state) => const WidgetsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
