import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/weather_model.dart';
import '../../../../core/theme/izes_theme.dart';
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
    final updatedAt = DateFormat('dd/MM HH:mm').format(weather.fetchedAt);

    return AppSurfaceCard(
      backgroundColor: IzesColors.greenSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CLIMA EM TEMPO REAL', style: theme.labelMedium),
          const SizedBox(height: 10),
          Text(subtitle, style: theme.titleLarge),
          const SizedBox(height: 4),
          Text(
            weather.condition,
            style: theme.bodyLarge?.copyWith(color: IzesColors.green),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _WeatherFact(
                label: 'Temperatura',
                value: '${weather.temperatureC.toStringAsFixed(1)} C',
              ),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: IzesColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: IzesColors.line),
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
          const SizedBox(height: 12),
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
      width: width.clamp(120.0, 220.0).toDouble(),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: IzesColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: IzesColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
