/// Office shift rules used to label attendance events
/// ("On time", "Too Early", "Late", "12 Min Early", ...).
enum ShiftTone { good, bad, neutral }

class ShiftEvaluation {
  final String label;
  final ShiftTone tone;
  final String delta;

  const ShiftEvaluation(this.label, this.tone, this.delta);
}

abstract final class ShiftRules {
  static const startHour = 9;
  static const breakHour = 12;
  static const endHour = 18;

  static DateTime shiftStart(DateTime day) =>
      DateTime(day.year, day.month, day.day, startHour);
  static DateTime shiftEnd(DateTime day) =>
      DateTime(day.year, day.month, day.day, endHour);

  static String formatMinutes(int minutes) {
    final m = minutes.abs();
    if (m < 60) return '$m Min';
    final h = m ~/ 60;
    final rest = m % 60;
    return rest == 0 ? '${h}h' : '${h}h ${rest}m';
  }

  static ShiftEvaluation evaluate(String type, DateTime time, {String? status}) {
    switch (type) {
      case 'check_in':
        final diff = time.difference(shiftStart(time)).inMinutes;
        if (diff <= 0) {
          return ShiftEvaluation(
            'On time',
            ShiftTone.good,
            diff == 0 ? 'Right on time' : '${formatMinutes(diff)} Early',
          );
        }
        return ShiftEvaluation('Late', ShiftTone.bad, '${formatMinutes(diff)} Late');
      case 'check_out':
        final diff = time.difference(shiftEnd(time)).inMinutes;
        if (diff < 0) {
          return ShiftEvaluation(
              'Too Early', ShiftTone.bad, '${formatMinutes(diff)} Early');
        }
        return ShiftEvaluation(
          'On time',
          ShiftTone.good,
          diff == 0 ? 'Right on time' : '+${formatMinutes(diff)} Stay',
        );
      case 'break':
        final target = DateTime(time.year, time.month, time.day, breakHour);
        final diff = time.difference(target).inMinutes;
        if (diff < -10) {
          return ShiftEvaluation(
              'Too Early', ShiftTone.bad, '${formatMinutes(diff)} Early');
        }
        return ShiftEvaluation(
          'On time',
          ShiftTone.good,
          diff <= 0 ? 'Break started' : '${formatMinutes(diff)} After Noon',
        );
      case 'overtime':
        return const ShiftEvaluation('Overtime', ShiftTone.good, 'Extra hours');
      case 'leave':
        return ShiftEvaluation(status ?? 'Submitted', ShiftTone.neutral, 'Leave request');
      default:
        return ShiftEvaluation(status ?? '—', ShiftTone.neutral, '');
    }
  }
}
