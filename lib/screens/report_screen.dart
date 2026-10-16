import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/dose_log.dart';
import '../models/medicine.dart';
import '../services/report_builder.dart';

class ReportScreen extends StatelessWidget {
  final List<Medicine> medicines;
  final List<DoseLog> logs;

  const ReportScreen({super.key, required this.medicines, required this.logs});

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied. You can paste it anywhere.'),
      ),
    );
  }

  Future<void> _shareOnWhatsApp(BuildContext context, String text) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  IconData _iconFor(DayStat day) {
    if (day.missed > 0) return Icons.warning_amber;
    if (day.skipped > 0) return Icons.remove_circle_outline;
    if (day.taken > 0) return Icons.check_circle;
    return Icons.circle_outlined;
  }

  Color _colorFor(DayStat day) {
    if (day.missed > 0) return Colors.red;
    if (day.skipped == 0 && day.taken > 0) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final report = ReportBuilder.build(
      medicines: medicines,
      logs: logs,
      now: DateTime.now(),
    );
    final shareText = report.toShareText();

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: report.percent / 100,
                          strokeWidth: 10,
                        ),
                        Center(
                          child: Text(
                            '${report.percent}%',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adherence',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text('${report.taken} of ${report.total} doses taken'),
                        const Text('Last 7 days'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatTile(
                label: 'Taken',
                value: report.taken,
                color: Colors.green,
              ),
              _StatTile(
                label: 'Skipped',
                value: report.skipped,
                color: Colors.grey,
              ),
              _StatTile(
                label: 'Missed',
                value: report.missed,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _copy(context, shareText),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy report'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareOnWhatsApp(context, shareText),
                  icon: const Icon(Icons.share),
                  label: const Text('Share on WhatsApp'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Day by day', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          for (final day in report.days)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_iconFor(day), color: _colorFor(day)),
              title: Text(day.label),
              subtitle: Text(day.summary),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                '$value',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: color),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
