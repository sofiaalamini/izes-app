enum SensorStatus { online, attention, offline }

class SensorModel {
  const SensorModel({
    required this.id,
    required this.label,
    required this.status,
    this.lastReading,
    required this.note,
    required this.primaryValue,
    this.location,
    this.facts = const <SensorFact>[],
  });

  final String id;
  final String label;
  final SensorStatus status;
  final DateTime? lastReading;
  final String note;
  final String primaryValue;
  final String? location;
  final List<SensorFact> facts;
}

class SensorFact {
  const SensorFact({required this.label, required this.value});

  final String label;
  final String value;
}
