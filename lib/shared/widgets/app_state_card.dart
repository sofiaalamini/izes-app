import 'package:flutter/material.dart';

import '../../core/theme/izes_theme.dart';
import 'app_surface_card.dart';

enum AppStateTone { neutral, warning }

class AppStateCard extends StatelessWidget {
  const AppStateCard({
    super.key,
    required this.title,
    required this.message,
    this.eyebrow,
    this.supportingText,
    this.loading = false,
    this.actionLabel,
    this.onAction,
    this.tone = AppStateTone.neutral,
  });

  final String title;
  final String message;
  final String? eyebrow;
  final String? supportingText;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppStateTone tone;

  @override
  Widget build(BuildContext context) {
    final isWarning = tone == AppStateTone.warning;
    final accent = isWarning ? IzesColors.urgent : IzesColors.green;
    final soft = isWarning ? IzesColors.urgentSoft : IzesColors.surfaceSoft;
    final theme = Theme.of(context).textTheme;

    return AppSurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: IzesColors.line),
              ),
              child: Text(
                eyebrow!,
                style: theme.labelMedium?.copyWith(color: accent),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(title, style: theme.titleLarge),
          const SizedBox(height: 8),
          if (loading) ...[
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            message,
            style: theme.bodyLarge?.copyWith(color: IzesColors.ink),
          ),
          if (supportingText != null) ...[
            const SizedBox(height: 6),
            Text(
              supportingText!,
              style: theme.bodyMedium?.copyWith(color: IzesColors.muted),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
