import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicine_reminder/models/dose_log.dart';
import 'package:medicine_reminder/models/medicine.dart';
import 'package:medicine_reminder/services/reminder_service.dart';

// A fixed "now": Thursday 15 Oct 2026, 12:00 noon.
final DateTime _now = DateTime(2026, 10, 15, 12, 0);

const Medicine _morning = Medicine(
  id: 1,
  name: 'Panadol',
  dose: '1 tablet',
  hour: 8,
  minute: 0,
);

const Medicine _evening = Medicine(
  id: 2,
  name: 'Vitamin D',
  dose: '1 capsule',
  hour: 21,
  minute: 0,
);

const ReminderSettings _on = ReminderSettings(
  enabled: true,
  topic: 'medrem-testtopic',
  showNames: true,
);

String _unixSeconds(DateTime time) {
  return (time.millisecondsSinceEpoch ~/ 1000).toString();
}

void main() {
  group('planReminders', () {
    test('plans the next 70 hours and skips doses that already passed', () {
      final plan = planReminders(
        medicines: [_morning, _evening],
        logs: [],
        now: _now,
      );

      // today 21:00, then 2 a day on the next two days, then 08:00 on day 3
      expect(plan.length, 6);
      expect(plan.first.sequenceId, 'm2-20261015');
      expect(plan.first.at, DateTime(2026, 10, 15, 21, 0));
      expect(plan.last.at, DateTime(2026, 10, 18, 8, 0));
    });

    test('leaves out a dose that was already taken today', () {
      final plan = planReminders(
        medicines: [_morning, _evening],
        logs: const [
          DoseLog(
            medicineId: 2,
            date: '2026-10-15',
            status: DoseStatus.taken,
          ),
        ],
        now: _now,
      );

      expect(plan.length, 5);
      expect(plan.any((p) => p.sequenceId == 'm2-20261015'), isFalse);
    });

    test('gives every dose its own short name', () {
      expect(sequenceIdFor(_evening, DateTime(2026, 10, 16)), 'm2-20261016');
    });

    test('plans nothing when there are no medicines', () {
      expect(planReminders(medicines: [], logs: [], now: _now), isEmpty);
    });
  });

  group('ReminderService', () {
    late List<http.Request> requests;
    late ReminderService service;

    ReminderService serviceWith(int statusCode, {DateTime? at}) {
      return ReminderService(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', statusCode);
        }),
        clock: () => at ?? _now,
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      requests = [];
      service = serviceWith(200);
    });

    test('makes a long secret topic name', () {
      final first = ReminderService.generateTopic();
      final second = ReminderService.generateTopic();

      expect(first, startsWith('medrem-'));
      expect(first.length, 27);
      expect(first, isNot(second));
    });

    test('creates a topic once and keeps it', () async {
      final first = await service.loadSettings();
      final second = await service.loadSettings();

      expect(first.topic, second.topic);
      expect(first.enabled, isFalse);
      expect(first.showNames, isTrue);
    });

    test('saves the settings', () async {
      await service.saveSettings(_on.copyWith(showNames: false));

      final loaded = await service.loadSettings();

      expect(loaded.enabled, isTrue);
      expect(loaded.topic, 'medrem-testtopic');
      expect(loaded.showNames, isFalse);
    });

    test('schedules every coming dose on ntfy.sh', () async {
      final result = await service.syncAll(
        settings: _on,
        medicines: [_morning, _evening],
        logs: [],
      );

      expect(result.scheduled, 6);
      expect(result.failed, 0);
      expect(requests.length, 6);

      final first = requests.first;
      expect(first.method, 'POST');
      expect(first.url.toString(), 'https://ntfy.sh/medrem-testtopic');
      expect(first.headers['X-Sequence-ID'], 'm2-20261015');
      expect(
        first.headers['X-Delay'],
        _unixSeconds(DateTime(2026, 10, 15, 21, 0)),
      );
      expect(first.headers['X-Title'], 'Time for your medicine');
      expect(first.body, 'Vitamin D (1 capsule)');
    });

    test('can hide the medicine name', () async {
      await service.syncAll(
        settings: _on.copyWith(showNames: false),
        medicines: [_evening],
        logs: [],
      );

      expect(requests.first.body, 'It is time to take your medicine.');
    });

    test('does nothing when phone reminders are off', () async {
      final result = await service.syncAll(
        settings: _on.copyWith(enabled: false),
        medicines: [_morning, _evening],
        logs: [],
      );

      expect(result.scheduled, 0);
      expect(requests, isEmpty);
    });

    test('counts the reminders that failed', () async {
      final failing = serviceWith(500);

      final result = await failing.syncAll(
        settings: _on,
        medicines: [_morning, _evening],
        logs: [],
      );

      expect(result.scheduled, 0);
      expect(result.failed, 6);
      expect(result.ok, isFalse);
    });

    test('cancels today\'s reminder of a dose that is already taken', () async {
      await service.syncAll(
        settings: _on,
        medicines: [_evening],
        logs: const [
          DoseLog(
            medicineId: 2,
            date: '2026-10-15',
            status: DoseStatus.taken,
          ),
        ],
      );

      final deletes = requests.where((r) => r.method == 'DELETE').toList();
      expect(deletes.length, 1);
      expect(
        deletes.first.url.toString(),
        'https://ntfy.sh/medrem-testtopic/m2-20261015',
      );
      // the next two evenings are still scheduled
      expect(requests.where((r) => r.method == 'POST').length, 2);
    });

    test('marking a dose Taken cancels its reminder', () async {
      await service.onDoseChanged(
        settings: _on,
        medicine: _morning,
        status: DoseStatus.taken,
      );

      expect(requests.length, 1);
      expect(requests.first.method, 'DELETE');
      expect(
        requests.first.url.toString(),
        'https://ntfy.sh/medrem-testtopic/m1-20261015',
      );
    });

    test('undoing a dose that is still ahead brings the reminder back',
        () async {
      await service.onDoseChanged(
        settings: _on,
        medicine: _evening,
        status: null,
      );

      expect(requests.length, 1);
      expect(requests.first.method, 'POST');
      expect(requests.first.headers['X-Sequence-ID'], 'm2-20261015');
      expect(
        requests.first.headers['X-Delay'],
        _unixSeconds(DateTime(2026, 10, 15, 21, 0)),
      );
    });

    test('undoing a dose whose time has passed sends nothing', () async {
      await service.onDoseChanged(
        settings: _on,
        medicine: _morning,
        status: null,
      );

      expect(requests, isEmpty);
    });

    test('deleting a medicine cancels its coming reminders', () async {
      await service.onMedicineRemoved(settings: _on, medicine: _morning);

      final urls = requests.map((r) => r.url.toString()).toList();
      expect(requests.every((r) => r.method == 'DELETE'), isTrue);
      expect(urls, [
        'https://ntfy.sh/medrem-testtopic/m1-20261015',
        'https://ntfy.sh/medrem-testtopic/m1-20261016',
        'https://ntfy.sh/medrem-testtopic/m1-20261017',
        'https://ntfy.sh/medrem-testtopic/m1-20261018',
      ]);
    });

    test('the test notification arrives in about 20 seconds', () async {
      final ok = await service.sendTest(_on);

      expect(ok, isTrue);
      expect(requests.length, 1);
      expect(requests.first.headers['X-Sequence-ID'], 'test');
      expect(
        requests.first.headers['X-Delay'],
        _unixSeconds(_now.add(const Duration(seconds: 20))),
      );
    });

    test('a test that cannot be sent says so', () async {
      final failing = serviceWith(500);

      expect(await failing.sendTest(_on), isFalse);
    });

    test('asks for a refresh when reminders were never sent', () async {
      expect(await service.needsAutoSync(_on), isTrue);
      expect(
        await service.needsAutoSync(_on.copyWith(enabled: false)),
        isFalse,
      );
    });

    test('does not refresh again within 6 hours, but does after that',
        () async {
      await service.syncAll(settings: _on, medicines: [_evening], logs: []);

      expect(await service.needsAutoSync(_on), isFalse);

      final later = serviceWith(200, at: _now.add(const Duration(hours: 7)));
      expect(await later.needsAutoSync(_on), isTrue);
    });
  });
}
