import 'package:flutter/material.dart';

import '../../../../core/models/sensor_model.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/services/sensor_service.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/theme/izes_theme.dart';
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
  String? _selectedSensorId;
  List<SensorModel> _currentSensors = const <SensorModel>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _sensorsFuture = _sensorService.fetchSensors().then((sensors) {
      _currentSensors = sensors;
      if (sensors.isEmpty) {
        _selectedSensorId = null;
      } else if (_selectedSensorId == null ||
          !sensors.any((sensor) => sensor.id == _selectedSensorId)) {
        _selectedSensorId = sensors.first.id;
      }
      return sensors;
    });

    _weatherFuture = _sensorsFuture.then((sensors) {
      if (sensors.isEmpty) {
        throw const WeatherException(
          'Nenhum sensor disponivel para consultar o clima.',
        );
      }

      final selectedSensor =
          sensors.any((sensor) => sensor.id == _selectedSensorId)
          ? sensors.firstWhere((sensor) => sensor.id == _selectedSensorId)
          : sensors.first;
      _selectedSensorId = selectedSensor.id;
      return _weatherService.getWeatherBySensor(selectedSensor.id);
    });
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await Future.wait<dynamic>([_weatherFuture, _sensorsFuture]);
  }

  void _selectSensor(String sensorId) {
    if (_selectedSensorId == sensorId) {
      return;
    }
    setState(() {
      _selectedSensorId = sensorId;
      _weatherFuture = _weatherService.getWeatherBySensor(sensorId);
    });
  }

  String _weatherErrorMessage(Object? error) {
    if (error is WeatherException) {
      return error.message;
    }
    return 'O clima nao esta disponivel agora.';
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
            eyebrow: 'Clima e sensores',
            title: 'Leitura rapida do ambiente',
            description:
                'Clima do sensor selecionado e status mais recente dos sensores.',
            compact: true,
          ),
          const SizedBox(height: 14),
          FutureBuilder<WeatherModel>(
            future: _weatherFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _StateCard(
                  title: 'Clima atual',
                  message: 'Atualizando informacoes do sensor...',
                  loading: true,
                );
              }

              if (snapshot.hasError) {
                return _StateCard(
                  title: 'Clima atual',
                  message: _weatherErrorMessage(snapshot.error),
                  actionLabel: 'Tentar novamente',
                  onAction: () => setState(() {
                    final sensorId = _selectedSensorId;
                    if (sensorId == null) {
                      _weatherFuture = Future<WeatherModel>.error(
                        const WeatherException(
                          'Nenhum sensor disponivel para consultar o clima.',
                        ),
                      );
                    } else {
                      _weatherFuture = _weatherService.getWeatherBySensor(
                        sensorId,
                      );
                    }
                  }),
                );
              }

              final weather = snapshot.data;
              if (weather == null) {
                return const _StateCard(
                  title: 'Clima atual',
                  message: 'Sem atualizacao de clima no momento.',
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
                  message: 'Buscando as leituras mais recentes...',
                  loading: true,
                );
              }

              if (snapshot.hasError) {
                return _StateCard(
                  title: 'Sensores da propriedade',
                  message: 'Falha ao carregar sensores.',
                  actionLabel: 'Recarregar',
                  onAction: () => setState(_loadData),
                );
              }

              final sensors = snapshot.data ?? _currentSensors;
              if (sensors.isEmpty) {
                return const _StateCard(
                  title: 'Sensores da propriedade',
                  message: 'Nenhum sensor disponivel no momento.',
                );
              }

              return PropertySensorsCard(
                sensors: sensors,
                selectedSensorId: _selectedSensorId,
                onSensorSelected: _selectSensor,
              );
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (loading) ...[
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 10),
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
