import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import 'books_screen.dart';
import 'past_papers_screen.dart';
import 'quizzes_screen.dart';
import 'settings_screen.dart';

const Map<String, Color> _subjectColors = {
  'Biology':          Color(0xFF10B981),
  'Mathematics':      Color(0xFF3B82F6),
  'Chemistry':        Color(0xFFA78BFA),
  'Physics':          Color(0xFFF97316),
  'English':          Color(0xFFF59E0B),
  'Geography':        Color(0xFF60A5FA),
  'History':          Color(0xFFEF4444),
  'Civic Education':  Color(0xFF34D399),
  'Computer Studies': Color(0xFF93C5FD),
  'Agriculture':      Color(0xFF10B981),
  'Business Studies': Color(0xFFF97316),
  'Chichewa':         Color(0xFFF59E0B),
};

// ─── Models ───────────────────────────────────────────────────────────────────

class _DashboardStats {
  final String downloads, quizzesCount, pastPapers, averageScore;
  const _DashboardStats({
    required this.downloads, required this.quizzesCount,
    required this.pastPapers, required this.averageScore,
  });
  factory _DashboardStats.fromJson(Map<String, dynamic> json) => _DashboardStats(
    downloads:    json['downloads']?.toString()    ?? '—',
    quizzesCount: json['quizzesCount']?.toString() ?? '—',
    pastPapers:   json['pastPapers']?.toString()   ?? '—',
    averageScore: json['averageScore'] != null ? '${json['averageScore']}%' : '—',
  );
  static const empty = _DashboardStats(
      downloads: '—', quizzesCount: '—', pastPapers: '—', averageScore: '—');
}

class _ActivityItem {
  final String text, time;
  final Color  dot;
  const _ActivityItem({required this.text, required this.time, required this.dot});

  factory _ActivityItem.fromJson(Map<String, dynamic> json) {
    final action        = json['action']        as String? ?? '';
    final createdAt     = json['createdAt']     as String?;
    final resourceTitle = json['resourceTitle'] as String? ?? 'a resource';
    final meta          = json['metadata']      as Map<String, dynamic>? ?? {};
    String text; Color dot;
    switch (action) {
      case 'DOWNLOAD':
        text = 'Downloaded "$resourceTitle"'; dot = const Color(0xFF10B981); break;
      case 'RESOURCE_VIEWED':
        text = 'Viewed "$resourceTitle"'; dot = const Color(0xFF3B82F6); break;
      case 'QUIZ_COMPLETED':
        final subject = meta['subject'] ?? ''; final topic = meta['topic'] ?? '';
        final pct = meta['percentage'] ?? 0;
        text = 'Completed $subject quiz — $topic ($pct%)'; dot = const Color(0xFFF97316); break;
      default:
        text = 'Activity recorded'; dot = const Color(0xFF6B7280);
    }
    String formattedTime = '—';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        const mon = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        formattedTime =
            '${dt.day} ${mon[dt.month]}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      } catch (_) {}
    }
    return _ActivityItem(text: text, time: formattedTime, dot: dot);
  }
}

class _QuizAttempt {
  final String subject; final String? topic; final int percentage;
  const _QuizAttempt({required this.subject, this.topic, required this.percentage});
  factory _QuizAttempt.fromJson(Map<String, dynamic> j) => _QuizAttempt(
    subject:    j['subject']?.toString()           ?? '',
    topic:      j['topic']?.toString(),
    percentage: (j['percentage'] as num?)?.toInt() ?? 0,
  );
}

// ─── Main screen ──────────────────────────────────────────────────────────────

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
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
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
        backgroundColor: t.surface,
        indicatorColor: t.primary.withValues(alpha: 0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color:      selected ? t.primary : t.muted,
            fontSize:   12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          );
        }),
        destinations: [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined,        color: t.muted),
              selectedIcon: Icon(Icons.dashboard_rounded,    color: t.primary),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.local_library_outlined,    color: t.muted),
              selectedIcon: Icon(Icons.local_library_rounded, color: t.primary),
              label: 'Books'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined,       color: t.muted),
              selectedIcon: Icon(Icons.assignment_rounded,    color: t.primary),
              label: 'Papers'),
          NavigationDestination(
              icon: Icon(Icons.edit_note_outlined,        color: t.muted),
              selectedIcon: Icon(Icons.edit_note_rounded,     color: t.primary),
              label: 'Quizzes'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined,         color: t.muted),
              selectedIcon: Icon(Icons.settings_rounded,      color: t.primary),
              label: 'Settings'),
        ],
      ),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

class _StudentDashboard extends StatefulWidget {
  final ValueChanged<int> onTabSelected;
  const _StudentDashboard({required this.onTabSelected});
  @override
  State<_StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<_StudentDashboard> {
  bool                _loading    = true;
  String?             _error;
  String              _firstName  = 'Student';
  String              _schoolName = '';
  _DashboardStats     _stats      = _DashboardStats.empty;
  List<_ActivityItem> _activity   = [];
  List<_QuizAttempt>  _attempts   = [];

  @override
  void initState() { super.initState(); _fetchAll(); }

  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await authHeaders();
      final results = await Future.wait([
        http.get(Uri.parse('$kApiBase/profiles/me'),           headers: headers),
        http.get(Uri.parse('$kApiBase/activity/me/stats'),     headers: headers),
        http.get(Uri.parse('$kApiBase/activity/me'),           headers: headers),
        http.get(Uri.parse('$kApiBase/quizzes/attempts/mine'), headers: headers),
      ]);
      if (!mounted) return;
      if (results[0].statusCode < 300) {
        final p = jsonDecode(results[0].body) as Map<String, dynamic>;
        _firstName  = p['firstName'] as String? ?? 'Student';
        _schoolName = (p['school'] as Map<String, dynamic>?)?['name'] as String? ?? '';
      }
      if (results[1].statusCode < 300)
        _stats = _DashboardStats.fromJson(jsonDecode(results[1].body) as Map<String, dynamic>);
      if (results[2].statusCode < 300)
        _activity = (jsonDecode(results[2].body) as List)
            .take(10).map((e) => _ActivityItem.fromJson(e as Map<String, dynamic>)).toList();
      if (results[3].statusCode < 300)
        _attempts = (jsonDecode(results[3].body) as List)
            .map((e) => _QuizAttempt.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _error = 'Failed to load dashboard data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return SafeArea(
      child: RefreshIndicator(
        color: t.primary,
        onRefresh: _fetchAll,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: t.primary))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null) _ErrorBanner(message: _error!),

                  // ── Welcome hero ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF065F46), Color(0xFF047857)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Welcome back, $_firstName!',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        if (_schoolName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(_schoolName,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 15)),
                        ],
                      ])),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.school_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),
                  _StatsGrid(stats: _stats),
                  const SizedBox(height: 28),

                  LayoutBuilder(builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 700;
                    final quickAccess = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(icon: Icons.menu_book_rounded, label: 'Quick Access'),
                        const SizedBox(height: 14),
                        _QuickAccessGrid(onTabSelected: widget.onTabSelected),
                      ],
                    );
                    final progressWidget = _ProgressWidget(
                      attempts: _attempts,
                      onGoToQuizzes: () => widget.onTabSelected(3),
                    );
                    if (wide) {
                      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(flex: 2, child: quickAccess),
                        const SizedBox(width: 20),
                        Expanded(flex: 1, child: Column(children: [
                          const SizedBox(height: 38),
                          progressWidget,
                        ])),
                      ]);
                    }
                    return Column(children: [
                      quickAccess,
                      const SizedBox(height: 28),
                      _SectionHeader(icon: Icons.bar_chart_rounded, label: 'My Progress'),
                      const SizedBox(height: 14),
                      progressWidget,
                    ]);
                  }),

                  const SizedBox(height: 28),
                  _SectionHeader(icon: Icons.schedule_rounded, label: 'Recent Activity'),
                  const SizedBox(height: 14),
                  _ActivityList(activity: _activity),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}

// ─── Progress Widget ──────────────────────────────────────────────────────────

class _ProgressWidget extends StatelessWidget {
  final List<_QuizAttempt> attempts;
  final VoidCallback        onGoToQuizzes;
  const _ProgressWidget({required this.attempts, required this.onGoToQuizzes});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    if (attempts.isEmpty) {
      return _DashCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.bar_chart_rounded, color: t.primary, size: 20),
          const SizedBox(width: 8),
          Text('My Progress',
              style: TextStyle(color: t.text, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Text('Take some quizzes to see your progress here!',
            style: TextStyle(color: t.subtle, fontSize: 14)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onGoToQuizzes,
          child: Text('Go to Quizzes →',
              style: TextStyle(color: t.primary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ]));
    }

    final bySubject  = <String, List<_QuizAttempt>>{};
    for (final a in attempts) bySubject.putIfAbsent(a.subject, () => []).add(a);
    final subjects   = bySubject.keys.toList();
    final overallAvg =
        (attempts.fold(0, (s, a) => s + a.percentage) / attempts.length).round();

    String? trending; int trendDiff = 0;
    for (final sub in subjects) {
      final sa = bySubject[sub]!;
      if (sa.length >= 2) {
        final diff = sa[0].percentage - sa[1].percentage;
        if (trending == null || diff > trendDiff) { trending = sub; trendDiff = diff; }
      }
    }

    return _DashCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.bar_chart_rounded, color: t.primary, size: 20),
          const SizedBox(width: 8),
          Text('My Progress',
              style: TextStyle(color: t.text, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        GestureDetector(
          onTap: onGoToQuizzes,
          child: Text('View all →',
              style: TextStyle(color: t.primary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 14),

      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Overall Average',
                style: TextStyle(color: t.subtle, fontSize: 12)),
            Text('$overallAvg%',
                style: TextStyle(color: t.primary, fontSize: 28,
                    fontWeight: FontWeight.w800)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${attempts.length} quizzes',
                style: TextStyle(color: t.subtle, fontSize: 12)),
            if (trending != null && trendDiff > 0) ...[
              const SizedBox(height: 4),
              Text('↑ $trending',
                  style: TextStyle(color: t.primary, fontSize: 12)),
            ],
          ]),
        ]),
      ),
      const SizedBox(height: 10),
      _ProgressBar(value: overallAvg),
      const SizedBox(height: 18),

      ...subjects.take(5).map((sub) {
        final sa  = bySubject[sub]!;
        final avg = (sa.fold(0, (s, a) => s + a.percentage) / sa.length).round();
        final col = _subjectColors[sub] ?? t.primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _showSubjectDetail(context, sub, sa, t),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(sub,
                    style: TextStyle(color: t.text, fontSize: 13),
                    overflow: TextOverflow.ellipsis)),
                Text('$avg%',
                    style: TextStyle(color: col, fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 5),
              _ProgressBar(value: avg, color: col),
            ]),
          ),
        );
      }),

      if (subjects.length > 5) ...[
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onGoToQuizzes,
          child: Text('+${subjects.length - 5} more subjects →',
              style: TextStyle(color: t.subtle, fontSize: 13)),
        ),
      ],
    ]));
  }

  void _showSubjectDetail(BuildContext context, String subject,
      List<_QuizAttempt> attempts, AppThemeData t) {
    final color  = _subjectColors[subject] ?? t.primary;
    final avg    = (attempts.fold(0, (s, a) => s + a.percentage) / attempts.length).round();
    final best   = attempts.map((a) => a.percentage).reduce((a, b) => a > b ? a : b);
    final byTopic = <String, List<_QuizAttempt>>{};
    for (final a in attempts) byTopic.putIfAbsent(a.topic ?? 'Unknown', () => []).add(a);

    showModalBottomSheet(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.4, maxChildSize: 0.92, expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: t.border,
                  borderRadius: BorderRadius.circular(2)),
            )),
            Text(subject,
                style: TextStyle(color: color, fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text('${attempts.length} attempts · Avg $avg% · Best $best%',
                style: TextStyle(color: t.subtle, fontSize: 13)),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Overall average', style: TextStyle(color: t.subtle, fontSize: 13)),
              Text('$avg%',
                  style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            _ProgressBar(value: avg, color: color, height: 8),
            const SizedBox(height: 22),
            if (attempts.length > 1) ...[
              Text('Score History',
                  style: TextStyle(color: t.muted, fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SizedBox(
                height: 64,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: attempts.take(12).map((a) {
                    final barH = ((a.percentage / 100) * 56).clamp(4.0, 56.0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Tooltip(
                          message: '${a.percentage}%${a.topic != null ? "\n${a.topic}" : ""}',
                          child: Container(
                            height: barH,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 22),
            ],
            Text('Topic Breakdown',
                style: TextStyle(color: t.muted, fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...byTopic.entries.map((e) {
              final tAvg =
                  (e.value.fold(0, (s, a) => s + a.percentage) / e.value.length).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(e.key,
                        style: TextStyle(color: t.text, fontSize: 13),
                        overflow: TextOverflow.ellipsis)),
                    Text('$tAvg% · ${e.value.length}×',
                        style: TextStyle(color: t.muted, fontSize: 12)),
                  ]),
                  const SizedBox(height: 5),
                  _ProgressBar(value: tAvg, color: color),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _ProgressBar extends StatefulWidget {
  final int value; final Color color; final double height;
  const _ProgressBar({required this.value,
      this.color = const Color(0xFF10B981), this.height = 6});
  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double _width = 0;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 120),
        () { if (mounted) setState(() => _width = widget.value.toDouble()); });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final barColor = widget.value >= 75
        ? widget.color
        : widget.value >= 50 ? t.amber : t.danger;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _width / 100,
        backgroundColor: t.border,
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
        minHeight: widget.height,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon; final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: t.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: t.primary, size: 20),
      ),
      const SizedBox(width: 10),
      Text(label,
          style: TextStyle(color: t.text, fontSize: 20, fontWeight: FontWeight.w800)),
    ]);
  }
}

class _DashCard extends StatelessWidget {
  final Widget child; final EdgeInsetsGeometry padding; final VoidCallback? onTap;
  const _DashCard({required this.child,
      this.padding = const EdgeInsets.all(18), this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final card = Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap,
          borderRadius: BorderRadius.circular(16), child: card),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.errorBg,
        border: Border.all(color: t.errorBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: t.danger, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: TextStyle(color: t.danger, fontSize: 14))),
      ]),
    );
  }
}

// ─── Stats grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final _DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final items = [
      (stats.downloads,    'Downloads',         Icons.download_rounded),
      (stats.quizzesCount, 'Quizzes Completed', Icons.edit_note_rounded),
      (stats.pastPapers,   'Resources Viewed',  Icons.visibility_rounded),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 720 ? 3 : 2;
      return GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: cols == 3 ? 1.55 : 1.3,
        ),
        itemBuilder: (context, i) => _DashCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(items[i].$3, color: t.primary, size: 20),
              ),
              const SizedBox(height: 10),
              Text(items[i].$1,
                  style: TextStyle(color: t.primary, fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(items[i].$2,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.subtle, fontSize: 13)),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Quick access grid ────────────────────────────────────────────────────────

class _QuickAccessGrid extends StatelessWidget {
  final ValueChanged<int> onTabSelected;
  const _QuickAccessGrid({required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final items = [
      (Icons.local_library_rounded, 'Books Library',    'Browse textbooks and novels',           1, false),
      (Icons.assignment_rounded,    'Past Papers',       'Access exam papers',                    2, false),
      (Icons.edit_note_rounded,     'Practice Quizzes',  'Test your knowledge',                   3, false),
      (Icons.fact_check_rounded,    'Structured Tests',  'Timed tests from your teacher',         3, true ),
    ];
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth >= 560 ? 2 : 1;
      return GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, crossAxisSpacing: 14, mainAxisSpacing: 14,
          childAspectRatio: cols == 1 ? 2.8 : 1.2,
        ),
        itemBuilder: (_, i) {
          final (icon, title, desc, tabIdx, isTests) = items[i];
          final accentColor = isTests ? t.primary : const Color(0xFF3B82F6);
          return _DashCard(
            padding: EdgeInsets.zero,
            onTap: () {
              onTabSelected(tabIdx);
              if (isTests) {
                Future.delayed(const Duration(milliseconds: 100),
                    () { QuizzesScreen.jumpToTab(3); });
              }
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                  ),
                  child: Icon(icon, color: accentColor, size: 36),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isTests ? t.primary : t.text,
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(desc,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.subtle, fontSize: 13)),
                ]),
              ),
            ]),
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

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    if (activity.isEmpty) {
      return _DashCard(child: Center(
        child: Text(
          'No activity yet. Start by downloading a resource or taking a quiz!',
          textAlign: TextAlign.center,
          style: TextStyle(color: t.subtle, fontSize: 14),
        ),
      ));
    }
    return _DashCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        for (var i = 0; i < activity.length; i++)
          DecoratedBox(
            decoration: BoxDecoration(
              border: i != activity.length - 1
                  ? Border(bottom: BorderSide(color: t.border))
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 9, height: 9,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                      color: activity[i].dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(activity[i].text,
                      style: TextStyle(color: t.muted, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(activity[i].time,
                      style: TextStyle(color: t.subtle, fontSize: 12)),
                ])),
              ]),
            ),
          ),
      ]),
    );
  }
}