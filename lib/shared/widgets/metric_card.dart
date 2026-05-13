import 'package:flutter/material.dart';

import '../../core/theme/izes_theme.dart';
import 'app_surface_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    this.tint,
  });

  final String label;
  final String value;
  final String note;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return AppSurfaceCard(
      backgroundColor: tint ?? IzesColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: theme.labelMedium),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(note, style: theme.bodyMedium),
        ],
      ),
    );
  }
}
