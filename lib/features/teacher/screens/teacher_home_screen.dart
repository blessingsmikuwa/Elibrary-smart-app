import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Welcome Teacher!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'You are logged in as a teacher',
              style: TextStyle(fontSize: 16, color: AppColors.text2),
            ),
          ],
        ),
      ),
    );
  }
}
