import 'package:flutter/material.dart';

import '../../../../core/models/sensor_model.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sensor_service.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_state_card.dart';
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

  bool _isSessionExpiredMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('401') ||
        normalized.contains('unauthorized') ||
        normalized.contains('token') ||
        normalized.contains('sessao') ||
        normalized.contains('session');
  }

  void _handleSessionExpired() {
    AuthService().logout();
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
            title: 'Clima e leituras de campo',
            description:
                'Veja a condicao externa e o que exige atencao no campo sem misturar contexto climatico com leitura de sensor.',
            compact: true,
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            eyebrow: 'Condicao externa',
            title: 'Clima atual da area monitorada',
            description:
                'Base para decidir irrigacao, aplicacao e monitoramento nas proximas horas.',
            compact: true,
          ),
          const SizedBox(height: 12),
          FutureBuilder<WeatherModel>(
            future: _weatherFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _StateCard(
                  title: 'Clima atual',
                  message: 'Atualizando as condicoes mais recentes da area.',
                  supportingText: 'Isso leva apenas alguns instantes.',
                  loading: true,
                );
              }

              if (snapshot.hasError) {
                final message = _weatherErrorMessage(snapshot.error);
                final expiredSession = _isSessionExpiredMessage(message);
                return _StateCard(
                  title: 'Clima atual',
                  message: expiredSession
                      ? 'Sua sessao expirou. Entre novamente para continuar.'
                      : message,
                  supportingText: expiredSession
                      ? 'Ao entrar de novo, o app volta a carregar clima e sensores normalmente.'
                      : 'Tente atualizar de novo em instantes.',
                  actionLabel: expiredSession
                      ? 'Entrar novamente'
                      : 'Tentar novamente',
                  onAction: expiredSession
                      ? _handleSessionExpired
                      : () => setState(() {
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
                  tone: expiredSession
                      ? AppStateTone.warning
                      : AppStateTone.neutral,
                );
              }

              final weather = snapshot.data;
              if (weather == null) {
                return _StateCard(
                  title: 'Clima atual',
                  message: 'Sem atualizacao de clima no momento.',
                  supportingText:
                      'Tente novamente quando houver uma nova consulta para esta area.',
                );
              }

              return WeatherCard(weather: weather);
            },
          ),
          const SizedBox(height: 20),
          const SectionHeader(
            eyebrow: 'Leituras de campo',
            title: 'Sensores da propriedade',
            description:
                'Ultimas leituras recebidas para identificar rapidamente o que precisa de acompanhamento.',
            compact: true,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<SensorModel>>(
            future: _sensorsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _StateCard(
                  title: 'Sensores da propriedade',
                  message: 'Buscando as leituras mais recentes.',
                  supportingText:
                      'Os sensores ativos serao exibidos assim que a consulta terminar.',
                  loading: true,
                );
              }

              if (snapshot.hasError) {
                final message = snapshot.error.toString();
                final expiredSession = _isSessionExpiredMessage(message);
                return _StateCard(
                  title: 'Sensores da propriedade',
                  message: expiredSession
                      ? 'Sua sessao expirou. Entre novamente para continuar.'
                      : 'Nao foi possivel carregar os sensores agora.',
                  supportingText: expiredSession
                      ? 'Ao entrar de novo, as leituras de campo voltam a aparecer aqui.'
                      : 'Tente atualizar novamente em instantes.',
                  actionLabel: expiredSession
                      ? 'Entrar novamente'
                      : 'Recarregar',
                  onAction: expiredSession
                      ? _handleSessionExpired
                      : () => setState(_loadData),
                  tone: expiredSession
                      ? AppStateTone.warning
                      : AppStateTone.neutral,
                );
              }

              final sensors = snapshot.data ?? _currentSensors;
              if (sensors.isEmpty) {
                return _StateCard(
                  title: 'Sensores da propriedade',
                  message: 'Nenhum sensor encontrado para esta propriedade.',
                  supportingText:
                      'Quando houver sensores vinculados, as leituras mais recentes aparecem aqui.',
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
    this.supportingText,
    this.loading = false,
    this.actionLabel,
    this.onAction,
    this.tone = AppStateTone.neutral,
  });

  final String title;
  final String message;
  final String? supportingText;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppStateTone tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppStateCard(
        title: title,
        message: message,
        supportingText: supportingText,
        loading: loading,
        actionLabel: actionLabel,
        onAction: onAction,
        tone: tone,
      ),
    );
  }
}
