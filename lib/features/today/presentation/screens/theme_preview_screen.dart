import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_style.dart';
import '../../../../core/theme/app_theme_variant.dart';
import '../../../../core/theme/theme_provider.dart';

/// Temporary screen to verify the theme system. Replaced by the real
/// Today screen in a later step.
class ThemePreviewScreen extends ConsumerWidget {
  const ThemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final style = theme.extension<AppThemeStyle>()!;
    final currentVariant = ref.watch(themeProvider);

    final Color heroTextColor;
    if (style.heroGradient != null) {
      heroTextColor = Colors.white;
    } else {
      heroTextColor = style.heroBackground.computeLuminance() > 0.5
          ? style.colorScheme.onSurface
          : Colors.white;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ScreenTime',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontFamily: style.displayFontFamily,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(style.cardRadius),
                  gradient: style.heroGradient,
                  color: style.heroGradient == null
                      ? style.heroBackground
                      : null,
                ),
                child: Text(
                  'Hero card style: ${style.heroCardStyle.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: heroTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Switch theme', style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ThemeChip(
                    label: 'Material Flow',
                    selected: currentVariant == AppThemeVariant.materialFlow,
                    onTap: () => ref
                        .read(themeProvider.notifier)
                        .setVariant(AppThemeVariant.materialFlow),
                  ),
                  _ThemeChip(
                    label: 'Night Focus',
                    selected: currentVariant == AppThemeVariant.nightFocus,
                    onTap: () => ref
                        .read(themeProvider.notifier)
                        .setVariant(AppThemeVariant.nightFocus),
                  ),
                  _ThemeChip(
                    label: 'Calm Balance',
                    selected: currentVariant == AppThemeVariant.calmBalance,
                    onTap: () => ref
                        .read(themeProvider.notifier)
                        .setVariant(AppThemeVariant.calmBalance),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
