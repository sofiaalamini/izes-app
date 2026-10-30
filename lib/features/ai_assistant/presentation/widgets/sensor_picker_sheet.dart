import 'package:flutter/material.dart';

import '../../../../core/models/sensor_model.dart';
import '../../../../core/services/sensor_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../core/utils/error_message.dart';

/// Abre a lista de sensores e devolve o escolhido (ou null se fechar sem escolher).
Future<SensorModel?> showSensorPicker(
  BuildContext context, {
  String? selectedId,
  SensorService? service,
}) {
  return showModalBottomSheet<SensorModel>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SensorPickerSheet(
      selectedId: selectedId,
      service: service ?? SensorService(),
    ),
  );
}

class SensorPickerSheet extends StatefulWidget {
  const SensorPickerSheet({super.key, this.selectedId, required this.service});

  final String? selectedId;
  final SensorService service;

  @override
  State<SensorPickerSheet> createState() => _SensorPickerSheetState();
}

class _SensorPickerSheetState extends State<SensorPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<SensorModel>? _sensors;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _sensors = null;
      _error = null;
    });
    try {
      final sensors = await widget.service.fetchSensors();
      if (!mounted) return;
      setState(() => _sensors = sensors);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = mensagemDeErro(
          error,
          padrao: 'Não foi possível carregar os sensores agora.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensors = _sensors;
    final query = _query.trim().toLowerCase();
    final visible = sensors == null
        ? const <SensorModel>[]
        : sensors
              .where(
                (sensor) =>
                    query.isEmpty ||
                    sensor.label.toLowerCase().contains(query) ||
                    sensor.note.toLowerCase().contains(query),
              )
              .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text(
                  'Sobre qual sensor você quer falar?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (sensors != null && sensors.length > 6)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: 'Buscar sensor',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
              Flexible(child: _body(visible)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(List<SensorModel> visible) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _load,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      );
    }
    if (_sensors == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_sensors!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Text('Nenhum sensor cadastrado para a sua conta ainda.'),
      );
    }
    if (visible.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Text('Nenhum sensor com esse nome.'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final sensor = visible[index];
        final selected = sensor.id == widget.selectedId;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          selected: selected,
          selectedTileColor: IzesColors.greenSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: _StatusDot(status: sensor.status),
          title: Text(
            sensor.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${_statusText(sensor.status)} • ${sensor.primaryValue}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: selected
              ? const Icon(Icons.check_circle_rounded, color: IzesColors.green)
              : null,
          onTap: () => Navigator.of(context).pop(sensor),
        );
      },
    );
  }

  String _statusText(SensorStatus status) {
    switch (status) {
      case SensorStatus.online:
        return 'Normal';
      case SensorStatus.attention:
        return 'Precisa de atenção';
      case SensorStatus.offline:
        return 'Sem leitura recente';
    }
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final SensorStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SensorStatus.online => IzesColors.green,
      SensorStatus.attention => IzesColors.observation,
      SensorStatus.offline => IzesColors.muted,
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.sensors_rounded, color: color, size: 20),
    );
  }
}
