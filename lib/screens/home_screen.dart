import 'dart:async';
import 'package:flutter/material.dart';
import '../models/dose_log.dart';
import '../models/medicine.dart';
import '../services/dose_log_storage.dart';
import '../services/medicine_storage.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/dialogs.dart';
import '../widgets/pill_image.dart';
import 'about_screen.dart';
import 'add_medicine_screen.dart';
import 'reminder_settings_screen.dart';
import 'report_screen.dart';
import 'scan_prescription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MedicineStorage _medicineStorage = MedicineStorage();
  final DoseLogStorage _logStorage = DoseLogStorage();
  final ReminderService _reminders = ReminderService();

  List<Medicine> _medicines = [];
  List<DoseLog> _logs = [];
  ReminderSettings? _reminderSettings;
  bool _loading = true;

  Timer? _timer;
  // Remembers which reminders we already showed, so we never show one twice.
  final Set<String> _alreadyAlerted = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _checkDueMedicines(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------- Loading ----------

  Future<void> _loadData() async {
    final medicines = await _medicineStorage.load();
    final logs = await _logStorage.load();
    final reminderSettings = await _reminders.loadSettings();
    if (!mounted) return;
    setState(() {
      _medicines = medicines;
      _logs = logs;
      _reminderSettings = reminderSettings;
      _loading = false;
    });
    await _autoSyncReminders();
  }

  // ---------- Phone reminders ----------

  /// When the app opens, refresh the phone reminders if it was a while ago.
  Future<void> _autoSyncReminders() async {
    final settings = _reminderSettings;
    if (settings == null || !settings.enabled) return;
    if (await _reminders.needsAutoSync(settings)) {
      await _reminders.syncAll(
        settings: settings,
        medicines: _medicines,
        logs: _logs,
      );
    }
  }

  /// Schedules all the coming phone reminders again (after the list changed).
  void _syncReminders() {
    final settings = _reminderSettings;
    if (settings == null || !settings.enabled) return;
    unawaited(
      _reminders.syncAll(
        settings: settings,
        medicines: _medicines,
        logs: _logs,
      ),
    );
  }

  Future<void> _openReminderSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReminderSettingsScreen(
          medicines: _medicines,
          logs: _logs,
        ),
      ),
    );
    if (!mounted) return;
    final settings = await _reminders.loadSettings();
    if (!mounted) return;
    setState(() {
      _reminderSettings = settings;
    });
  }

  // ---------- Helpers ----------

  List<Medicine> get _sortedMedicines {
    final copy = List<Medicine>.of(_medicines);
    copy.sort((a, b) => a.minutesOfDay.compareTo(b.minutesOfDay));
    return copy;
  }

  /// Today's status for a medicine, or null if nothing is recorded yet.
  DoseStatus? _statusFor(Medicine medicine) {
    final today = todayKey();
    for (final log in _logs) {
      if (log.medicineId == medicine.id && log.date == today) {
        return log.status;
      }
    }
    return null;
  }

  int get _takenTodayCount =>
      _medicines.where((m) => _statusFor(m) == DoseStatus.taken).length;

  /// A dose counts as missed if it is more than 1 hour late and not recorded.
  bool _isMissed(Medicine medicine) {
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    return _statusFor(medicine) == null &&
        nowMinutes > medicine.minutesOfDay + 60;
  }

  /// Which part of the day a medicine belongs to.
  String _periodOf(Medicine medicine) {
    if (medicine.hour < 12) return 'Morning';
    if (medicine.hour < 17) return 'Afternoon';
    return 'Evening';
  }

  IconData _periodIcon(String period) {
    switch (period) {
      case 'Morning':
        return Icons.wb_sunny_outlined;
      case 'Afternoon':
        return Icons.light_mode_outlined;
      default:
        return Icons.wb_twilight;
    }
  }

  // ---------- Actions ----------

  /// Sets today's status. Passing null clears it (this is the "Undo").
  Future<void> _setStatus(Medicine medicine, DoseStatus? status) async {
    final today = todayKey();
    setState(() {
      _logs.removeWhere((l) => l.medicineId == medicine.id && l.date == today);
      if (status != null) {
        _logs.add(
          DoseLog(medicineId: medicine.id, date: today, status: status),
        );
      }
    });
    await _logStorage.save(_logs);

    // Cancel (or bring back) today's reminder on the phone.
    final settings = _reminderSettings;
    if (settings != null && settings.enabled) {
      unawaited(
        _reminders.onDoseChanged(
          settings: settings,
          medicine: medicine,
          status: status,
        ),
      );
    }
  }

  /// Opens the form. If [existing] is given, it edits that medicine.
  Future<void> _openForm({Medicine? existing}) async {
    final result = await Navigator.push<MedicineFormResult>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(existing: existing),
      ),
    );
    if (result == null || !mounted) return;

    if (result.deleted) {
      if (existing != null) await _deleteMedicine(existing);
      return;
    }

    final saved = result.medicine;
    if (saved == null) return;
    setState(() {
      final index = _medicines.indexWhere((m) => m.id == saved.id);
      if (index == -1) {
        _medicines.add(saved);
      } else {
        _medicines[index] = saved;
      }
    });
    await _medicineStorage.save(_medicines);
    _syncReminders();
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    setState(() {
      _medicines.removeWhere((m) => m.id == medicine.id);
      _logs.removeWhere((l) => l.medicineId == medicine.id);
    });
    await _medicineStorage.save(_medicines);
    await _logStorage.save(_logs);

    final settings = _reminderSettings;
    if (settings != null && settings.enabled) {
      unawaited(
        _reminders.onMedicineRemoved(settings: settings, medicine: medicine),
      );
    }
  }

  /// Opens the prescription import screen and adds the medicines it returns.
  Future<void> _openImportScreen() async {
    final result = await Navigator.push<List<Medicine>>(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanPrescriptionScreen(),
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    setState(() {
      _medicines.addAll(result);
    });
    await _medicineStorage.save(_medicines);
    _syncReminders();
  }

  /// Opens the weekly report.
  void _openReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportScreen(medicines: _medicines, logs: _logs),
      ),
    );
  }

  /// Opens the About page.
  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutScreen()),
    );
  }

  /// Handles taps on the bottom bar (Home is the screen we are already on).
  void _onNavTap(int index) {
    if (index == 1) _openReport();
    if (index == 2) _openReminderSettings();
    if (index == 3) _openAbout();
  }

  // ---------- In-app reminders (pop-up while the app is open) ----------

  Future<void> _checkDueMedicines() async {
    if (!mounted) return;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    for (final medicine in _medicines) {
      final key = '${medicine.id}-${todayKey()}';
      final isDueNow = medicine.minutesOfDay == nowMinutes;
      if (isDueNow &&
          _statusFor(medicine) == null &&
          !_alreadyAlerted.contains(key)) {
        _alreadyAlerted.add(key);
        await _showReminder(medicine);
        if (!mounted) return;
      }
    }
  }

  Future<void> _showReminder(Medicine medicine) async {
    final result = await showReminderDialog(context, medicine);
    if (result != null) {
      await _setStatus(medicine, result);
    }
  }

  // ---------- Screen parts ----------

  /// A round, light-purple button for the top bar.
  Widget _topBarButton(IconData icon, String tooltip, VoidCallback onPressed) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.primary,
        ),
      ),
    );
  }

  /// The rounded outline shared by all cards.
  ShapeBorder _cardShape() {
    final scheme = Theme.of(context).colorScheme;
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: scheme.outlineVariant),
    );
  }

  /// The "Today's progress" card, with the big + button on its right side.
  Widget _buildSummary() {
    final scheme = Theme.of(context).colorScheme;
    final total = _medicines.length;
    final taken = _takenTodayCount;
    return Card(
      elevation: 0,
      color: scheme.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: _cardShape(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's progress",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : taken / total,
                      minHeight: 10,
                      color: AppColors.success,
                      backgroundColor: scheme.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$taken of $total taken today',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.add, size: 28),
              tooltip: 'Add medicine',
              onPressed: () => _openForm(),
              style: IconButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                fixedSize: const Size(56, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown until the phone reminders are turned on.
  Widget _buildReminderBanner() {
    final settings = _reminderSettings;
    if (settings == null || settings.enabled) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openReminderSettings,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get reminders on your phone',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to set up notifications that ring even when '
                      'the app is closed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String period) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Icon(_periodIcon(period), size: 20, color: const Color(0xFFF2A100)),
          const SizedBox(width: 8),
          Text(
            period,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusArea(Medicine medicine) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = _statusFor(medicine);

    // Already taken or skipped: show a coloured bar with Undo.
    if (status != null) {
      final isTaken = status == DoseStatus.taken;
      final barColor = isTaken
          ? (isDark ? const Color(0xFF1F3A2C) : const Color(0xFFDDF5E8))
          : scheme.surfaceContainerHighest;
      final contentColor =
          isTaken ? AppColors.success : scheme.onSurfaceVariant;

      return Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: barColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              isTaken ? Icons.check_circle : Icons.remove_circle_outline,
              color: contentColor,
            ),
            const SizedBox(width: 8),
            Text(
              isTaken ? 'Taken' : 'Skipped',
              style: TextStyle(
                color: contentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => _setStatus(medicine, null),
              child: const Text('Undo'),
            ),
          ],
        ),
      );
    }

    // Not recorded yet: show Skip and Mark taken.
    return Column(
      children: [
        if (_isMissed(medicine))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3B1F22)
                      : const Color(0xFFFDE7E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Missed',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => _setStatus(medicine, DoseStatus.skipped),
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => _setStatus(medicine, DoseStatus.taken),
                child: const Text('Mark taken'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicineCard(Medicine medicine) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: _cardShape(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openForm(existing: medicine),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  PillBadge(index: PillImage.forMedicine(medicine), size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${medicine.dose}  •  '
                          '${medicine.timeOfDay.format(context)}',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatusArea(medicine),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    // Group the medicines by part of the day (they are already sorted by time).
    final groups = <String, List<Medicine>>{
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
    };
    for (final medicine in _sortedMedicines) {
      groups[_periodOf(medicine)]!.add(medicine);
    }

    final children = <Widget>[_buildSummary(), _buildReminderBanner()];
    for (final entry in groups.entries) {
      if (entry.value.isEmpty) continue;
      children.add(_buildSectionHeader(entry.key));
      children.addAll(entry.value.map(_buildMedicineCard));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: children,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_medicines.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildSummary(),
          _buildReminderBanner(),
          const SizedBox(height: 24),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PillBadge(index: 4, size: 110, circle: true),
                SizedBox(height: 16),
                Text(
                  'No medicines yet.\nTap + to add one.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return _buildList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: const Text(
          'My Medicines',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          _topBarButton(Icons.bar_chart, 'Weekly report', _openReport),
          _topBarButton(
            Icons.upload_file_outlined,
            'Import prescription',
            _openImportScreen,
          ),
          _topBarButton(Icons.info_outline, 'About', _openAbout),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        selectedIndex: 0,
        onDestinationSelected: _onNavTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
