import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../screens/settings_screen.dart';

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.surface),
            child: Row(
              children: const [
                Icon(Icons.menu_book_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'EduLib Malawi',
                  style: TextStyle(color: AppColors.text, fontSize: 18),
                ),
              ],
            ),
          ),
          drawerItem('Home'),
          drawerItem('Resources'),
          drawerItem('Quizzes'),
          drawerItem('Past Papers'),
          const Spacer(),
          drawerItem(
            'Settings',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          drawerItem('Logout', color: AppColors.accent4),
        ],
      ),
    );
  }

  Widget drawerItem(
    String text, {
    Color color = AppColors.text2,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(text, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
