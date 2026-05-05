import 'package:flutter/material.dart';

import 'books_screen.dart';
import 'past_papers_screen.dart';
import 'quizzes_screen.dart';
import 'settings_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  static const Color _backgroundColor = Color(0xFF0D1117);
  static const Color _surfaceColor = Color(0xFF161B22);
  static const Color _borderColor = Color(0xFF21262D);
  static const Color _primaryColor = Color(0xFF2EA043);
  static const Color _textColor = Color(0xFFE6EDF3);
  static const Color _mutedTextColor = Color(0xFF8B949E);
  static const Color _subtleTextColor = Color(0xFF6E7681);

  static final _student = _DummyStudent(
    firstName: 'Student',
    schoolName: 'Smart E-Library Secondary School',
  );

  static const List<_DashboardStat> _stats = [
    _DashboardStat(number: '24', label: 'Downloads'),
    _DashboardStat(number: '8', label: 'Quizzes Completed'),
    _DashboardStat(number: '37', label: 'Resources Viewed'),
    _DashboardStat(number: '82%', label: 'Average Quiz Score'),
  ];

  static const List<_RecentActivity> _activities = [
    _RecentActivity(
      text: 'Downloaded "Mathematics Final Exam 2023"',
      time: '2 May, 09:30',
      color: Color(0xFF2EA043),
    ),
    _RecentActivity(
      text: 'Viewed "Biology Mock Paper"',
      time: '1 May, 15:45',
      color: Color(0xFF388BFD),
    ),
    _RecentActivity(
      text: 'Completed Mathematics quiz - Algebra (86%)',
      time: '30 Apr, 11:20',
      color: Color(0xFFF0883E),
    ),
    _RecentActivity(
      text: 'Downloaded "English Grammar Notes"',
      time: '29 Apr, 14:05',
      color: Color(0xFF2EA043),
    ),
  ];

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudentHomeScreen._backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _StudentDashboard(onTabSelected: _selectTab),
          const BooksScreen(),
          const PastPapersScreen(),
          const QuizzesScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_library_outlined),
            selectedIcon: Icon(Icons.local_library_rounded),
            label: 'Books',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Papers',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note_rounded),
            label: 'Quizzes',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _StudentDashboard extends StatelessWidget {
  final ValueChanged<int> onTabSelected;

  const _StudentDashboard({required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _WelcomePanel(student: StudentHomeScreen._student),
          const SizedBox(height: 20),
          const _StatsGrid(stats: StudentHomeScreen._stats),
          const SizedBox(height: 28),
          _SectionTitle(icon: Icons.menu_book_rounded, title: 'Quick Access'),
          const SizedBox(height: 14),
          _QuickAccessGrid(
            items: [
              _QuickAccessItem(
                title: 'Books Library',
                description: 'Browse textbooks and novels',
                icon: Icons.local_library_rounded,
                onTap: () => onTabSelected(1),
              ),
              _QuickAccessItem(
                title: 'Past Papers',
                description: 'Access exam papers',
                icon: Icons.assignment_rounded,
                onTap: () => onTabSelected(2),
              ),
              _QuickAccessItem(
                title: 'Practice Quizzes',
                description: 'Test your knowledge',
                icon: Icons.edit_note_rounded,
                onTap: () => onTabSelected(3),
              ),
              _QuickAccessItem(
                title: 'Study Materials',
                description: 'Notes and worksheets',
                icon: Icons.school_rounded,
                onTap: () => _showComingSoon(context),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SectionTitle(icon: Icons.schedule_rounded, title: 'Recent Activity'),
          const SizedBox(height: 14),
          const _RecentActivityList(activities: StudentHomeScreen._activities),
        ],
      ),
    );
  }

  static void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Study materials will be available soon.')),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  final _DummyStudent student;

  const _WelcomePanel({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: StudentHomeScreen._primaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${student.firstName}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (student.schoolName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              student.schoolName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_DashboardStat> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 4 : 2;

        return GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth >= 720 ? 1.55 : 1.25,
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];

            return _DashboardCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stat.number,
                    style: const TextStyle(
                      color: StudentHomeScreen._primaryColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stat.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: StudentHomeScreen._subtleTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final List<_QuickAccessItem> items;

  const _QuickAccessGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.15,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return _DashboardCard(
              onTap: item.onTap,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      color: StudentHomeScreen._backgroundColor,
                      child: Icon(
                        item.icon,
                        color: StudentHomeScreen._textColor,
                        size: 34,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudentHomeScreen._textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: StudentHomeScreen._subtleTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  final List<_RecentActivity> activities;

  const _RecentActivityList({required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const _DashboardCard(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text(
            'No activity yet. Start by downloading a resource or taking a quiz!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: StudentHomeScreen._subtleTextColor,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return _DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < activities.length; index++)
            _ActivityTile(
              activity: activities[index],
              showDivider: index != activities.length - 1,
            ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final _RecentActivity activity;
  final bool showDivider;

  const _ActivityTile({required this.activity, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: StudentHomeScreen._borderColor),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: activity.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.text,
                    style: const TextStyle(
                      color: StudentHomeScreen._mutedTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.time,
                    style: const TextStyle(
                      color: StudentHomeScreen._subtleTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: StudentHomeScreen._textColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: StudentHomeScreen._textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: StudentHomeScreen._surfaceColor,
        border: Border.all(color: StudentHomeScreen._borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: card,
      ),
    );
  }
}

class _DummyStudent {
  final String firstName;
  final String schoolName;

  const _DummyStudent({required this.firstName, required this.schoolName});
}

class _DashboardStat {
  final String number;
  final String label;

  const _DashboardStat({required this.number, required this.label});
}

class _QuickAccessItem {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}

class _RecentActivity {
  final String text;
  final String time;
  final Color color;

  const _RecentActivity({
    required this.text,
    required this.time,
    required this.color,
  });
}
