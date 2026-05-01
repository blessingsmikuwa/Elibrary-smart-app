import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

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
                Text("📚", style: TextStyle(fontSize: 28)),
                SizedBox(width: 10),
                Text(
                  "EduLib Malawi",
                  style: TextStyle(color: AppColors.text, fontSize: 18),
                ),
              ],
            ),
          ),

          drawerItem("🏠 Home"),
          drawerItem("📖 Resources"),
          drawerItem("📝 Quizzes"),
          drawerItem("� Past Papers"),

          const Spacer(),

          drawerItem("⚙️ Settings"),
          drawerItem("🚪 Logout", color: AppColors.accent4),
        ],
      ),
    );
  }

  Widget drawerItem(String text, {Color color = AppColors.text2}) {
    return ListTile(
      title: Text(text, style: TextStyle(color: color)),
      onTap: () {},
    );
  }
}
