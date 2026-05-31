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

    return AppSurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      backgroundColor: IzesColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clima atual', style: theme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.bodyMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: IzesColors.greenSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${weather.temperatureC.toStringAsFixed(1)} C',
                  style: theme.titleLarge?.copyWith(color: IzesColors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            weather.condition,
            style: theme.bodyLarge?.copyWith(color: IzesColors.ink),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WeatherFact(
                label: 'Sensacao',
                value: '${weather.feelsLikeC.toStringAsFixed(1)} C',
              ),
              _WeatherFact(label: 'Umidade', value: '${weather.humidity}%'),
              _WeatherFact(
                label: 'Chuva',
                value:
                    '${weather.chanceOfRain}% / ${weather.precipitationMm.toStringAsFixed(1)} mm',
              ),
              _WeatherFact(
                label: 'Vento',
                value: '${weather.windKph.toStringAsFixed(1)} km/h',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: IzesColors.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recomendacao agricola', style: theme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  weather.agriculturalRecommendation,
                  style: theme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Atualizado em $updatedAt', style: theme.bodyMedium),
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
    final width = (MediaQuery.sizeOf(context).width - 56) / 2;
    return Container(
      width: width.clamp(110.0, 180.0).toDouble(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: IzesColors.greenSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: IzesColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
