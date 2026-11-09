import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dose_log.dart';
import '../models/medicine.dart';
import '../utils/time_utils.dart';

/// The page that opens when the user taps a reminder on the phone.
const String kAppUrl = 'https://syedasumayya.github.io/medicine_reminder/';

/// The free notification service that carries our reminders to the phone.
/// (The phone has the free "ntfy" app, which listens to a secret topic name.)
const String kNtfyServer = 'https://ntfy.sh';

/// The settings of the phone reminders.
class ReminderSettings {
  final bool enabled;

  /// The secret topic name. The ntfy app on the phone subscribes to it.
  final String topic;

  /// Whether the medicine name is written in the notification.
  final bool showNames;

  const ReminderSettings({
    required this.enabled,
    required this.topic,
    required this.showNames,
  });

  ReminderSettings copyWith({bool? enabled, String? topic, bool? showNames}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      topic: topic ?? this.topic,
      showNames: showNames ?? this.showNames,
    );
  }
}

/// One notification we want the phone to show at a certain time.
class PlannedReminder {
  final Medicine medicine;
  final DateTime at;
  final String sequenceId;

  const PlannedReminder({
    required this.medicine,
    required this.at,
    required this.sequenceId,
  });
}

/// How many reminders were scheduled, and how many failed.
class SyncResult {
  final int scheduled;
  final int failed;

  const SyncResult({required this.scheduled, required this.failed});

  bool get ok => failed == 0;
}

/// A short name for one dose, like m123-20261015. Sending the same name again
/// replaces the earlier reminder, so we never get the same reminder twice.
String sequenceIdFor(Medicine medicine, DateTime day) {
  return 'm${medicine.id}-${todayKey(day).replaceAll('-', '')}';
}

/// Works out which reminders the phone should get.
///
/// The free service can only hold a message for 3 days, so we plan the next
/// [hoursAhead] hours. Doses that are already taken or skipped today are left out.
List<PlannedReminder> planReminders({
  required List<Medicine> medicines,
  required List<DoseLog> logs,
  required DateTime now,
  int hoursAhead = 70,
}) {
  final result = <PlannedReminder>[];
  final today = todayKey(now);
  final earliest = now.add(const Duration(seconds: 30));
  final latest = now.add(Duration(hours: hoursAhead));

  for (var dayOffset = 0; dayOffset <= 3; dayOffset++) {
    final day = DateTime(now.year, now.month, now.day + dayOffset);
    final dayText = todayKey(day);

    for (final medicine in medicines) {
      final at = DateTime(
        day.year,
        day.month,
        day.day,
        medicine.hour,
        medicine.minute,
      );
      if (at.isBefore(earliest) || at.isAfter(latest)) continue;
      if (dayText == today && _hasLog(logs, medicine.id, today)) continue;

      result.add(
        PlannedReminder(
          medicine: medicine,
          at: at,
          sequenceId: sequenceIdFor(medicine, day),
        ),
      );
    }
  }

  result.sort((a, b) => a.at.compareTo(b.at));
  return result;
}

bool _hasLog(List<DoseLog> logs, int medicineId, String dateText) {
  return logs.any((l) => l.medicineId == medicineId && l.date == dateText);
}

class ReminderService {
  ReminderService({http.Client? client, DateTime Function()? clock})
      : _client = client ?? http.Client(),
        _clock = clock ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _clock;

  static const String _enabledKey = 'reminder_enabled';
  static const String _topicKey = 'reminder_topic';
  static const String _namesKey = 'reminder_show_names';
  static const String _lastSyncKey = 'reminder_last_sync';

  /// Do not send more than this many messages in one go.
  static const int _maxPerSync = 40;

  // ---------- Settings ----------

  /// Makes a long random topic name. Anyone who knows it can read the
  /// reminders, so it must stay secret and hard to guess.
  static String generateTopic() {
    const letters = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final tail = List.generate(
      20,
      (_) => letters[random.nextInt(letters.length)],
    ).join();
    return 'medrem-$tail';
  }

  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    var topic = prefs.getString(_topicKey);
    if (topic == null || topic.isEmpty) {
      topic = generateTopic();
      await prefs.setString(_topicKey, topic);
    }
    return ReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      topic: topic,
      showNames: prefs.getBool(_namesKey) ?? true,
    );
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setString(_topicKey, settings.topic);
    await prefs.setBool(_namesKey, settings.showNames);
  }

  /// True if reminders are on and they were not refreshed for 6 hours.
  Future<bool> needsAutoSync(ReminderSettings settings) async {
    if (!settings.enabled) return false;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastSyncKey);
    if (last == null) return true;
    final lastTime = DateTime.fromMillisecondsSinceEpoch(last);
    return _clock().difference(lastTime) > const Duration(hours: 6);
  }

  Future<void> _saveLastSync(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }

  // ---------- Talking to ntfy.sh ----------

  String _title() => 'Time for your medicine';

  String _body(Medicine medicine, ReminderSettings settings) {
    if (settings.showNames) return '${medicine.name} (${medicine.dose})';
    return 'It is time to take your medicine.';
  }

  /// Asks the service to deliver a notification at time [at].
  Future<bool> _publish({
    required String topic,
    required DateTime at,
    required String sequenceId,
    required String body,
  }) async {
    final response = await _client.post(
      Uri.parse('$kNtfyServer/$topic'),
      headers: {
        'X-Title': _title(),
        'X-Priority': 'high',
        'X-Tags': 'pill',
        'X-Click': kAppUrl,
        'X-Sequence-ID': sequenceId,
        'X-Delay': (at.millisecondsSinceEpoch ~/ 1000).toString(),
      },
      body: body,
    );
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Cancels a reminder that was not delivered yet. Errors are ignored.
  Future<void> _cancel(String topic, String sequenceId) async {
    try {
      await _client.delete(Uri.parse('$kNtfyServer/$topic/$sequenceId'));
    } catch (_) {
      // No internet or the reminder did not exist: nothing to do.
    }
  }

  /// Sends a test notification that arrives in about 20 seconds.
  Future<bool> sendTest(ReminderSettings settings) async {
    try {
      return await _publish(
        topic: settings.topic,
        at: _clock().add(const Duration(seconds: 20)),
        sequenceId: 'test',
        body: 'This is a test. Your phone reminders work!',
      );
    } catch (_) {
      return false;
    }
  }

  /// Schedules every reminder for the next 3 days.
  /// It is safe to call it again and again, because the same dose always
  /// gets the same name and replaces the earlier reminder.
  Future<SyncResult> syncAll({
    required ReminderSettings settings,
    required List<Medicine> medicines,
    required List<DoseLog> logs,
  }) async {
    if (!settings.enabled) return const SyncResult(scheduled: 0, failed: 0);

    final now = _clock();
    var scheduled = 0;
    var failed = 0;

    final planned = planReminders(medicines: medicines, logs: logs, now: now)
        .take(_maxPerSync);
    for (final reminder in planned) {
      try {
        final ok = await _publish(
          topic: settings.topic,
          at: reminder.at,
          sequenceId: reminder.sequenceId,
          body: _body(reminder.medicine, settings),
        );
        if (ok) {
          scheduled++;
        } else {
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }

    // Doses already taken or skipped today must not ring later today.
    final today = todayKey(now);
    for (final medicine in medicines) {
      final at = DateTime(
        now.year,
        now.month,
        now.day,
        medicine.hour,
        medicine.minute,
      );
      if (at.isAfter(now) && _hasLog(logs, medicine.id, today)) {
        await _cancel(settings.topic, sequenceIdFor(medicine, now));
      }
    }

    await _saveLastSync(now);
    return SyncResult(scheduled: scheduled, failed: failed);
  }

  /// Call this when a dose was marked Taken or Skipped (status is set),
  /// or when the mark was undone (status is null).
  Future<void> onDoseChanged({
    required ReminderSettings settings,
    required Medicine medicine,
    required DoseStatus? status,
  }) async {
    if (!settings.enabled) return;
    final now = _clock();
    final sequenceId = sequenceIdFor(medicine, now);

    if (status != null) {
      await _cancel(settings.topic, sequenceId);
      return;
    }

    // Undo: bring today's reminder back if the time has not passed yet.
    final at = DateTime(
      now.year,
      now.month,
      now.day,
      medicine.hour,
      medicine.minute,
    );
    if (at.isAfter(now.add(const Duration(seconds: 30)))) {
      try {
        await _publish(
          topic: settings.topic,
          at: at,
          sequenceId: sequenceId,
          body: _body(medicine, settings),
        );
      } catch (_) {
        // No internet: it will be scheduled again on the next refresh.
      }
    }
  }

  /// Call this when a medicine was deleted: cancels its coming reminders.
  Future<void> onMedicineRemoved({
    required ReminderSettings settings,
    required Medicine medicine,
  }) async {
    if (!settings.enabled) return;
    final now = _clock();
    for (var dayOffset = 0; dayOffset <= 3; dayOffset++) {
      final day = DateTime(now.year, now.month, now.day + dayOffset);
      await _cancel(settings.topic, sequenceIdFor(medicine, day));
    }
  }
}
