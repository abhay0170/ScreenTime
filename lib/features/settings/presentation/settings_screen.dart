import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/settings/notification_preference_provider.dart';
import '../../../core/theme/app_theme_style.dart';
import '../../../core/theme/app_theme_variant.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/themes.dart';
import '../../../core/widgets/status_badge.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
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
      // Usage Access / notification permission can change from system
      // settings while this screen is backgrounded — re-check on return.
      ref.invalidate(usageAccessStatusProvider);
      ref.invalidate(notificationPermissionEnabledProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _AppearanceSection(),
          SizedBox(height: 16),
          _NotificationsSection(),
          SizedBox(height: 16),
          _PermissionsSection(),
          SizedBox(height: 16),
          _AboutSection(),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<AppThemeStyle>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(style.cardRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeProvider);

    return _SettingsSection(
      title: 'Appearance',
      children: [
        Row(
          children: [
            for (final variant in AppThemeVariant.values) ...[
              if (variant != AppThemeVariant.values.first)
                const SizedBox(width: 12),
              Expanded(
                child: _ThemeCard(
                  variant: variant,
                  selected: variant == current,
                  onTap: () =>
                      ref.read(themeProvider.notifier).setVariant(variant),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeVariant variant;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outerTheme = Theme.of(context);
    final style = themeForVariant(variant).extension<AppThemeStyle>()!;
    final previewTextColor = style.heroGradient != null
        ? Colors.white
        : (style.heroBackground.computeLuminance() > 0.5
              ? style.colorScheme.onSurface
              : Colors.white);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? outerTheme.colorScheme.primary
                : outerTheme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.4,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: style.heroGradient,
                  color: style.heroGradient == null
                      ? style.heroBackground
                      : null,
                  borderRadius: BorderRadius.circular(style.cardRadius / 2),
                ),
                child: Text(
                  'Aa',
                  style: TextStyle(
                    fontFamily: style.displayFontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: previewTextColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _labelFor(variant),
              style: outerTheme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Icon(
              Icons.check_circle,
              size: 16,
              color: selected
                  ? outerTheme.colorScheme.primary
                  : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  static String _labelFor(AppThemeVariant variant) {
    switch (variant) {
      case AppThemeVariant.materialFlow:
        return 'Material Flow';
      case AppThemeVariant.nightFocus:
        return 'Night Focus';
      case AppThemeVariant.calmBalance:
        return 'Calm Balance';
    }
  }
}

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationPreferenceProvider);
    final osEnabledAsync = ref.watch(notificationPermissionEnabledProvider);

    return _SettingsSection(
      title: 'Notifications',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Limit threshold alerts'),
          subtitle: const Text('Notify me at 80% and 100% of a daily limit'),
          value: enabled,
          onChanged: (value) => ref
              .read(notificationPreferenceProvider.notifier)
              .setEnabled(value),
        ),
        osEnabledAsync.when(
          data: (osEnabled) => osEnabled
              ? const SizedBox.shrink()
              : _WarningRow(
                  message:
                      'Notifications are turned off for ScreenTime in '
                      'system settings.',
                  actionLabel: 'Open settings',
                  onTap: () => ref
                      .read(notificationServiceProvider)
                      .openAppNotificationSettings(),
                ),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => _WarningRow(
            message: "Couldn't check notification permission status.",
            actionLabel: 'Retry',
            onTap: () => ref.invalidate(notificationPermissionEnabledProvider),
          ),
        ),
      ],
    );
  }
}

class _PermissionsSection extends ConsumerWidget {
  const _PermissionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(usageAccessStatusProvider);
    final theme = Theme.of(context);

    return _SettingsSection(
      title: 'Permissions',
      children: [
        permissionAsync.when(
          data: (granted) => _PermissionStatusRow(
            granted: granted,
            onRegrant: () =>
                ref.read(usageStatsServiceProvider).requestPermission(),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, stackTrace) => Text(
            'Failed to check permission: $error',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _PermissionStatusRow extends StatelessWidget {
  final bool granted;
  final VoidCallback onRegrant;

  const _PermissionStatusRow({required this.granted, required this.onRegrant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle : Icons.error_outline,
          color: granted ? Colors.green.shade600 : theme.colorScheme.error,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usage Access', style: theme.textTheme.titleSmall),
              Text(
                granted ? 'Granted' : 'Not granted',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (!granted)
          TextButton(onPressed: onRegrant, child: const Text('Re-grant')),
      ],
    );
  }
}

class _WarningRow extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  const _WarningRow({
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onTap, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final theme = Theme.of(context);

    return _SettingsSection(
      title: 'About',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Version'),
          subtitle: packageInfoAsync.when(
            data: (info) => Text('${info.version} (${info.buildNumber})'),
            loading: () => const Text('…'),
            error: (error, stackTrace) => const Text('Unknown'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your usage data stays on this device and is never sent anywhere.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: 0.6,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Goals & Streaks'),
            trailing: StatusBadge(
              label: 'COMING SOON',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
