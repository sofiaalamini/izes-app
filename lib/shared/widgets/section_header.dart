import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: textTheme.labelMedium),
        const SizedBox(height: 6),
        Text(title, style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(description, style: textTheme.bodyMedium),
      ],
    );
  }
}
