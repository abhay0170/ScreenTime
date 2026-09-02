import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/providers.dart';

/// A themed "nothing here yet" state: icon, title, body copy, and an
/// optional action button. Used for every screen's empty-data case so they
/// share one look instead of each hand-rolling its own.
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// A retry-able error state for a failed async load. Checks Usage Access
/// permission (which can be revoked from system settings at any time) and,
/// if that's the cause, routes toward re-granting it instead of showing a
/// generic message the user can't act on.
///
/// [permissionAware] should be false for data that doesn't depend on
/// usage_stats (e.g. package info), so a permission check isn't watched
/// (and thus never touches the plugin) where it wouldn't be the cause.
class AsyncErrorView extends ConsumerWidget {
  final VoidCallback onRetry;
  final bool compact;
  final bool permissionAware;

  const AsyncErrorView({
    super.key,
    required this.onRetry,
    this.compact = false,
    this.permissionAware = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissionGranted = permissionAware
        ? ref.watch(usageAccessStatusProvider).valueOrNull
        : true;

    if (permissionGranted == false) {
      return _StateBody(
        compact: compact,
        icon: Icons.lock_outline_rounded,
        iconColor: theme.colorScheme.error,
        title: 'Usage Access was turned off',
        body:
            "ScreenTime can't read app usage until Usage Access is granted "
            'again in system settings.',
        button: FilledButton(
          onPressed: () => context.go('/onboarding'),
          child: const Text('Re-grant access'),
        ),
      );
    }

    return _StateBody(
      compact: compact,
      icon: Icons.error_outline_rounded,
      iconColor: theme.colorScheme.error,
      title: 'Something went wrong',
      body: "We couldn't load this. Please try again.",
      button: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Retry'),
      ),
    );
  }
}

class _StateBody extends StatelessWidget {
  final bool compact;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget button;

  const _StateBody({
    required this.compact,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 16 : 48,
        horizontal: compact ? 0 : 24,
      ),
      child: Column(
        children: [
          Icon(icon, size: compact ? 28 : 48, color: iconColor),
          SizedBox(height: compact ? 8 : 16),
          Text(
            title,
            style: compact
                ? theme.textTheme.titleSmall
                : theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 12 : 16),
          button,
        ],
      ),
    );
  }
}

/// A pulsing placeholder box for content that's still loading — used
/// instead of leaving a section blank or showing a bare zero while its
/// provider resolves.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.35,
    end: 0.85,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, child) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withValues(alpha: _opacity.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
