import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import 'books_screen.dart';
import 'past_papers_screen.dart';
import 'quizzes_screen.dart';
import 'settings_screen.dart';

// ─── Colours ──────────────────────────────────────────────────────────────────

const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _border  = Color(0xFF21262D);
const _primary = Color(0xFF2EA043);
const _text    = Color(0xFFE6EDF3);
const _muted   = Color(0xFF8B949E);
const _subtle  = Color(0xFF6E7681);
const _red     = Color(0xFFDA3633);
const _yellow  = Color(0xFFE3B341);

const Map<String, Color> _subjectColors = {
  'Biology':          Color(0xFF2EA043),
  'Mathematics':      Color(0xFF1F6FEB),
  'Chemistry':        Color(0xFFA371F7),
  'Physics':          Color(0xFFF0883E),
  'English':          Color(0xFFE3B341),
  'Geography':        Color(0xFF58A6FF),
  'History':          Color(0xFFDA3633),
  'Civic Education':  Color(0xFF56D364),
  'Computer Studies': Color(0xFF79C0FF),
  'Agriculture':      Color(0xFF2EA043),
  'Business Studies': Color(0xFFF0883E),
  'Chichewa':         Color(0xFFE3B341),
};

// ─── Models ───────────────────────────────────────────────────────────────────

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

  factory _DashboardStats.fromJson(Map<String, dynamic> json) => _DashboardStats(
    downloads:    json['downloads']?.toString()    ?? '—',
    quizzesCount: json['quizzesCount']?.toString() ?? '—',
    pastPapers:   json['pastPapers']?.toString()   ?? '—',
    averageScore: json['averageScore'] != null ? '${json['averageScore']}%' : '—',
  );

  static const empty = _DashboardStats(
    downloads: '—', quizzesCount: '—', pastPapers: '—', averageScore: '—',
  );
}

class _ActivityItem {
  final String text;
  final String time;
  final Color  dot;

  const _ActivityItem({required this.text, required this.time, required this.dot});

  factory _ActivityItem.fromJson(Map<String, dynamic> json) {
    final action        = json['action']        as String? ?? '';
    final createdAt     = json['createdAt']     as String?;
    final resourceTitle = json['resourceTitle'] as String? ?? 'a resource';
    final meta          = json['metadata']      as Map<String, dynamic>? ?? {};

    String text;
    Color  dot;

    switch (action) {
      case 'DOWNLOAD':
        text = 'Downloaded "$resourceTitle"';
        dot  = const Color(0xFF2EA043);
        break;
      case 'RESOURCE_VIEWED':
        text = 'Viewed "$resourceTitle"';
        dot  = const Color(0xFF388BFD);
        break;
      case 'QUIZ_COMPLETED':
        final subject = meta['subject']    ?? '';
        final topic   = meta['topic']      ?? '';
        final pct     = meta['percentage'] ?? 0;
        text = 'Completed $subject quiz — $topic ($pct%)';
        dot  = const Color(0xFFF0883E);
        break;
      default:
        text = 'Activity recorded';
        dot  = const Color(0xFF6E7681);
    }

    String formattedTime = '—';
    if (createdAt != null) {
      try {
        final dt  = DateTime.parse(createdAt).toLocal();
        const mon = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        formattedTime = '${dt.day} ${mon[dt.month]}, '
            '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      } catch (_) {}
    }

    return _ActivityItem(text: text, time: formattedTime, dot: dot);
  }
}

class _QuizAttempt {
  final String  subject;
  final String? topic;
  final int     percentage;

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
  @override State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _selectedIndex = 0;

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
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
          NavigationDestination(icon: Icon(Icons.dashboard_outlined),     selectedIcon: Icon(Icons.dashboard_rounded),     label: 'Home'),
          NavigationDestination(icon: Icon(Icons.local_library_outlined), selectedIcon: Icon(Icons.local_library_rounded), label: 'Books'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined),    selectedIcon: Icon(Icons.assignment_rounded),    label: 'Papers'),
          NavigationDestination(icon: Icon(Icons.edit_note_outlined),     selectedIcon: Icon(Icons.edit_note_rounded),     label: 'Quizzes'),
          NavigationDestination(icon: Icon(Icons.settings_outlined),      selectedIcon: Icon(Icons.settings_rounded),      label: 'Settings'),
        ],
      ),
    );
  }
}

// ─── Dashboard ────────────────────────────────────────────────────────────────

class _StudentDashboard extends StatefulWidget {
  final ValueChanged<int> onTabSelected;
  const _StudentDashboard({required this.onTabSelected});
  @override State<_StudentDashboard> createState() => _StudentDashboardState();
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
      if (results[1].statusCode < 300) {
        _stats = _DashboardStats.fromJson(
            jsonDecode(results[1].body) as Map<String, dynamic>);
      }
      if (results[2].statusCode < 300) {
        _activity = (jsonDecode(results[2].body) as List)
            .take(10)
            .map((e) => _ActivityItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (results[3].statusCode < 300) {
        _attempts = (jsonDecode(results[3].body) as List)
            .map((e) => _QuizAttempt.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
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
                  if (_error != null) _ErrorBanner(message: _error!),

                  // ── Welcome banner ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome back, $_firstName!',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800)),
                      if (_schoolName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_schoolName,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 15)),
                      ],
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // ── Stats grid ─────────────────────────────────────────
                  _StatsGrid(stats: _stats),

                  const SizedBox(height: 28),

                  // ── Quick Access + Progress ────────────────────────────
                  LayoutBuilder(builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 700;
                    final quickAccess = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(
                            icon: Icons.menu_book_rounded,
                            label: 'Quick Access'),
                        const SizedBox(height: 14),
                        _QuickAccessGrid(
                            onTabSelected: widget.onTabSelected,
                            context: context),
                      ],
                    );
                    final progressWidget = _ProgressWidget(
                      attempts: _attempts,
                      onGoToQuizzes: () => widget.onTabSelected(3),
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: quickAccess),
                          const SizedBox(width: 20),
                          Expanded(flex: 1, child: Column(children: [
                            const SizedBox(height: 38),
                            progressWidget,
                          ])),
                        ],
                      );
                    }
                    return Column(children: [
                      quickAccess,
                      const SizedBox(height: 28),
                      const _SectionHeader(
                          icon: Icons.bar_chart_rounded,
                          label: 'My Progress'),
                      const SizedBox(height: 14),
                      progressWidget,
                    ]);
                  }),

                  const SizedBox(height: 28),

                  // ── Recent Activity ────────────────────────────────────
                  const _SectionHeader(
                      icon: Icons.schedule_rounded,
                      label: 'Recent Activity'),
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

class _ProgressWidget extends StatefulWidget {
  final List<_QuizAttempt> attempts;
  final VoidCallback        onGoToQuizzes;
  const _ProgressWidget({required this.attempts, required this.onGoToQuizzes});
  @override State<_ProgressWidget> createState() => _ProgressWidgetState();
}

class _ProgressWidgetState extends State<_ProgressWidget> {
  @override
  Widget build(BuildContext context) {
    final attempts = widget.attempts;

    if (attempts.isEmpty) {
      return _DashCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📊 My Progress',
            style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Take some quizzes to see your progress here!',
            style: TextStyle(color: _subtle, fontSize: 13)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: widget.onGoToQuizzes,
          child: const Text('Go to Quizzes →',
              style: TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ]));
    }

    final bySubject = <String, List<_QuizAttempt>>{};
    for (final a in attempts) {
      bySubject.putIfAbsent(a.subject, () => []).add(a);
    }
    final subjects   = bySubject.keys.toList();
    final overallAvg = (attempts.fold(0, (s, a) => s + a.percentage) /
            attempts.length)
        .round();

    String? trending;
    int     trendDiff = 0;
    for (final sub in subjects) {
      final sa = bySubject[sub]!;
      if (sa.length >= 2) {
        final diff = sa[0].percentage - sa[1].percentage;
        if (trending == null || diff > trendDiff) {
          trending  = sub;
          trendDiff = diff;
        }
      }
    }

    return _DashCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('📊 My Progress',
            style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
        GestureDetector(
          onTap: widget.onGoToQuizzes,
          child: const Text('View all →',
              style: TextStyle(color: _primary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),

      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Overall Average', style: TextStyle(color: _subtle, fontSize: 11)),
            Text('$overallAvg%',
                style: const TextStyle(color: _primary, fontSize: 26, fontWeight: FontWeight.w800)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${attempts.length} quizzes',
                style: const TextStyle(color: _subtle, fontSize: 11)),
            if (trending != null && trendDiff > 0) ...[
              const SizedBox(height: 4),
              Text('↑ $trending', style: const TextStyle(color: _primary, fontSize: 11)),
            ],
          ]),
        ]),
      ),
      const SizedBox(height: 8),
      _ProgressBar(value: overallAvg),
      const SizedBox(height: 16),

      ...subjects.take(5).map((sub) {
        final subAttempts = bySubject[sub]!;
        final avg = (subAttempts.fold(0, (s, a) => s + a.percentage) /
                subAttempts.length)
            .round();
        final color = _subjectColors[sub] ?? _primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _showSubjectDetail(context, sub, bySubject[sub]!),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(sub,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                Text('$avg%', style: const TextStyle(color: _muted, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              _ProgressBar(value: avg, color: color),
            ]),
          ),
        );
      }),

      if (subjects.length > 5) ...[
        const SizedBox(height: 4),
        GestureDetector(
          onTap: widget.onGoToQuizzes,
          child: Text('+${subjects.length - 5} more subjects →',
              style: const TextStyle(color: _subtle, fontSize: 12)),
        ),
      ],
    ]));
  }

  void _showSubjectDetail(
      BuildContext context, String subject, List<_QuizAttempt> attempts) {
    final color   = _subjectColors[subject] ?? _primary;
    final avg     = (attempts.fold(0, (s, a) => s + a.percentage) /
            attempts.length)
        .round();
    final best =
        attempts.map((a) => a.percentage).reduce((a, b) => a > b ? a : b);
    final byTopic = <String, List<_QuizAttempt>>{};
    for (final a in attempts) {
      byTopic.putIfAbsent(a.topic ?? 'Unknown', () => []).add(a);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize:     0.4,
        maxChildSize:     0.92,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: _border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(subject,
                    style: TextStyle(
                        color: color, fontSize: 18, fontWeight: FontWeight.w800)),
                Text('${attempts.length} attempts · Avg $avg% · Best $best%',
                    style: const TextStyle(color: _subtle, fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Overall average',
                  style: TextStyle(color: _subtle, fontSize: 12)),
              Text('$avg%',
                  style: const TextStyle(
                      color: _text, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            _ProgressBar(value: avg, color: color, height: 8),
            const SizedBox(height: 20),
            if (attempts.length > 1) ...[
              const Text('Score History',
                  style: TextStyle(
                      color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: attempts.take(12).toList().reversed.toList().reversed.map((a) {
                    final barH = ((a.percentage / 100) * 56).clamp(4.0, 56.0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Tooltip(
                          message:
                              '${a.percentage}%${a.topic != null ? "\n${a.topic}" : ""}',
                          child: Container(
                            height: barH,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text('Topic Breakdown',
                style: TextStyle(
                    color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...byTopic.entries.map((e) {
              final tAvg = (e.value.fold(0, (s, a) => s + a.percentage) /
                      e.value.length)
                  .round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                        child: Text(e.key,
                            style: const TextStyle(color: _text, fontSize: 12),
                            overflow: TextOverflow.ellipsis)),
                    Text('$tAvg% · ${e.value.length}×',
                        style: const TextStyle(color: _muted, fontSize: 11)),
                  ]),
                  const SizedBox(height: 4),
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
  final int    value;
  final Color  color;
  final double height;
  const _ProgressBar(
      {required this.value, this.color = _primary, this.height = 6});
  @override State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double _width = 0;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 120),
        () { if (mounted) setState(() => _width = widget.value.toDouble()); });
  }

  Color get _barColor {
    if (widget.value >= 75) return widget.color;
    if (widget.value >= 50) return _yellow;
    return _red;
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _width / 100,
          backgroundColor: _border,
          valueColor: AlwaysStoppedAnimation<Color>(_barColor),
          minHeight: widget.height,
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _SectionHeader({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: _text, size: 22),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: _text, fontSize: 20, fontWeight: FontWeight.w800)),
      ]);
}

class _DashCard extends StatelessWidget {
  final Widget             child;
  final EdgeInsetsGeometry padding;
  final VoidCallback?      onTap;
  const _DashCard(
      {required this.child,
      this.padding = const EdgeInsets.all(18),
      this.onTap});

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
          onTap: onTap, borderRadius: BorderRadius.circular(8), child: card),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF3D1F1F),
          border: Border.all(color: const Color(0xFFF85149)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(message,
            style: const TextStyle(color: Color(0xFFF85149), fontSize: 13)),
      );
}

// ─── Stats grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final _DashboardStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (stats.downloads,    'Downloads'),
      (stats.quizzesCount, 'Quizzes Completed'),
      (stats.pastPapers,   'Resources Viewed'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth >= 720 ? 3 : 2;
      return GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: cols == 3 ? 1.55 : 1.25,
        ),
        itemBuilder: (context, i) => _DashCard(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:  MainAxisAlignment.center,
          children: [
            Text(items[i].$1,
                style: const TextStyle(
                    color: _primary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(items[i].$2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _subtle, fontSize: 13)),
          ],
        )),
      );
    });
  }
}

// ─── Quick access grid ────────────────────────────────────────────────────────

class _QuickAccessGrid extends StatelessWidget {
  final ValueChanged<int> onTabSelected;
  final BuildContext      context;
  const _QuickAccessGrid(
      {required this.onTabSelected, required this.context});

  @override
  Widget build(BuildContext outerCtx) {
    // tabIdx 3 = Quizzes tab; testsTabIdx 3 = Structured Tests inside QuizzesScreen
    final items = [
      (Icons.local_library_rounded, 'Books Library',   'Browse textbooks and novels',        1, false),
      (Icons.assignment_rounded,    'Past Papers',      'Access exam papers',                 2, false),
      (Icons.edit_note_rounded,     'Practice Quizzes', 'Test your knowledge',                3, false),
      (Icons.fact_check_rounded,    'Structured Tests', 'Timed tests from your teacher',      3, true ),
      // ↑ tabIdx 3 navigates to Quizzes tab, isTests=true then jumps to inner tab 3
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth >= 560 ? 2 : 1;
      return GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: cols == 1 ? 2.8 : 1.15,
        ),
        itemBuilder: (_, i) {
          final (icon, title, desc, tabIdx, isTests) = items[i];
          return _DashCard(
            padding: EdgeInsets.zero,
            onTap: () {
              // Always go to Quizzes tab first
              onTabSelected(tabIdx);
              // If it's Structured Tests, jump to inner tab 3 after nav
              if (isTests) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  QuizzesScreen.jumpToTab(3);
                });
              }
            },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isTests
                        ? const Color(0xFF1A3A2A) // green-tinted bg
                        : _bg,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                  ),
                  child: Icon(icon,
                      color: isTests ? _primary : _text,
                      size: 34),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: isTests ? _primary : _text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 5),
                  Text(desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _subtle, fontSize: 13)),
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
    if (activity.isEmpty) {
      return _DashCard(
          child: const Center(
        child: Text(
          'No activity yet. Start by downloading a resource or taking a quiz!',
          textAlign: TextAlign.center,
          style: TextStyle(color: _subtle, fontSize: 13),
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
                  ? const Border(bottom: BorderSide(color: _border))
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                      color: activity[i].dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  Text(activity[i].text,
                      style: const TextStyle(color: _muted, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(activity[i].time,
                      style: const TextStyle(color: _subtle, fontSize: 12)),
                ])),
              ]),
            ),
          ),
      ]),
    );
  }
}