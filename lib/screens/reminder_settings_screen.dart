import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/dose_log.dart';
import '../models/medicine.dart';
import '../services/reminder_service.dart';

/// Where the user sets up reminders that ring on the phone, even when the
/// app is closed.
class ReminderSettingsScreen extends StatefulWidget {
  final List<Medicine> medicines;
  final List<DoseLog> logs;

  /// Only used by the tests. The app uses the normal service.
  final ReminderService? service;

  const ReminderSettingsScreen({
    super.key,
    required this.medicines,
    required this.logs,
    this.service,
  });

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late final ReminderService _service = widget.service ?? ReminderService();
  ReminderSettings? _settings;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _service.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
    });
  }

  Future<void> _update(ReminderSettings settings) async {
    await _service.saveSettings(settings);
    if (!mounted) return;
    setState(() {
      _settings = settings;
    });
  }

  /// Schedules the coming reminders and tells the user how it went.
  Future<void> _sync(ReminderSettings settings, {String prefix = ''}) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = await _service.syncAll(
      settings: settings,
      medicines: widget.medicines,
      logs: widget.logs,
    );
    if (!mounted) return;

    final String text;
    if (!result.ok) {
      text = '${prefix}Some reminders could not be sent. Check your '
          'internet and try again.';
    } else if (result.scheduled == 0) {
      text = '${prefix}No reminders are needed right now. They will be '
          'scheduled when you add medicines.';
    } else {
      text = '$prefix${result.scheduled} reminder(s) scheduled for the next '
          '3 days.';
    }
    setState(() {
      _busy = false;
      _message = text;
    });
  }

  Future<void> _toggleEnabled(bool value) async {
    final settings = _settings;
    if (settings == null) return;
    final updated = settings.copyWith(enabled: value);
    await _update(updated);
    if (value) {
      await _sync(updated, prefix: 'Phone reminders are on. ');
    } else if (mounted) {
      setState(() {
        _message = 'Phone reminders are off.';
      });
    }
  }

  Future<void> _toggleNames(bool value) async {
    final settings = _settings;
    if (settings == null) return;
    final updated = settings.copyWith(showNames: value);
    await _update(updated);
    if (updated.enabled) await _sync(updated);
  }

  Future<void> _sendTest() async {
    final settings = _settings;
    if (settings == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final ok = await _service.sendTest(settings);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = ok
          ? 'Test sent. It should arrive on your phone in about 20 seconds.'
          : 'The test could not be sent. Check your internet and try again.';
    });
  }

  Future<void> _copyTopic(String topic) async {
    await Clipboard.setData(ClipboardData(text: topic));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Topic copied.')),
    );
  }

  Future<void> _openLink(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  // ---------- Screen parts ----------

  Widget _step(int number, Widget content) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.primary,
            child: Text(
              '$number',
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _card({required Widget child, Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: color ?? scheme.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = _settings;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Phone Reminders',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _card(
                  color: scheme.primaryContainer,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Get a notification on your phone at every dose '
                          'time, even when this app is closed.',
                          style: TextStyle(color: scheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set up (one time)',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      _step(
                        1,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Install the free "ntfy" app on your phone '
                              '(Android or iPhone).',
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => _openLink(
                                'https://docs.ntfy.sh/subscribe/phone/',
                              ),
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Get the ntfy app'),
                            ),
                          ],
                        ),
                      ),
                      _step(
                        2,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'In ntfy, tap + and subscribe to this topic '
                              '(keep the server as ntfy.sh):',
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.only(left: 12),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      settings.topic,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    tooltip: 'Copy topic',
                                    onPressed: () => _copyTopic(settings.topic),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () => _openLink(
                                'ntfy://ntfy.sh/${settings.topic}',
                              ),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open in the ntfy app'),
                            ),
                          ],
                        ),
                      ),
                      _step(
                        3,
                        const Text(
                          'Turn on phone reminders below, then press '
                          '"Send test notification".',
                        ),
                      ),
                    ],
                  ),
                ),
                _card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Phone reminders'),
                        value: settings.enabled,
                        onChanged: _busy ? null : _toggleEnabled,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show medicine names'),
                        subtitle: const Text(
                          'Turn off to get a plain "time for your medicine" '
                          'message.',
                        ),
                        value: settings.showNames,
                        onChanged: _busy ? null : _toggleNames,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _sendTest,
                          icon: const Icon(Icons.notifications_outlined),
                          label: const Text('Send test notification'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_busy || !settings.enabled)
                              ? null
                              : () => _sync(settings),
                          icon: const Icon(Icons.sync),
                          label: const Text('Update reminders now'),
                        ),
                      ),
                      if (_busy) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(_message!),
                      ],
                    ],
                  ),
                ),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Good to know',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '- Reminders are scheduled 3 days ahead. Open this app '
                        'at least once every 2 days. It refreshes them '
                        'automatically.\n'
                        '- When you mark a dose Taken or Skipped, its '
                        'reminder is cancelled.\n'
                        '- Reminders travel through the free ntfy.sh service. '
                        'Anyone who knows your topic name could read them, so '
                        'do not share it. Turn off "Show medicine names" if '
                        'you prefer more privacy.\n'
                        '- Your medicines stay saved in this browser on this '
                        'phone only.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
