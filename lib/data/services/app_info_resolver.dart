import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

/// Resolves a package name to its installed [AppInfo] (display name, icon,
/// system-app flag, ...).
///
/// Uses `installed_apps` (actively maintained — latest release February
/// 2026) rather than `device_apps`, whose last release predates current
/// Flutter/Android tooling by several years. `getAppInfo` looks up a single
/// known package, so unlike `getInstalledApps` it doesn't require the
/// broad, Play-Store-review-triggering QUERY_ALL_PACKAGES permission.
class AppInfoResolver {
  Future<AppInfo?> resolve(String packageName) {
    return InstalledApps.getAppInfo(packageName);
  }
}
