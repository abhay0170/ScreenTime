import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme_provider.dart';
import 'core/theme/themes.dart';
import 'features/today/presentation/screens/theme_preview_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(themeProvider);

    return MaterialApp(
      title: 'ScreenTime',
      debugShowCheckedModeBanner: false,
      theme: themeForVariant(variant),
      home: const ThemePreviewScreen(),
    );
  }
}
