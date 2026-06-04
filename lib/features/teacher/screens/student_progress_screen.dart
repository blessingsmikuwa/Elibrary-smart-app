import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';

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
};

class _Attempt {
  final String   id;
  final int      studentId;
  final String   studentName;
  final String   school;
  final String   subject;
  final String?  topic;
  final int      score;
  final int      total;
  final int      percentage;
  final String   source;
  final DateTime completedAt;

  _Attempt({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.school,
    required this.subject,
    this.topic,
    required this.score,
    required this.total,
    required this.percentage,
    required this.source,
    required this.completedAt,
  });

  factory _Attempt.fromJson(Map<String, dynamic> j) {
    final student   = j['student'] as Map<String, dynamic>?;
    final first     = student?['firstName'] as String? ?? '';
    final last      = student?['lastName']  as String? ?? '';
    final name      = '$first $last'.trim();
    final schoolMap = student?['school'] as Map<String, dynamic>?;
    final school    = schoolMap?['name'] as String? ?? '—';
    return _Attempt(
      id:          j['id']?.toString() ?? '',
      studentId:   (j['studentId'] as num?)?.toInt() ?? 0,
      studentName: name.isEmpty ? 'Student #${j['studentId']}' : name,
      school:      school,
      subject:     j['subject']  as String? ?? '',
      topic:       j['topic']    as String?,
      score:       (j['score']   as num?)?.toInt() ?? 0,
      total:       (j['total']   as num?)?.toInt() ?? 10,
      percentage:  (j['percentage'] as num?)?.toInt() ?? 0,
      source:      j['source']   as String? ?? '',
      completedAt: DateTime.tryParse(j['completedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class _StudentRow {
  final int    id;
  final String name;
  final String school;
  final List<_Attempt> attempts;

  _StudentRow({
    required this.id,
    required this.name,
    required this.school,
    required this.attempts,
  });

  int get avg => attempts.isEmpty
      ? 0
      : (attempts.map((a) => a.percentage).reduce((a, b) => a + b) /
              attempts.length)
          .round();

  DateTime get latest => attempts.isEmpty
      ? DateTime(2000)
      : attempts
          .map((a) => a.completedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);

  Map<String, List<_Attempt>> get bySubject {
    final map = <String, List<_Attempt>>{};
    for (final a in attempts) {
      map.putIfAbsent(a.subject, () => []).add(a);
    }
    return map;
  }
}

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});
  @override
  State<StudentProgressScreen> createState() =>
      _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  List<_Attempt> _attempts = [];
  bool           _loading  = true;
  String?        _error;
  String         _search   = '';
  String         _sortBy   = 'recent';
  int?           _expandedId;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async =>
      (await SharedPreferences.getInstance()).getString('accessToken');

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _error   = 'Not authenticated. Please log in again.';
          _loading = false;
        });
        return;
      }
      final res = await http
          .get(
            Uri.parse('$kApiBase/quizzes/teacher/attempts'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode < 300) {
        final List raw      = jsonDecode(res.body) as List;
        final attempts = <_Attempt>[];
        for (final item in raw) {
          try {
            attempts.add(_Attempt.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            debugPrint('Parse error: $e');
          }
        }
        setState(() { _attempts = attempts; _loading = false; });
      } else {
        setState(() {
          _error   = 'Server error ${res.statusCode}\n${res.body}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Map<int, _StudentRow> get _byStudent {
    final map = <int, _StudentRow>{};
    for (final a in _attempts) {
      if (!map.containsKey(a.studentId)) {
        map[a.studentId] = _StudentRow(
            id: a.studentId,
            name: a.studentName,
            school: a.school,
            attempts: []);
      }
      map[a.studentId]!.attempts.add(a);
    }
    return map;
  }

  List<_StudentRow> get _students {
    var list = _byStudent.values.toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              s.school.toLowerCase().contains(q))
          .toList();
    }
    switch (_sortBy) {
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
      case 'score':
        list.sort((a, b) => b.avg.compareTo(a.avg));
      default:
        list.sort((a, b) => b.latest.compareTo(a.latest));
    }
    return list;
  }

  int get _totalAttempts  => _attempts.length;
  int get _uniqueStudents => _byStudent.length;
  int get _avgScore => _totalAttempts == 0
      ? 0
      : (_attempts.map((a) => a.percentage).reduce((a, b) => a + b) /
              _totalAttempts)
          .round();

  Map<String, ({int total, int sum})> get _subjectStats {
    final map = <String, ({int total, int sum})>{};
    for (final a in _attempts) {
      if (a.subject.isEmpty) continue;
      final prev = map[a.subject] ?? (total: 0, sum: 0);
      map[a.subject] =
          (total: prev.total + 1, sum: prev.sum + a.percentage);
    }
    return map;
  }

  Color _scoreColor(AppThemeData t, int pct) =>
      pct >= 75 ? t.greenAccent : pct >= 50 ? t.amberText : t.redText;

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]}, $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        title: Text('Student Progress',
            style: TextStyle(
                color: t.text, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: t.text),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh, color: t.muted),
              onPressed: _load),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: t.surface2),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: t.primary))
          : _error != null
              ? _buildError(t)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: t.primary,
                  backgroundColor: t.surface,
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildSummaryStats(t),
                          const SizedBox(height: 16),
                          if (_subjectStats.isNotEmpty) ...[
                            _buildSubjectBreakdown(t),
                            const SizedBox(height: 16),
                          ],
                          _buildSearchSort(t),
                          const SizedBox(height: 8),
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${_students.length} student${_students.length != 1 ? "s" : ""} found',
                              style: TextStyle(
                                  color: t.subtle, fontSize: 11),
                            ),
                          ),
                          if (_attempts.isEmpty)
                            _buildEmpty(t)
                          else if (_students.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 32),
                              child: Center(
                                  child: Text(
                                'No students match the filter.',
                                style: TextStyle(color: t.subtle),
                              )),
                            )
                          else
                            ..._students.map(
                                (s) => _buildStudentCard(t, s)),
                          const SizedBox(height: 32),
                        ]),
                  ),
                ),
    );
  }

  Widget _buildSummaryStats(AppThemeData t) {
    final stats = [
      (icon: '👥', label: 'Students Attempted', value: '$_uniqueStudents'),
      (icon: '📊', label: 'Class Average',       value: '$_avgScore%'),
      (icon: '📝', label: 'Total Attempts',      value: '$_totalAttempts'),
      (icon: '✏️', label: 'Quizzes Created',     value: '—'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: stats
          .map((s) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.surface,
                  border: Border.all(color: t.surface2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.icon,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(s.value,
                          style: TextStyle(
                              color: t.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text(s.label,
                          style: TextStyle(
                              color: t.subtle, fontSize: 10)),
                    ]),
              ))
          .toList(),
    );
  }

  Widget _buildSubjectBreakdown(AppThemeData t) {
    final sorted = _subjectStats.entries.toList()
      ..sort((a, b) {
        final avgA = a.value.sum / a.value.total;
        final avgB = b.value.sum / b.value.total;
        return avgB.compareTo(avgA);
      });
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.surface2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class Performance by Subject',
                style: TextStyle(
                    color: t.muted,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            const SizedBox(height: 14),
            ...sorted.map((e) {
              final avg   = (e.value.sum / e.value.total).round();
              final color = _subjectColors[e.key] ?? t.muted;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(e.key,
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12))),
                        Text(
                            '${e.value.total} attempt${e.value.total != 1 ? "s" : ""} · ',
                            style: TextStyle(
                                color: t.subtle, fontSize: 11)),
                        Text('$avg% avg',
                            style: TextStyle(
                                color: t.text,
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ]),
                      const SizedBox(height: 4),
                      _AnimProgressBar(
                          value: avg / 100, color: color),
                    ]),
              );
            }),
          ]),
    );
  }

  Widget _buildSearchSort(AppThemeData t) => Column(children: [
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _search = v),
          style: TextStyle(color: t.text, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search students or schools...',
            hintStyle: TextStyle(color: t.subtle, fontSize: 13),
            prefixIcon: Icon(Icons.search, color: t.subtle, size: 18),
            suffixIcon: _search.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: t.subtle, size: 16),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                    })
                : null,
            filled: true,
            fillColor: t.surface,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: t.surface2)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: t.primary)),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text('Sort: ',
              style: TextStyle(color: t.subtle, fontSize: 12)),
          const SizedBox(width: 6),
          ...[
            ('recent', 'Most Recent'),
            ('score', 'Highest Score'),
            ('name', 'Name A–Z'),
          ].map((tab) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _sortBy = tab.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _sortBy == tab.$1
                          ? t.primary
                          : t.surface,
                      border: Border.all(
                          color: _sortBy == tab.$1
                              ? t.primary
                              : t.surface2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tab.$2,
                        style: TextStyle(
                            color: _sortBy == tab.$1
                                ? Colors.white
                                : t.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              )),
        ]),
      ]);

  Widget _buildStudentCard(AppThemeData t, _StudentRow student) {
    final avg        = student.avg;
    final isExpanded = _expandedId == student.id;
    final sorted     = [...student.attempts]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final latest = sorted.isNotEmpty ? sorted.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(
            color: isExpanded ? t.primary : t.surface2),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        InkWell(
          onTap: () => setState(() =>
              _expandedId = isExpanded ? null : student.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                          Text(student.name,
                              style: TextStyle(
                                  color: t.text,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          if (student.school != '—')
                            Text('· ${student.school}',
                                style: TextStyle(
                                    color: t.subtle,
                                    fontSize: 11)),
                        ])),
                    Text(
                      '${student.attempts.length} attempt${student.attempts.length != 1 ? "s" : ""}',
                      style:
                          TextStyle(color: t.subtle, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text('$avg%',
                        style: TextStyle(
                            color: _scoreColor(t, avg),
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const SizedBox(width: 6),
                    Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: t.subtle,
                        size: 18),
                  ]),
                  const SizedBox(height: 8),
                  _AnimProgressBar(
                      value: avg / 100,
                      color: _scoreColor(t, avg)),
                  if (latest != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Last: ${latest.subject}'
                      '${latest.topic != null && latest.topic!.isNotEmpty ? " — ${latest.topic}" : ""}'
                      ' (${latest.percentage}%) · ${_fmtDate(latest.completedAt)}',
                      style: TextStyle(
                          color: t.subtle, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ]),
          ),
        ),
        if (isExpanded) ...[
          Container(height: 1, color: t.surface2),
          Container(
            color: t.bg,
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Subject Breakdown',
                      style: TextStyle(
                          color: t.muted,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.4,
                    children:
                        student.bySubject.entries.map((e) {
                      final subAvg = (e.value
                                  .map((a) => a.percentage)
                                  .reduce((a, b) => a + b) /
                              e.value.length)
                          .round();
                      final color =
                          _subjectColors[e.key] ?? t.muted;
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: t.surface,
                            borderRadius:
                                BorderRadius.circular(6)),
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(e.key,
                                        style: TextStyle(
                                            color: color,
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 11),
                                        overflow: TextOverflow
                                            .ellipsis)),
                                Text('$subAvg%',
                                    style: TextStyle(
                                        color: t.text,
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 11)),
                              ]),
                              const SizedBox(height: 4),
                              _AnimProgressBar(
                                  value: subAvg / 100,
                                  color: color,
                                  height: 4),
                              const SizedBox(height: 2),
                              Text(
                                  '${e.value.length} attempt${e.value.length != 1 ? "s" : ""}',
                                  style: TextStyle(
                                      color: t.subtle,
                                      fontSize: 10)),
                            ]),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text('Recent Attempts',
                      style: TextStyle(
                          color: t.muted,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  ...sorted.take(8).map((a) {
                    final isAI =
                        a.source.toUpperCase() == 'AI';
                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius:
                              BorderRadius.circular(6)),
                      child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Flexible(
                                    child: Text(a.subject,
                                        style: TextStyle(
                                            color: t.text,
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 12),
                                        overflow: TextOverflow
                                            .ellipsis)),
                                const SizedBox(width: 5),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isAI
                                        ? t.blueBg
                                        : t.greenBg,
                                    borderRadius:
                                        BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                      isAI
                                          ? '🤖 AI'
                                          : '👩‍🏫 Teacher',
                                      style: TextStyle(
                                          color: isAI
                                              ? t.blueText
                                              : t.greenAccent,
                                          fontSize: 9)),
                                ),
                              ]),
                              if (a.topic != null &&
                                  a.topic!.isNotEmpty)
                                Text(a.topic!,
                                    style: TextStyle(
                                        color: t.subtle,
                                        fontSize: 11),
                                    overflow:
                                        TextOverflow.ellipsis),
                              Text(
                                  _fmtDate(a.completedAt),
                                  style: TextStyle(
                                      color: t.subtle,
                                      fontSize: 10)),
                            ])),
                        Text(
                            '${a.score}/${a.total} (${a.percentage}%)',
                            style: TextStyle(
                                color: _scoreColor(t, a.percentage),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ]),
                    );
                  }),
                ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildEmpty(AppThemeData t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              const Text('👥', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'No students have attempted your quizzes yet.',
                style: TextStyle(color: t.subtle, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ])),
      );

  Widget _buildError(AppThemeData t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: t.redText, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6))),
              child: const Text('Retry'),
            ),
          ]),
        ),
      );
}

class _AnimProgressBar extends StatefulWidget {
  final double value;
  final Color  color;
  final double height;
  const _AnimProgressBar(
      {required this.value, required this.color, this.height = 6});
  @override
  State<_AnimProgressBar> createState() => _AnimProgressBarState();
}

class _AnimProgressBarState extends State<_AnimProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700));
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 80),
        () { if (mounted) _ctrl.forward(); });
  }

  @override
  void didUpdateWidget(_AnimProgressBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(begin: _anim.value, end: widget.value)
          .animate(
              CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _anim.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius:
                    BorderRadius.circular(widget.height / 2),
              ),
            ),
          ),
        ),
      );
}