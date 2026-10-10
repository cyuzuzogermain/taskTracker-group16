import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A stand-in for a screen that has not been built yet.
///
/// It lets the navigation work end to end while the real screens are
/// still in progress. Each one is swapped out as its screen is merged.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This screen is coming soon.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
