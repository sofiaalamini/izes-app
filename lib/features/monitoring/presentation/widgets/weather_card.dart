import 'package:flutter/material.dart';

import '../../../../core/models/weather_model.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../core/utils/date_time_formatter.dart';
import '../../../../shared/widgets/app_surface_card.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final subtitle = weather.region.isEmpty
        ? weather.city
        : '${weather.city}, ${weather.region}';
    final updatedAt = DateTimeFormatter.shortDateTime(weather.fetchedAt);
    final message = weather.agriculturalRecommendation.isEmpty
        ? 'Sem recomendacao adicional no momento.'
        : weather.agriculturalRecommendation;

    return AppSurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(18),
      backgroundColor: IzesColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.titleLarge,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              Text(
                '${weather.temperatureC.toStringAsFixed(1)}°C',
                style: theme.headlineMedium?.copyWith(
                  color: IzesColors.greenDark,
                  fontSize: 34,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  weather.condition,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleMedium?.copyWith(color: IzesColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _WeatherFact(
                  label: 'Umidade',
                  value: '${weather.humidity}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WeatherFact(
                  label: 'Vento',
                  value: '${weather.windKph.toStringAsFixed(1)} km/h',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: IzesColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              message,
              style: theme.bodyLarge?.copyWith(color: IzesColors.ink),
            ),
          ),
          const SizedBox(height: 10),
          Text('Atualizado em $updatedAt', style: theme.bodySmall),
        ],
      ),
    );
  }
}

class _WeatherFact extends StatelessWidget {
  const _WeatherFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: IzesColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IzesColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: IzesColors.ink),
          ),
        ],
      ),
    );
  }
}
