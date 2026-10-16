import '../models/dose_log.dart';
import '../models/medicine.dart';
import '../utils/time_utils.dart';

const List<String> _weekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// The numbers for one day.
class DayStat {
  final DateTime date;
  final int taken;
  final int skipped;
  final int missed;
  final int pending; // due later today, not counted as missed yet

  const DayStat({
    required this.date,
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.pending,
  });

  String get label =>
      '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';

  String get summary {
    final parts = <String>[];
    if (taken > 0) parts.add('$taken taken');
    if (skipped > 0) parts.add('$skipped skipped');
    if (missed > 0) parts.add('$missed missed');
    if (pending > 0) parts.add('$pending coming up');
    return parts.isEmpty ? 'No doses scheduled' : parts.join(', ');
  }
}

/// The whole report: a list of days (newest first) plus totals.
class AdherenceReport {
  final List<DayStat> days;

  const AdherenceReport(this.days);

  int get taken => days.fold(0, (sum, d) => sum + d.taken);
  int get skipped => days.fold(0, (sum, d) => sum + d.skipped);
  int get missed => days.fold(0, (sum, d) => sum + d.missed);

  /// Doses that are finished one way or another (pending ones are left out).
  int get total => taken + skipped + missed;

  int get percent => total == 0 ? 0 : (taken * 100 / total).round();

  /// The plain text that is copied or sent on WhatsApp.
  String toShareText() {
    final buffer = StringBuffer();
    buffer.writeln('Medicine report (last ${days.length} days)');
    buffer.writeln('Adherence: $percent% ($taken of $total doses taken)');
    buffer.writeln('Taken: $taken | Skipped: $skipped | Missed: $missed');
    buffer.writeln();
    for (final day in days) {
      buffer.writeln('${day.label}: ${day.summary}');
    }
    return buffer.toString().trim();
  }
}

class ReportBuilder {
  /// A dose is "missed" when it is more than 60 minutes late.
  static const int _missedAfterMinutes = 60;

  static AdherenceReport build({
    required List<Medicine> medicines,
    required List<DoseLog> logs,
    required DateTime now,
    int days = 7,
  }) {
    final todayText = todayKey(now);
    final nowMinutes = now.hour * 60 + now.minute;
    final stats = <DayStat>[];

    for (var i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dateText = todayKey(date);

      var taken = 0;
      var skipped = 0;
      var missed = 0;
      var pending = 0;

      for (final medicine in medicines) {
        final status = _statusOn(medicine, logs, dateText);

        // Before the medicine existed, nothing was scheduled.
        if (status == null &&
            dateText.compareTo(_startDate(medicine, logs, todayText)) < 0) {
          continue;
        }

        if (status == DoseStatus.taken) {
          taken++;
        } else if (status == DoseStatus.skipped) {
          skipped++;
        } else if (dateText != todayText) {
          missed++; // a past day with nothing recorded
        } else if (nowMinutes > medicine.minutesOfDay + _missedAfterMinutes) {
          missed++; // today, and already more than an hour late
        } else {
          pending++;
        }
      }

      stats.add(
        DayStat(
          date: date,
          taken: taken,
          skipped: skipped,
          missed: missed,
          pending: pending,
        ),
      );
    }

    return AdherenceReport(stats);
  }

  static DoseStatus? _statusOn(
    Medicine medicine,
    List<DoseLog> logs,
    String dateText,
  ) {
    for (final log in logs) {
      if (log.medicineId == medicine.id && log.date == dateText) {
        return log.status;
      }
    }
    return null;
  }

  /// The first day we should count this medicine.
  /// Old medicines have no createdOn, so we use their earliest record.
  static String _startDate(
    Medicine medicine,
    List<DoseLog> logs,
    String todayText,
  ) {
    final created = medicine.createdOn;
    if (created != null) return created;

    var earliest = todayText;
    for (final log in logs) {
      if (log.medicineId == medicine.id && log.date.compareTo(earliest) < 0) {
        earliest = log.date;
      }
    }
    return earliest;
  }
}
