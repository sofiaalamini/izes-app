import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izesapp/core/models/sensor_model.dart';
import 'package:izesapp/core/services/sensor_service.dart';
import 'package:izesapp/features/ai_assistant/presentation/widgets/sensor_picker_sheet.dart';

class _FakeSensorService extends SensorService {
  _FakeSensorService(this.sensors);

  final List<SensorModel> sensors;

  @override
  Future<List<SensorModel>> fetchSensors() async => sensors;
}

SensorModel _sensor(String id, String label, SensorStatus status) {
  return SensorModel(
    id: id,
    label: label,
    status: status,
    note: 'Fazenda',
    primaryValue: '30%',
  );
}

Future<SensorModel?> _abrir(WidgetTester tester, List<SensorModel> sensors) async {
  SensorModel? escolhido;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              escolhido = await showSensorPicker(
                context,
                service: _FakeSensorService(sensors),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return escolhido;
}

void main() {
  testWidgets('lista os sensores e devolve o que foi tocado', (tester) async {
    SensorModel? escolhido;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                escolhido = await showSensorPicker(
                  context,
                  service: _FakeSensorService([
                    _sensor('a', 'Canteiro 03', SensorStatus.attention),
                    _sensor('b', 'Canteiro 07', SensorStatus.online),
                  ]),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Sobre qual sensor você quer falar?'), findsOneWidget);
    expect(find.text('Canteiro 03'), findsOneWidget);
    expect(find.textContaining('Precisa de atenção'), findsOneWidget);

    await tester.tap(find.text('Canteiro 07'));
    await tester.pumpAndSettle();

    expect(escolhido?.id, 'b');
  });

  testWidgets('sem sensores explica que não há nenhum cadastrado', (tester) async {
    await _abrir(tester, const []);

    expect(find.textContaining('Nenhum sensor cadastrado'), findsOneWidget);
  });
}
