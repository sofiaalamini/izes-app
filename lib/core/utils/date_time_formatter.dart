import 'package:intl/intl.dart';

class DateTimeFormatter {
  static final DateFormat _shortDateTimeFormat = DateFormat('dd/MM HH:mm');

  static String shortDateTime(dynamic value) {
    if (value == null) {
      return 'Sem data';
    }

    final parsed = parse(value);
    if (parsed == null) {
      return value.toString();
    }

    return _shortDateTimeFormat.format(parsed);
  }

  static DateTime? parse(dynamic value) {
    if (value == null) {
      return null;
    }

    DateTime? parsed;
    if (value is DateTime) {
      parsed = value;
    } else {
      parsed = DateTime.tryParse(value.toString());
    }

    if (parsed == null) {
      return null;
    }

    return parsed.toLocal();
  }
}
