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
    this.accentColor,
    this.icon,
  });

  final String label;
  final String value;
  final String note;
  final Color? tint;
  final Color? accentColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: tint ?? IzesColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelMedium,
                ),
              ),
              if (icon != null)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  height: 26,
                  width: 26,
                  decoration: BoxDecoration(
                    color: (accentColor ?? IzesColors.green).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: accentColor ?? IzesColors.green),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.headlineMedium?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: accentColor ?? IzesColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.bodySmall,
          ),
        ],
      ),
    );
  }
}
