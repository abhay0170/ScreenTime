import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/themes.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Keeps limit feedback responsive when returning to the app, rather
      // than waiting on the ~15 minute background check.
      ref.read(limitsRepositoryProvider).checkAndNotifyThresholds();
    }
  }

  @override
  Widget build(BuildContext context) {
    final variant = ref.watch(themeProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'ScreenTime',
      debugShowCheckedModeBanner: false,
      theme: themeForVariant(variant),
      routerConfig: router,
    );
  }
}
