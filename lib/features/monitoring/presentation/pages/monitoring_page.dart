import 'package:flutter/material.dart';

import '../../../../core/models/sensor_model.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/services/sensor_service.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/property_sensors_card.dart';
import '../widgets/weather_card.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  final WeatherService _weatherService = WeatherService();
  final SensorService _sensorService = SensorService();

  late Future<WeatherModel> _weatherFuture;
  late Future<List<SensorModel>> _sensorsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _weatherFuture = _weatherService.fetchCurrentWeather();
    _sensorsFuture = _sensorService.fetchSensors();
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await Future.wait<dynamic>([_weatherFuture, _sensorsFuture]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: IzesColors.green,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            eyebrow: 'Monitoramento ambiental',
            title: 'Clima e sensores com leitura pronta para decisao.',
            description:
                'Acompanhe o clima em tempo real e o status operacional da propriedade.',
          ),
          const SizedBox(height: 16),
          FutureBuilder<WeatherModel>(
            future: _weatherFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _StateCard(
                  title: 'Clima em tempo real',
                  message: 'Buscando clima atual no backend...',
                  loading: true,
                );
              }

              if (snapshot.hasError) {
                return _StateCard(
                  title: 'Clima em tempo real',
                  message: '${snapshot.error}',
                  actionLabel: 'Tentar novamente',
                  onAction: () => setState(() {
                    _weatherFuture = _weatherService.fetchCurrentWeather();
                  }),
                );
              }

              final weather = snapshot.data;
              if (weather == null) {
                return const _StateCard(
                  title: 'Clima em tempo real',
                  message: 'Nenhum dado de clima disponivel no momento.',
                );
              }

              return WeatherCard(weather: weather);
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<SensorModel>>(
            future: _sensorsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _StateCard(
                  title: 'Sensores da propriedade',
                  message: 'Carregando leituras reais dos sensores...',
                  loading: true,
                );
              }

              if (snapshot.hasError) {
                return _StateCard(
                  title: 'Sensores da propriedade',
                  message: 'Falha ao carregar sensores.',
                  actionLabel: 'Recarregar',
                  onAction: () => setState(() {
                    _sensorsFuture = _sensorService.fetchSensors();
                  }),
                );
              }

              final sensors = snapshot.data ?? const <SensorModel>[];
              if (sensors.isEmpty) {
                return const _StateCard(
                  title: 'Sensores da propriedade',
                  message: 'Nenhuma leitura disponivel no momento.',
                );
              }

              return PropertySensorsCard(sensors: sensors);
            },
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.title,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (loading) ...[
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 12),
          ],
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
