import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'About',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          // The logo has dark letters, so it always sits on a white card.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: const Center(child: AppLogo(width: 280)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'v1.0.0',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: scheme.outlineVariant),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.favorite, color: AppColors.danger),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This app is a reminder tool, not a substitute for medical '
                  'advice.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Always follow your doctor's instructions, and check imported "
            'prescriptions by hand.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Center(
              child: Icon(
                Icons.monitor_heart_outlined,
                size: 76,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
