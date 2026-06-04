import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../screens/settings_screen.dart';

class StudentDrawer extends StatelessWidget {
  const StudentDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Drawer(
      backgroundColor: t.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: t.surface),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: t.primary),
                const SizedBox(width: 10),
                Text(
                  'EduLib Malawi',
                  style: TextStyle(color: t.text, fontSize: 18),
                ),
              ],
            ),
          ),
          _drawerItem(context, 'Home',       Icons.home_rounded,       t),
          _drawerItem(context, 'Resources',  Icons.library_books_rounded, t),
          _drawerItem(context, 'Quizzes',    Icons.quiz_rounded,       t),
          _drawerItem(context, 'Past Papers',Icons.history_edu_rounded, t),
          const Spacer(),
          _drawerItem(
            context, 'Settings', Icons.settings_rounded, t,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          _drawerItem(
            context, 'Logout', Icons.logout_rounded, t,
            color: t.danger,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    String text,
    IconData icon,
    AppThemeData t, {
    Color? color,
    VoidCallback? onTap,
  }) {
    final c = color ?? t.text;
    return ListTile(
      leading: Icon(icon, color: c, size: 20),
      title: Text(text, style: TextStyle(color: c, fontSize: 15)),
      onTap: onTap,
    );
  }
}