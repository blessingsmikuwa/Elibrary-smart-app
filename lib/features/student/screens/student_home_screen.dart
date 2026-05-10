import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_theme.dart';
import 'api_service.dart';
import 'books_screen.dart';
import 'past_papers_screen.dart';
import 'quizzes_screen.dart';
import 'settings_screen.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class _DashboardStats {
  final String downloads;
  final String quizzesCount;
  final String pastPapers;
  final String averageScore;

  const _DashboardStats({
    required this.downloads,
    required this.quizzesCount,
    required this.pastPapers,
    required this.averageScore,
  });

  factory _DashboardStats.fromJson(Map<String, dynamic> json) {
    return _DashboardStats(
      downloads:    json['downloads']?.toString()    ?? '—',
      quizzesCount: json['quizzesCount']?.toString() ?? '—',
      pastPapers:   json['pastPapers']?.toString()   ?? '—',
      averageScore: json['averageScore'] != null
          ? '${json['averageScore']}%'
          : '—',
    );
  }

  static const empty = _DashboardStats(
    downloads: '—', quizzesCount: '—', pastPapers: '—', averageScore: '—',
  );
}

class _ActivityItem {
  final String text;
  final String time;
  final Color dot;

  const _ActivityItem({
    required this.text,
    required this.time,
    required this.dot,
  });

  factory _ActivityItem.fromJson(Map<String, dynamic> json) {
    final action = json['action'] as String? ?? '';
    final createdAt = json['createdAt'] as String?;
    final resourceTitle = json['resourceTitle'] as String? ?? 'a resource';
    final meta = json['metadata'] as Map<String, dynamic>? ?? {};

    String text;
    Color dot;

    switch (action) {
      case 'DOWNLOAD':
        text = 'Downloaded "$resourceTitle"';
        dot = const Color(0xFF2EA043);
        break;
      case 'RESOURCE_VIEWED':
        text = 'Viewed "$resourceTitle"';
        dot = const Color(0xFF388BFD);
        break;
      case 'QUIZ_COMPLETED':
        final subject = meta['subject'] ?? '';
        final topic   = meta['topic']   ?? '';
        final pct     = meta['percentage'] ?? 0;
        text = 'Completed $subject quiz — $topic ($pct%)';
        dot = const Color(0xFFF0883E);
        break;
      default:
        text = 'Activity recorded';
        dot = const Color(0xFF6E7681);
    }

    String formattedTime = '—';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        formattedTime =
            '${dt.day} ${_month(dt.month)}, ${_pad(dt.hour)}:${_pad(dt.minute)}';
      } catch (_) {}
    }

    return _ActivityItem(text: text, time: formattedTime, dot: dot);
  }

  static String _month(int m) => const [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m];

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
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

// ─── Dashboard widget (fetches its own data) ──────────────────────────────────

class _StudentDashboard extends StatefulWidget {
  final ValueChanged<int> onTabSelected;
  const _StudentDashboard({required this.onTabSelected});

  @override
  State<_StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<_StudentDashboard> {
  static const _bg      = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);
  static const _primary = Color(0xFF2EA043);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);
  static const _subtle  = Color(0xFF6E7681);

  bool              _loading  = true;
  String?           _error;
  String            _firstName   = 'Student';
  String            _schoolName  = '';
  _DashboardStats   _stats       = _DashboardStats.empty;
  List<_ActivityItem> _activity  = [];

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await authHeaders();

      final results = await Future.wait([
        http.get(Uri.parse('$kApiBase/profiles/me'),       headers: headers),
        http.get(Uri.parse('$kApiBase/activity/me/stats'), headers: headers),
        http.get(Uri.parse('$kApiBase/activity/me'),       headers: headers),
      ]);

      if (!mounted) return;

      // Profile
      if (results[0].statusCode == 200) {
        final profile = jsonDecode(results[0].body) as Map<String, dynamic>;
        _firstName  = profile['firstName']       as String? ?? 'Student';
        _schoolName = (profile['school'] as Map<String, dynamic>?)?['name']
                          as String? ?? '';
      }

      // Stats
      if (results[1].statusCode == 200) {
        _stats = _DashboardStats.fromJson(
          jsonDecode(results[1].body) as Map<String, dynamic>,
        );
      }

      // Activity
      if (results[2].statusCode == 200) {
        final raw = jsonDecode(results[2].body) as List<dynamic>;
        _activity = raw
            .take(10)
            .map((e) => _ActivityItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _error = 'Failed to load dashboard data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: _primary,
        onRefresh: _fetchAll,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null)
                    _ErrorBanner(message: _error!),

                  // Welcome panel
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $_firstName!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_schoolName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _schoolName,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Stats grid
                  _StatsGrid(stats: _stats),

                  const SizedBox(height: 28),

                  // Quick Access header
                  Row(children: [
                    const Icon(Icons.menu_book_rounded, color: _text, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick Access',
                      style: TextStyle(
                        color: _text, fontSize: 20, fontWeight: FontWeight.w800,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 14),

                  _QuickAccessGrid(
                    items: [
                      _QuickItem(
                        title: 'Books Library',
                        description: 'Browse textbooks and novels',
                        icon: Icons.local_library_rounded,
                        onTap: () => widget.onTabSelected(1),
                      ),
                      _QuickItem(
                        title: 'Past Papers',
                        description: 'Access exam papers',
                        icon: Icons.assignment_rounded,
                        onTap: () => widget.onTabSelected(2),
                      ),
                      _QuickItem(
                        title: 'Practice Quizzes',
                        description: 'Test your knowledge',
                        icon: Icons.edit_note_rounded,
                        onTap: () => widget.onTabSelected(3),
                      ),
                      _QuickItem(
                        title: 'Study Materials',
                        description: 'Notes and worksheets',
                        icon: Icons.school_rounded,
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon!')),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Recent Activity header
                  Row(children: [
                    const Icon(Icons.schedule_rounded, color: _text, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        color: _text, fontSize: 20, fontWeight: FontWeight.w800,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 14),

                  _ActivityList(activity: _activity),
                ],
              ),
      ),
    );
  }
}

// ─── Stats grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final _DashboardStats stats;
  const _StatsGrid({required this.stats});

  static const _primary = Color(0xFF2EA043);
  static const _subtle  = Color(0xFF6E7681);

  @override
  Widget build(BuildContext context) {
    final items = [
      (stats.downloads,    'Downloads'),
      (stats.quizzesCount, 'Quizzes Completed'),
      (stats.pastPapers,   'Resources Viewed'),
      (stats.averageScore, 'Average Quiz Score'),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 720 ? 4 : 2;
      return GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: cols == 4 ? 1.55 : 1.25,
        ),
        itemBuilder: (context, i) => _DashCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                items[i].$1,
                style: const TextStyle(
                  color: _primary, fontSize: 26, fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                items[i].$2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _subtle, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Quick access grid ────────────────────────────────────────────────────────

class _QuickItem {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}

class _QuickAccessGrid extends StatelessWidget {
  final List<_QuickItem> items;
  const _QuickAccessGrid({required this.items});

  static const _bg   = Color(0xFF0D1117);
  static const _text = Color(0xFFE6EDF3);
  static const _subtle = Color(0xFF6E7681);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 560
              ? 2
              : 1;
      return GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: cols == 1 ? 2.8 : 1.15,
        ),
        itemBuilder: (context, i) {
          final item = items[i];
          return _DashCard(
            onTap: item.onTap,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    color: _bg,
                    child: Icon(item.icon, color: _text, size: 34),
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
                          color: _text, fontWeight: FontWeight.w700, fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _subtle, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

// ─── Activity list ────────────────────────────────────────────────────────────

class _ActivityList extends StatelessWidget {
  final List<_ActivityItem> activity;
  const _ActivityList({required this.activity});

  static const _subtle = Color(0xFF6E7681);
  static const _muted  = Color(0xFF8B949E);
  static const _border = Color(0xFF21262D);

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return _DashCard(
        child: const Center(
          child: Text(
            'No activity yet. Start by downloading a resource or taking a quiz!',
            textAlign: TextAlign.center,
            style: TextStyle(color: _subtle, fontSize: 13),
          ),
        ),
      );
    }

    return _DashCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < activity.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i != activity.length - 1
                    ? const Border(bottom: BorderSide(color: _border))
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: activity[i].dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity[i].text,
                            style: const TextStyle(color: _muted, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity[i].time,
                            style: const TextStyle(color: _subtle, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _DashCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1F1F),
        border: Border.all(color: const Color(0xFFF85149)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFF85149), fontSize: 13),
      ),
    );
  }
}