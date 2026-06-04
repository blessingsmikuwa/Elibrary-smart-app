import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.heroBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.heroBorder),
      ),
      child: Text(
        'Welcome to the E-Library!',
        style: TextStyle(
          color: t.text,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}