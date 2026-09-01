import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final backgroundService = BackgroundService();
  await backgroundService.initialize();
  await backgroundService.registerPeriodicLimitsCheck();

  runApp(const ProviderScope(child: App()));
}
