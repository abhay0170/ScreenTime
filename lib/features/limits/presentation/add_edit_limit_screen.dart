import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../domain/models/app_usage_info.dart';
import '../../../domain/models/time_limit.dart';

/// Add mode when [packageName] is null (with an optional [initialPackageName]
/// pre-selection, e.g. from the Limits screen's "Other apps" quick action).
/// Edit mode when [packageName] is set.
class AddEditLimitScreen extends ConsumerStatefulWidget {
  final String? packageName;
  final String? initialPackageName;

  const AddEditLimitScreen({
    super.key,
    this.packageName,
    this.initialPackageName,
  });

  bool get isEditMode => packageName != null;

  @override
  ConsumerState<AddEditLimitScreen> createState() => _AddEditLimitScreenState();
}

class _AddEditLimitScreenState extends ConsumerState<AddEditLimitScreen> {
  String? _selectedPackageName;
  String _selectedAppName = '';
  int _hours = 1;
  int _minutes = 0;
  bool _notifyAt80 = true;
  bool _notifyAt100 = true;
  bool _loading = true;
  bool _saving = false;
  TimeLimit? _existingLimit;

  @override
  void initState() {
    super.initState();
    _selectedPackageName = widget.packageName ?? widget.initialPackageName;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final packageName = _selectedPackageName;
    if (packageName == null) {
      setState(() => _loading = false);
      return;
    }

    if (widget.isEditMode) {
      final limit = await ref
          .read(limitsRepositoryProvider)
          .getLimitForPackage(packageName);
      if (limit != null) {
        _existingLimit = limit;
        _hours = limit.dailyLimitMinutes ~/ 60;
        _minutes = limit.dailyLimitMinutes % 60;
        _notifyAt80 = limit.notifyAt80;
        _notifyAt100 = limit.notifyAt100;
      }
    }

    final appInfo = await ref
        .read(appInfoResolverProvider)
        .resolve(packageName);
    _selectedAppName = appInfo?.name ?? packageName;

    if (mounted) setState(() => _loading = false);
  }

  void _selectApp(AppUsageInfo app) {
    setState(() {
      _selectedPackageName = app.packageName;
      _selectedAppName = app.appName;
    });
  }

  Future<void> _save() async {
    final packageName = _selectedPackageName;
    if (packageName == null || (_hours == 0 && _minutes == 0)) return;

    setState(() => _saving = true);
    final now = DateTime.now();

    await ref
        .read(limitsRepositoryProvider)
        .upsertLimit(
          TimeLimit(
            packageName: packageName,
            dailyLimitMinutes: _hours * 60 + _minutes,
            notifyAt80: _notifyAt80,
            notifyAt100: _notifyAt100,
            createdAt: _existingLimit?.createdAt ?? now,
            updatedAt: now,
          ),
        );

    ref.invalidate(allLimitsProvider);
    ref.invalidate(limitsWithUsageProvider);
    ref.invalidate(unlimitedTrackedAppsProvider);

    if (mounted) context.pop();
  }

  Future<void> _remove() async {
    final packageName = widget.packageName;
    if (packageName == null) return;

    await ref.read(limitsRepositoryProvider).deleteLimit(packageName);

    ref.invalidate(allLimitsProvider);
    ref.invalidate(limitsWithUsageProvider);
    ref.invalidate(unlimitedTrackedAppsProvider);

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final canSave =
        _selectedPackageName != null && (_hours > 0 || _minutes > 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit limit' : 'Add limit'),
        actions: [
          if (widget.isEditMode)
            IconButton(
              tooltip: 'Remove limit',
              icon: const Icon(Icons.delete_outline),
              onPressed: _remove,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_selectedPackageName == null)
            _AppPicker(onSelected: _selectApp)
          else ...[
            _SelectedAppHeader(
              name: _selectedAppName,
              onChange: widget.isEditMode
                  ? null
                  : () => setState(() {
                      _selectedPackageName = null;
                      _selectedAppName = '';
                    }),
            ),
            const SizedBox(height: 24),
            Text('Daily limit', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _DurationPicker(
              hours: _hours,
              minutes: _minutes,
              onChanged: (hours, minutes) {
                setState(() {
                  _hours = hours;
                  _minutes = minutes;
                });
              },
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notify at 80%'),
              value: _notifyAt80,
              onChanged: (value) => setState(() => _notifyAt80 = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Notify at 100%'),
              value: _notifyAt100,
              onChanged: (value) => setState(() => _notifyAt100 = value),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving || !canSave ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedAppHeader extends StatelessWidget {
  final String name;
  final VoidCallback? onChange;

  const _SelectedAppHeader({required this.name, this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(name, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (onChange != null)
          TextButton(onPressed: onChange, child: const Text('Change')),
      ],
    );
  }
}

class _AppPicker extends ConsumerWidget {
  final ValueChanged<AppUsageInfo> onSelected;

  const _AppPicker({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(unlimitedTrackedAppsProvider);
    final theme = Theme.of(context);

    return appsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text('Failed to load apps: $error'),
      data: (apps) {
        if (apps.isEmpty) {
          return Text(
            "All the apps you've used today already have a limit.",
            style: theme.textTheme.bodyMedium,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose an app', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final app in apps)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AppIcon(bytes: app.iconBytes),
                title: Text(app.appName),
                subtitle: Text('${formatDuration(app.totalTime)} today'),
                onTap: () => onSelected(app),
              ),
          ],
        );
      },
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final int hours;
  final int minutes;
  final void Function(int hours, int minutes) onChanged;

  const _DurationPicker({
    required this.hours,
    required this.minutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Stepper(
            label: 'Hours',
            value: hours,
            max: 23,
            onChanged: (value) => onChanged(value, minutes),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _Stepper(
            label: 'Minutes',
            value: minutes,
            max: 55,
            step: 5,
            onChanged: (value) => onChanged(hours, value),
          ),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.label,
    required this.value,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value <= 0
                  ? null
                  : () => onChanged((value - step).clamp(0, max)),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value >= max
                  ? null
                  : () => onChanged((value + step).clamp(0, max)),
            ),
          ],
        ),
      ],
    );
  }
}
