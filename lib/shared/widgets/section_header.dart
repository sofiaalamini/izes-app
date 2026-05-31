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
        SizedBox(height: compact ? 0 : 2),
        Text(
          title,
          style: compact ? textTheme.titleLarge : textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(description, style: textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class AppSectionHeader extends SectionHeader {
  const AppSectionHeader({
    super.key,
    required super.eyebrow,
    required super.title,
    required super.description,
    super.compact = false,
  });
}
