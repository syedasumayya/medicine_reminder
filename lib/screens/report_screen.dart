import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/dose_log.dart';
import '../models/medicine.dart';
import '../services/report_builder.dart';
import '../theme/app_theme.dart';

const List<String> _weekdays = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];
const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class ReportScreen extends StatelessWidget {
  final List<Medicine> medicines;
  final List<DoseLog> logs;

  const ReportScreen({
    super.key,
    required this.medicines,
    required this.logs,
  });

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied. You can paste it anywhere.')),
    );
  }

  Future<void> _shareOnWhatsApp(BuildContext context, String text) async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }

  String _dayLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    return '${_weekdays[date.weekday - 1]}, $day ${_months[date.month - 1]}';
  }

  Widget _legendRow(BuildContext context, Color color, String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _statusIcon(BuildContext context, DayStat day) {
    final scheme = Theme.of(context).colorScheme;
    if (day.missed > 0) {
      return const Icon(Icons.error, color: AppColors.danger);
    }
    if (day.taken > 0 && day.skipped == 0) {
      return const Icon(Icons.check_circle, color: AppColors.success);
    }
    return Icon(Icons.remove_circle, color: scheme.outline);
  }

  Widget _dayRow(BuildContext context, DayStat day) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayLabel(day.date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  day.summary,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _statusIcon(context, day),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final report = ReportBuilder.build(
      medicines: medicines,
      logs: logs,
      now: DateTime.now(),
    );
    final shareText = report.toShareText();
    // The report lists newest first; the screen shows oldest first.
    final days = report.days.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Weekly Report',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy',
            onPressed: () => _copy(context, shareText),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => _shareOnWhatsApp(context, shareText),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _RingPainter(
                        taken: report.taken,
                        skipped: report.skipped,
                        missed: report.missed,
                        trackColor: scheme.primaryContainer,
                        skippedColor: scheme.outline,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${report.percent}%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Adherence',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 120,
                child: Column(
                  children: [
                    _legendRow(
                      context,
                      AppColors.success,
                      'Taken',
                      report.taken,
                    ),
                    _legendRow(
                      context,
                      scheme.outline,
                      'Skipped',
                      report.skipped,
                    ),
                    _legendRow(
                      context,
                      AppColors.danger,
                      'Missed',
                      report.missed,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${report.taken} of ${report.total} doses taken',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: scheme.surface,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                  _dayRow(context, days[i]),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _copy(context, shareText),
                  icon: const Icon(Icons.copy),
                  label: const Text(
                    'Copy report',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: () => _shareOnWhatsApp(context, shareText),
                  icon: const Icon(Icons.chat),
                  label: const Text(
                    'Share on WhatsApp',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the ring: green for taken, grey for skipped, red for missed.
class _RingPainter extends CustomPainter {
  final int taken;
  final int skipped;
  final int missed;
  final Color trackColor;
  final Color skippedColor;

  const _RingPainter({
    required this.taken,
    required this.skipped,
    required this.missed,
    required this.trackColor,
    required this.skippedColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // The empty ring behind everything.
    paint.color = trackColor;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);

    final total = taken + skipped + missed;
    if (total == 0) return;

    var start = -math.pi / 2; // start at the top
    void drawPart(int count, Color color) {
      if (count == 0) return;
      final sweep = 2 * math.pi * count / total;
      paint.color = color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }

    drawPart(taken, AppColors.success);
    drawPart(skipped, skippedColor);
    drawPart(missed, AppColors.danger);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.taken != taken ||
        oldDelegate.skipped != skipped ||
        oldDelegate.missed != missed ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.skippedColor != skippedColor;
  }
}
