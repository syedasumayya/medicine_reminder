import 'dart:async';
import 'package:flutter/material.dart';
import '../models/dose_log.dart';
import '../models/medicine.dart';
import '../services/dose_log_storage.dart';
import '../services/medicine_storage.dart';
import '../utils/time_utils.dart';
import 'add_medicine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MedicineStorage _medicineStorage = MedicineStorage();
  final DoseLogStorage _logStorage = DoseLogStorage();

  List<Medicine> _medicines = [];
  List<DoseLog> _logs = [];
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
    if (!mounted) return;
    setState(() {
      _medicines = medicines;
      _logs = logs;
      _loading = false;
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
  }

  /// Opens the form. If [existing] is given, it edits that medicine.
  Future<void> _openForm({Medicine? existing}) async {
    final result = await Navigator.push<Medicine>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(existing: existing),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _medicines.indexWhere((m) => m.id == result.id);
      if (index == -1) {
        _medicines.add(result);
      } else {
        _medicines[index] = result;
      }
    });
    await _medicineStorage.save(_medicines);
  }

  Future<void> _confirmDelete(Medicine medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete medicine?'),
        content: Text('Remove ${medicine.name} and its history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _medicines.removeWhere((m) => m.id == medicine.id);
      _logs.removeWhere((l) => l.medicineId == medicine.id);
    });
    await _medicineStorage.save(_medicines);
    await _logStorage.save(_logs);
  }

  // ---------- In-app reminders ----------

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
        await _showReminderDialog(medicine);
        if (!mounted) return;
      }
    }
  }

  Future<void> _showReminderDialog(Medicine medicine) async {
    final result = await showDialog<DoseStatus>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.alarm),
        title: const Text('Time for your medicine'),
        content: Text('${medicine.name} - ${medicine.dose}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, DoseStatus.skipped),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, DoseStatus.taken),
            child: const Text('Taken'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _setStatus(medicine, result);
    }
  }

  // ---------- Screen parts ----------

  Widget _buildSummary() {
    final total = _medicines.length;
    final taken = _takenTodayCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's progress",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: total == 0 ? 0 : taken / total,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text('$taken of $total taken today'),
        ],
      ),
    );
  }

  Widget _buildStatusArea(Medicine medicine) {
    final status = _statusFor(medicine);

    if (status != null) {
      final isTaken = status == DoseStatus.taken;
      return Row(
        children: [
          Chip(
            avatar: Icon(
              isTaken ? Icons.check_circle : Icons.remove_circle_outline,
              size: 18,
              color: isTaken ? Colors.green : Colors.grey,
            ),
            label: Text(isTaken ? 'Taken' : 'Skipped'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _setStatus(medicine, null),
            child: const Text('Undo'),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (_isMissed(medicine))
          const Chip(
            avatar: Icon(Icons.warning_amber, size: 18, color: Colors.red),
            label: Text('Missed'),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => _setStatus(medicine, DoseStatus.skipped),
          child: const Text('Skip'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => _setStatus(medicine, DoseStatus.taken),
          child: const Text('Mark taken'),
        ),
      ],
    );
  }

  Widget _buildList() {
    final medicines = _sortedMedicines;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: medicines.length + 1, // +1 for the progress summary on top
      itemBuilder: (context, index) {
        if (index == 0) return _buildSummary();
        final medicine = medicines[index - 1];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.medication),
                  title: Text(medicine.name),
                  subtitle: Text(
                    '${medicine.dose}  •  ${medicine.timeOfDay.format(context)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(medicine),
                  ),
                  onTap: () => _openForm(existing: medicine),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildStatusArea(medicine),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_medicines.isEmpty) {
      return const Center(
        child: Text(
          'No medicines yet.\nTap + to add one.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return _buildList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Add medicine',
        child: const Icon(Icons.add),
      ),
    );
  }
}
