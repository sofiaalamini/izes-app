import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String description;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE7D8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(eyebrow, style: textTheme.labelMedium),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(title, style: compact ? textTheme.titleLarge : textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(description, style: textTheme.bodyMedium),
      ],
    );
  }
}
