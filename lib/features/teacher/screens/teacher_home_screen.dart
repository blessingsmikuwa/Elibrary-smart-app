import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import 'upload_material_screen.dart';
import 'teaching_materials_screen.dart';
import 'create_quiz_screen.dart';
import 'student_progress_screen.dart';
import 'teacher_profile_screen.dart';
import 'structured_tests_teacher_screen.dart';
import '../../../core/services/api_service.dart';


// ─── Colours ──────────────────────────────────────────────────────────────────

const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _border  = Color(0xFF21262D);
const _primary = Color(0xFF2EA043);
const _green   = Color(0xFF2EA043);
const _text    = Color(0xFFE6EDF3);
const _muted   = Color(0xFF8B949E);
const _subtle  = Color(0xFF6E7681);
const _red     = Color(0xFFDA3633);
const _yellow  = Color(0xFFE3A525);
const _blue    = Color(0xFF58A6FF);

// ─── Models ───────────────────────────────────────────────────────────────────

class _TeacherStats {
  final int    totalStudents;
  final double avgScore;
  const _TeacherStats({required this.totalStudents, required this.avgScore});
  factory _TeacherStats.fromJson(Map<String, dynamic> j) => _TeacherStats(
    totalStudents: (j['totalStudents'] as num?)?.toInt() ?? 0,
    avgScore:      (j['avgScore']      as num?)?.toDouble() ?? 0,
  );
}

class _Resource {
  final String  id;
  final String  title;
  final String? type;
  final String? description;
  final String? fileUrl;
  final int     downloadCount;
  final String? targetClassName;
  const _Resource({
    required this.id, required this.title, this.type,
    this.description, this.fileUrl, required this.downloadCount,
    this.targetClassName,
  });
  factory _Resource.fromJson(Map<String, dynamic> j) => _Resource(
    id:              j['id']?.toString()          ?? '',
    title:           j['title']?.toString()       ?? '',
    type:            j['type']?.toString(),
    description:     j['description']?.toString(),
    fileUrl:         j['fileUrl']?.toString(),
    downloadCount:   (j['downloadCount'] as num?)?.toInt() ?? 0,
    targetClassName: (j['targetClass'] as Map<String, dynamic>?)?['name']?.toString(),
  );
}

class _Quiz {
  final String  id;
  final String  title;
  final String? subject;
  final String? form;
  final DateTime? createdAt;
  const _Quiz({required this.id, required this.title, this.subject, this.form, this.createdAt});
  factory _Quiz.fromJson(Map<String, dynamic> j) {
    DateTime? ca;
    try { if (j['createdAt'] is String) ca = DateTime.parse(j['createdAt']); } catch (_) {}
    return _Quiz(
      id:        j['id']?.toString()      ?? '',
      title:     j['title']?.toString()   ?? '',
      subject:   j['subject']?.toString(),
      form:      j['form']?.toString(),
      createdAt: ca,
    );
  }
  String get formattedDate {
    if (createdAt == null) return '—';
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${createdAt!.day} ${m[createdAt!.month]} ${createdAt!.year}';
  }
}

// ─── Main screen ──────────────────────────────────────────────────────────────

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});
  @override State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;

  void _goTo(int index) => setState(() => _currentIndex = index);

  final List<String> _titles = ['Dashboard','Materials','Create Quiz','Progress','Tests','Profile'];

  Widget _screen() {
    switch (_currentIndex) {
      case 0: return _DashboardContent(onNavigate: _goTo);
      case 1: return TeachingMaterialsScreen();
      case 2: return CreateQuizScreen();
      case 3: return StudentProgressScreen();
      case 4: return const StructuredTestsTeacherScreen();
      case 5: return TeacherProfileScreen();
      default: return _DashboardContent(onNavigate: _goTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: _surface,
        foregroundColor: _text,
      ),
      body: _screen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap:        _goTo,
          backgroundColor:    _surface,
          selectedItemColor:   _primary,
          unselectedItemColor: _muted,
          type:            BottomNavigationBarType.fixed,
          selectedFontSize:   12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard),    activeIcon: Icon(Icons.dashboard,    color: _primary), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.book),         activeIcon: Icon(Icons.book,         color: _primary), label: 'Materials'),
            BottomNavigationBarItem(icon: Icon(Icons.quiz),         activeIcon: Icon(Icons.quiz,         color: _primary), label: 'Create Quiz'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart),    activeIcon: Icon(Icons.bar_chart,    color: _primary), label: 'Progress'),
            BottomNavigationBarItem(icon: Icon(Icons.edit_note),    activeIcon: Icon(Icons.edit_note,    color: _primary), label: 'Tests'),
            BottomNavigationBarItem(icon: Icon(Icons.person),       activeIcon: Icon(Icons.person,       color: _primary), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard content ────────────────────────────────────────────────────────

class _DashboardContent extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const _DashboardContent({required this.onNavigate});
  @override State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  bool            _loading     = true;
  String?         _error;
  String          _firstName   = 'Teacher';
  String          _lastName    = '';
  String          _schoolName  = '';
  _TeacherStats?  _stats;
  List<_Resource> _resources   = [];
  List<_Quiz>     _quizzes     = [];
  String?         _userId;

  @override
  void initState() { super.initState(); _fetchAll(); }

  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await authHeaders();
      final results = await Future.wait([
        http.get(Uri.parse('$kApiBase/profiles/me'),           headers: headers),
        http.get(Uri.parse('$kApiBase/resources'),             headers: headers),
        http.get(Uri.parse('$kApiBase/quizzes/mine'),          headers: headers),
        http.get(Uri.parse('$kApiBase/quizzes/teacher/stats'), headers: headers),
      ]);
      if (!mounted) return;

      if (results[0].statusCode < 300) {
        final p = jsonDecode(results[0].body) as Map<String, dynamic>;
        _firstName  = p['firstName'] as String? ?? 'Teacher';
        _lastName   = p['lastName']  as String? ?? '';
        _schoolName = (p['school'] as Map<String, dynamic>?)?['name'] as String? ?? '';
        _userId     = p['userId']?.toString() ?? p['id']?.toString();
      }

      if (results[1].statusCode < 300) {
        final data = jsonDecode(results[1].body);
        final arr  = data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
        final allRes = arr.map((e) => _Resource.fromJson(e as Map<String, dynamic>)).toList();
        _resources = allRes.where((r) {
          final raw = arr.firstWhere(
            (e) => (e as Map<String, dynamic>)['id']?.toString() == r.id,
            orElse: () => <String, dynamic>{},
          ) as Map<String, dynamic>;
          return _userId == null || raw['uploaderId']?.toString() == _userId;
        }).take(3).toList();
      }

      if (results[2].statusCode < 300) {
        _quizzes = (jsonDecode(results[2].body) as List)
            .map((e) => _Quiz.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (results[3].statusCode < 300) {
        _stats = _TeacherStats.fromJson(jsonDecode(results[3].body) as Map<String, dynamic>);
      }
    } catch (_) {
      _error = 'Failed to load dashboard data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _displayName => '$_firstName $_lastName'.trim();

  // ─── Toast helper ────────────────────────────────────────────────────────────

  void _toast(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _red : _green,
    ));
  }

  // ─── Add Student dialog ──────────────────────────────────────────────────────

  void _showAddStudentDialog(BuildContext context) {
    final firstCtrl = TextEditingController();
    final lastCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl  = TextEditingController();
    bool saving = false;
    DateTime? dob = DateTime(2008, 1, 1);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _border),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('👤 Add Student', style: TextStyle(color: _text,
                    fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: _muted),
                  onPressed: () => Navigator.pop(ctx)),
              ]),
              const Divider(color: _border),
              const SizedBox(height: 4),
              _dialogField('First Name', firstCtrl),
              const SizedBox(height: 10),
              _dialogField('Last Name', lastCtrl),
              const SizedBox(height: 10),
              _dialogField('Email', emailCtrl, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _dialogField('Password', passCtrl, obscure: true),
              const SizedBox(height: 10),
              // Date of birth picker
              const Text('Date of Birth', style: TextStyle(color: _subtle, fontSize: 11)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dob ?? DateTime(2008),
                    firstDate: DateTime(1990),
                    lastDate: DateTime.now(),
                    builder: (c, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(primary: _green),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setS(() => dob = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(color: _bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, color: _muted, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      dob != null
                          ? '${dob!.year}-${dob!.month.toString().padLeft(2,'0')}-${dob!.day.toString().padLeft(2,'0')}'
                          : 'Select date',
                      style: const TextStyle(color: _text, fontSize: 13),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: saving ? null : () async {
                  if (firstCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty
                      || passCtrl.text.trim().isEmpty) {
                    _toast(context, 'First name, email and password are required.', error: true);
                    return;
                  }
                  setS(() => saving = true);
                  try {
                    final h = await authHeaders();
                    final r = await http.post(
                      Uri.parse('$kApiBase/profiles'),
                      headers: h,
                      body: jsonEncode({
                        'firstName':   firstCtrl.text.trim(),
                        'lastName':    lastCtrl.text.trim(),
                        'email':       emailCtrl.text.trim(),
                        'password':    passCtrl.text,
                        'role':        'STUDENT',
                        'dateOfBirth': dob != null
                            ? '${dob!.year}-${dob!.month.toString().padLeft(2,'0')}-${dob!.day.toString().padLeft(2,'0')}'
                            : null,
                      }),
                    );
                    if (r.statusCode < 300) {
                      Navigator.pop(ctx);
                      _toast(context, '${firstCtrl.text} added successfully!');
                    } else {
                      final d = jsonDecode(r.body);
                      _toast(context, d['message']?.toString() ?? 'Failed.', error: true);
                    }
                  } catch (e) {
                    _toast(context, 'Error: $e', error: true);
                  } finally {
                    setS(() => saving = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text(saving ? 'Adding…' : 'Add Student',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── Dialog field helper ─────────────────────────────────────────────────────

  Widget _dialogField(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text, bool obscure = false}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _subtle, fontSize: 11)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: _text, fontSize: 13),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: _subtle),
          filled: true, fillColor: _bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _green, width: 1.5)),
        ),
      ),
    ]);

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _fetchAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) _ErrorBanner(message: _error!),

          // ── Welcome banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Welcome back,',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(_displayName.isEmpty ? 'Teacher' : _displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  if (_schoolName.isNotEmpty)
                    Text('📍 $_schoolName',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _BannerBtn(
                  label: '✏️ Create Quiz',
                  bg: _yellow, fg: Colors.black,
                  onTap: () => widget.onNavigate(2),
                ),
                _BannerBtn(
                  label: '📤 Upload Material',
                  bg: const Color(0xFF21262D), fg: _text,
                  border: _border,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UploadMaterialScreen())),
                ),
                _BannerBtn(
                  label: '👤 Add Student',
                  bg: _blue.withValues(alpha: 0.15), fg: _blue,
                  border: _blue,
                  onTap: () => _showAddStudentDialog(context),
                ),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Stats grid
          _StatsGrid(
            resources: _resources.length,
            quizzes:   _quizzes.length,
            stats:     _stats,
          ),

          const SizedBox(height: 16),

          // ── Student progress banner
          if (_stats != null && _stats!.totalStudents > 0)
            GestureDetector(
              onTap: () => widget.onNavigate(3),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surface, border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('📊 Student Progress Overview',
                        style: TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '${_stats!.totalStudents} student${_stats!.totalStudents != 1 ? "s" : ""} have attempted your quizzes · '
                      'Class avg: ${_stats!.avgScore.toStringAsFixed(1)}%',
                      style: const TextStyle(color: _subtle, fontSize: 12),
                    ),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(6)),
                    child: const Text('View →', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),

          // ── Recent Materials
          _SectionHeader(
            title: '📖 My Recent Materials',
            actionLabel: 'View All',
            onAction: () => widget.onNavigate(1),
          ),
          const SizedBox(height: 12),
          _resources.isEmpty
              ? _EmptyBox(icon: '📭', message: 'No materials uploaded yet.')
              : SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _resources.length,
                    itemBuilder: (_, i) => _ResourceCard(resource: _resources[i]),
                  ),
                ),

          const SizedBox(height: 28),

          // ── Recent Quizzes table
          _SectionHeader(
            title: '📊 My Recent Quizzes',
            actionLabel: '+ Create New',
            onAction: () => widget.onNavigate(2),
          ),
          const SizedBox(height: 12),
          _quizzes.isEmpty
              ? _EmptyBox(icon: '📭', message: 'No quizzes created yet.')
              : _QuizTable(quizzes: _quizzes.take(5).toList(), total: _quizzes.length,
                  onViewAll: () => widget.onNavigate(2)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Stats grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int            resources;
  final int            quizzes;
  final _TeacherStats? stats;
  const _StatsGrid({required this.resources, required this.quizzes, required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (resources.toString(),                              'Materials Uploaded', '📚'),
      (quizzes.toString(),                               'Quizzes Created',    '📝'),
      ((stats?.totalStudents ?? '—').toString(),         'Total Students',     '👥'),
      (stats != null ? '${stats!.avgScore.toStringAsFixed(1)}%' : '—', 'Avg Class Score', '📊'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface, border: Border.all(color: _border), borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(items[i].$1,
              style: const TextStyle(color: _primary, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(items[i].$2,
              style: const TextStyle(color: _subtle, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

// ─── Resource card ────────────────────────────────────────────────────────────

class _ResourceCard extends StatelessWidget {
  final _Resource resource;
  const _ResourceCard({required this.resource});

  static const _typeColors = <String, Color>{
    'LESSON PLAN':  Color(0xFFE3A525),
    'WORKSHEET':    Color(0xFF2EA043),
    'PRESENTATION': Color(0xFFA371F7),
    'PDF':          Color(0xFF58A6FF),
    'VIDEO':        Color(0xFFF0883E),
  };

  Color get _typeColor => _typeColors[resource.type?.toUpperCase()] ?? _muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface, border: Border.all(color: _border), borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _typeColor.withValues(alpha: 0.12),
            border: Border.all(color: _typeColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(resource.type ?? 'FILE',
              style: TextStyle(color: _typeColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 10),
        Text(resource.title,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(children: [
          if (resource.targetClassName != null) ...[
            Text('📅 ${resource.targetClassName}',
                style: const TextStyle(color: _muted, fontSize: 11)),
            const SizedBox(width: 10),
          ],
          Text('⬇️ ${resource.downloadCount}',
              style: const TextStyle(color: _muted, fontSize: 11)),
        ]),
        if (resource.description != null) ...[
          const SizedBox(height: 8),
          Expanded(child: Text(resource.description!,
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _subtle, fontSize: 12, height: 1.4))),
        ] else const Spacer(),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: () { if (resource.fileUrl != null) {} },
            style: ElevatedButton.styleFrom(
              backgroundColor: _red, padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _text, side: const BorderSide(color: _border),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          )),
        ]),
      ]),
    );
  }
}

// ─── Quiz table ───────────────────────────────────────────────────────────────

class _QuizTable extends StatelessWidget {
  final List<_Quiz> quizzes;
  final int         total;
  final VoidCallback onViewAll;
  const _QuizTable({required this.quizzes, required this.total, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface, border: Border.all(color: _border), borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF1A3A2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: const Row(children: [
            Expanded(flex: 3, child: Text('Title',   style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600))),
            Expanded(flex: 2, child: Text('Subject', style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600))),
            Expanded(flex: 1, child: Text('Form',    style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600))),
            Expanded(flex: 2, child: Text('Created', style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600))),
          ]),
        ),
        // Rows
        ...quizzes.asMap().entries.map((e) {
          final i = e.key; final q = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: i.isEven ? _surface : _bg,
              border: i < quizzes.length - 1 ? const Border(bottom: BorderSide(color: _border)) : null,
            ),
            child: Row(children: [
              Expanded(flex: 3, child: Text(q.title, style: const TextStyle(color: _text, fontSize: 13), overflow: TextOverflow.ellipsis)),
              Expanded(flex: 2, child: Text(q.subject ?? '—', style: const TextStyle(color: _muted, fontSize: 12))),
              Expanded(flex: 1, child: Text(q.form    ?? '—', style: const TextStyle(color: _muted, fontSize: 12))),
              Expanded(flex: 2, child: Text(q.formattedDate,   style: const TextStyle(color: _muted, fontSize: 12))),
            ]),
          );
        }),
        // View all footer
        if (total > 5)
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border))),
              alignment: Alignment.center,
              child: Text('View all $total quizzes →',
                  style: const TextStyle(color: _blue, fontSize: 13)),
            ),
          ),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _BannerBtn extends StatelessWidget {
  final String label; final Color bg, fg; final Color? border; final VoidCallback onTap;
  const _BannerBtn({required this.label, required this.bg, required this.fg, required this.onTap, this.border});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: border != null ? Border.all(color: border!) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title, actionLabel; final VoidCallback onAction;
  const _SectionHeader({required this.title, required this.actionLabel, required this.onAction});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w800)),
      GestureDetector(
        onTap: onAction,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _primary, borderRadius: BorderRadius.circular(6),
          ),
          child: Text(actionLabel, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    ],
  );
}

class _EmptyBox extends StatelessWidget {
  final String icon, message;
  const _EmptyBox({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: _surface, border: Border.all(color: _border), borderRadius: BorderRadius.circular(8),
    ),
    child: Column(children: [
      Text(icon, style: const TextStyle(fontSize: 36)),
      const SizedBox(height: 10),
      Text(message, style: const TextStyle(color: _subtle, fontSize: 13)),
    ]),
  );
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
    child: Text(message, style: const TextStyle(color: Color(0xFFF85149), fontSize: 13)),
  );
}