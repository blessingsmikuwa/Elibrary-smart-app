import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/welcome_banner.dart';
import '../widgets/stats_section.dart';
import '../widgets/progress_section.dart';
import 'books_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = ['Home', 'Books', 'Quizzes', 'Past Papers', 'Settings'];

  final List<Widget> _screens = [
    SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          WelcomeBanner(),
          const SizedBox(height: 16),
          StatsSection(),
          const SizedBox(height: 16),
          ProgressSection(),
        ],
      ),
    ),
    const BooksScreen(),
    const Center(child: Text("📝 Quizzes")),
    const Center(child: Text("📄 Past Papers")),
    const Center(child: Text("⚙️ Settings")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(_titles[_selectedIndex]),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Books'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), label: 'Quizzes'),
          NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Papers'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
