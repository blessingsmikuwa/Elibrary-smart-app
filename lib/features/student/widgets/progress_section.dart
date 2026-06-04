import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProgressSection extends StatelessWidget {
  const ProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Card(
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: t.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Reading Progress',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: t.text)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.7,
              backgroundColor: t.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(t.primary),
            ),
            const SizedBox(height: 8),
            Text('70% completed', style: TextStyle(color: t.muted)),
          ],
        ),
      ),
    );
  }
}