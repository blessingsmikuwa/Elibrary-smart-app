
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart'; // kApiBase, authHeaders()

// ─── Theme constants (matches quizzes.dart palette) ──────────────────────────
const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _border  = Color(0xFF21262D);
const _border2 = Color(0xFF30363D);
const _text    = Color(0xFFE6EDF3);
const _muted   = Color(0xFF8B949E);
const _subtle  = Color(0xFF6E7681);
const _green   = Color(0xFF2EA043);
const _greenL  = Color(0xFF3FB950);
const _greenBg = Color(0xFF1A3A2A);
const _blue    = Color(0xFF58A6FF);
const _blueBg  = Color(0xFF0D2A3D);
const _yellow  = Color(0xFFE3B341);
const _yellowBg= Color(0xFF3D2E0A);
const _red     = Color(0xFFF85149);
const _redBg   = Color(0xFF3D1A1A);

// ─── Models ───────────────────────────────────────────────────────────────────

class _Test {
  final String  id, title;
  final String? subject, form, duration, instructions;
  final int     totalMarks;
  final List<_TQuestion> questions;

  const _Test({
    required this.id, required this.title, this.subject, this.form,
    this.duration, this.instructions, required this.totalMarks,
    required this.questions,
  });

  factory _Test.fromJson(Map<String, dynamic> j) => _Test(
    id:          j['id']?.toString()          ?? '',
    title:       j['title']?.toString()       ?? 'Test',
    subject:     j['subject']?.toString(),
    form:        j['form']?.toString(),
    duration:    j['duration']?.toString(),
    instructions:j['instructions']?.toString(),
    totalMarks:  (j['totalMarks'] as num?)?.toInt() ?? 0,
    questions:   (j['questions'] as List? ?? [])
        .map((q) => _TQuestion.fromJson(q as Map<String, dynamic>))
        .toList(),
  );
}

class _TQuestion {
  final String id, text;
  final int    marks;
  final String type; // short | structured | long

  const _TQuestion({
    required this.id, required this.text,
    required this.marks, required this.type,
  });

  factory _TQuestion.fromJson(Map<String, dynamic> j) => _TQuestion(
    id:    j['id']?.toString()   ?? '',
    text:  j['text']?.toString() ?? '',
    marks: (j['marks'] as num?)?.toInt() ?? 0,
    type:  j['type']?.toString() ?? 'short',
  );
}

class _Submission {
  final String  id, status;
  final int?    totalScore, percentage;
  final String? teacherComment;
  final List<Map<String, dynamic>> answers;
  final List<Map<String, dynamic>> finalMarks;
  final _Test?  test;

  const _Submission({
    required this.id, required this.status,
    this.totalScore, this.percentage, this.teacherComment,
    required this.answers, required this.finalMarks, this.test,
  });

  factory _Submission.fromJson(Map<String, dynamic> j) => _Submission(
    id:             j['id']?.toString() ?? '',
    status:         j['status']?.toString() ?? 'SUBMITTED',
    totalScore:     (j['totalScore'] as num?)?.toInt(),
    percentage:     (j['percentage'] as num?)?.toInt(),
    teacherComment: j['teacherComment']?.toString(),
    answers:        List<Map<String, dynamic>>.from(j['answers'] ?? []),
    finalMarks:     List<Map<String, dynamic>>.from(j['finalMarks'] ?? []),
    test:           j['test'] != null ? _Test.fromJson(j['test'] as Map<String, dynamic>) : null,
  );
}

// ─── Toast ────────────────────────────────────────────────────────────────────

void _toast(BuildContext ctx, String msg, {bool error = false}) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Row(children: [
      Text(error ? '⚠️ ' : '✅ '),
      Expanded(child: Text(msg,
          style: TextStyle(color: error ? _red : _greenL,
              fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
    backgroundColor: error ? _redBg : _greenBg,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: error ? _red : _green),
    ),
  ));
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  const _SCard({required this.child, this.borderColor});
  @override
  Widget build(BuildContext ctx) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _surface,
      border: Border.all(color: borderColor ?? _border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _Badge(this.label, {this.fg = _green, this.bg = _greenBg});
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: fg.withValues(alpha: 0.4)),
    ),
    child: Text(label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

// ─── Main Tab Widget ──────────────────────────────────────────────────────────

class StructuredTestsTab extends StatefulWidget {
  const StructuredTestsTab({super.key});
  @override State<StructuredTestsTab> createState() => _StructuredTestsTabState();
}

class _StructuredTestsTabState extends State<StructuredTestsTab> {
  List<_Test> _tests   = [];
  bool        _loading = true;
  _Test?      _taking;   // currently taking a test
  _Test?      _viewing;  // viewing a result

  @override
  void initState() { super.initState(); _fetchTests(); }

  Future<void> _fetchTests() async {
    setState(() => _loading = true);
    try {
      final headers = await authHeaders();
      final res = await http.get(
        Uri.parse('$kApiBase/structured-tests/available'),
        headers: headers,
      );
      if (res.statusCode < 300 && mounted) {
        setState(() {
          _tests = (jsonDecode(res.body) as List)
              .map((e) => _Test.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
      if (mounted) _toast(context, 'Failed to load tests.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Taking a test ──────────────────────────────────────────────
    if (_taking != null) {
      return _TestRunner(
        test: _taking!,
        onDone: () {
          setState(() => _taking = null);
          _fetchTests();
        },
      );
    }

    // ── Viewing result ─────────────────────────────────────────────
    if (_viewing != null) {
      return _ResultView(
        test: _viewing!,
        onBack: () => setState(() => _viewing = null),
      );
    }

    // ── Test list ──────────────────────────────────────────────────
    return RefreshIndicator(
      color: _green,
      onRefresh: _fetchTests,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _tests.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _tests.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) return _header();
                    return _testCard(_tests[i - 1]);
                  },
                ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: _SCard(
      borderColor: _green,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('📝', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text('Written Tests',
              style: TextStyle(color: _text, fontSize: 17,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Text('${_tests.length} test${_tests.length != 1 ? "s" : ""} available from your teachers',
            style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 12),
        // Mini-stats row
        Row(children: [
          _miniStat('${_tests.length}', 'Available'),
          const SizedBox(width: 10),
          _miniStat(
            '${_tests.map((t) => t.subject).whereType<String>().toSet().length}',
            'Subjects',
          ),
          const SizedBox(width: 10),
          _miniStat(
            '${_tests.fold(0, (s, t) => s + t.totalMarks)}',
            'Total Marks',
          ),
        ]),
      ]),
    ),
  );

  Widget _miniStat(String val, String lbl) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        Text(val, style: const TextStyle(
            color: _green, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(lbl, style: const TextStyle(color: _subtle, fontSize: 10)),
      ]),
    ),
  );

  Widget _testCard(_Test t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _SCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Subject + form badges
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (t.subject != null)
              _Badge(t.subject!, fg: _green, bg: _greenBg),
            if (t.form != null)
              _Badge(t.form!, fg: _muted, bg: _border),
          ]),
          const SizedBox(height: 10),
          Text(t.title,
              style: const TextStyle(color: _text,
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          // Meta row
          Wrap(spacing: 16, children: [
            _meta('⏱', t.duration ?? '—'),
            _meta('❓', '${t.questions.length} questions'),
            _meta('📊', '${t.totalMarks} marks'),
          ]),
          const SizedBox(height: 12),
          // Action buttons
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _viewing = t),
                icon: const Icon(Icons.bar_chart, size: 16),
                label: const Text('Results', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _blue,
                  side: const BorderSide(color: _blue),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _taking = t),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Take Test',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _meta(String icon, String val) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(icon, style: const TextStyle(fontSize: 12)),
    const SizedBox(width: 4),
    Text(val, style: const TextStyle(color: _muted, fontSize: 12)),
  ]);

  Widget _emptyState() => Center(
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(32),
      children: const [
        Center(child: Text('📝', style: TextStyle(fontSize: 56))),
        SizedBox(height: 16),
        Center(
          child: Text('No tests available yet',
              style: TextStyle(color: _text, fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ),
        SizedBox(height: 8),
        Center(
          child: Text('Your teacher will publish tests here.\nPull down to refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13)),
        ),
      ],
    ),
  );
}

// ─── Test Runner (student takes the test) ────────────────────────────────────

class _TestRunner extends StatefulWidget {
  final _Test        test;
  final VoidCallback onDone;
  const _TestRunner({required this.test, required this.onDone});
  @override State<_TestRunner> createState() => _TestRunnerState();
}

class _TestRunnerState extends State<_TestRunner> {
  final Map<String, String> _answers   = {};
  final Map<String, FocusNode> _focus  = {};
  bool   _submitting = false;
  bool   _done       = false;
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Parse duration (e.g. "60 minutes" → 3600 seconds)
    final mins = int.tryParse(
        RegExp(r'\d+').firstMatch(widget.test.duration ?? '60')?.group(0) ?? '60') ?? 60;
    _secondsLeft = mins * 60;

    // Initialise focus nodes
    for (final q in widget.test.questions) {
      _focus[q.id] = FocusNode();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
          if (!_done) _submit(forceSubmit: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final f in _focus.values) f.dispose();
    super.dispose();
  }

  String get _timeFormatted {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft < 300) return _red;
    if (_secondsLeft < 600) return _yellow;
    return _green;
  }

  Future<void> _submit({bool forceSubmit = false}) async {
    final unanswered = widget.test.questions
        .where((q) => (_answers[q.id] ?? '').trim().isEmpty)
        .length;

    if (!forceSubmit && unanswered > 0) {
      _toast(context,
        '$unanswered question${unanswered > 1 ? "s" : ""} still unanswered.',
        error: true,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final headers = await authHeaders();
      final payload = widget.test.questions
          .map((q) => {'questionId': q.id, 'answer': _answers[q.id] ?? ''})
          .toList();

      final res = await http.post(
        Uri.parse('$kApiBase/structured-tests/${widget.test.id}/submit'),
        headers: headers,
        body: jsonEncode({'answers': payload}),
      );

      if (res.statusCode < 300) {
        setState(() => _done = true);
      } else {
        final d = jsonDecode(res.body);
        _toast(context,
          d['message']?.toString() ?? 'Submission failed (${res.statusCode})',
          error: true,
        );
      }
    } catch (e) {
      _toast(context, 'Network error: $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _successScreen();

    final answered = _answers.values.where((v) => v.trim().isNotEmpty).length;
    final total    = widget.test.questions.length;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Sticky header ────────────────────────────────────
            Container(
              color: _surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.test.title,
                          style: const TextStyle(color: _text,
                              fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        '${widget.test.subject ?? ""}'
                        '${widget.test.form != null ? " · ${widget.test.form}" : ""}'
                        ' · ${widget.test.totalMarks} marks',
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _timerColor),
                    ),
                    child: Column(children: [
                      Text(_timeFormatted,
                          style: TextStyle(color: _timerColor,
                              fontWeight: FontWeight.w800, fontSize: 20,
                              fontFeatures: const [FontFeature.tabularFigures()])),
                      Text('remaining',
                          style: TextStyle(color: _timerColor.withValues(alpha: 0.7),
                              fontSize: 10)),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  // Progress counter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _border2),
                    ),
                    child: Column(children: [
                      Text('$answered/$total',
                          style: const TextStyle(color: _green,
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      const Text('done', style: TextStyle(color: _subtle, fontSize: 10)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : answered / total,
                    backgroundColor: _border,
                    valueColor: const AlwaysStoppedAnimation(_green),
                    minHeight: 5,
                  ),
                ),
              ]),
            ),

            // ── Question list ────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: widget.test.questions.length + 1,
                itemBuilder: (_, i) {
                  if (i == widget.test.questions.length) {
                    return _submitBar(answered, total);
                  }
                  return _questionCard(widget.test.questions[i], i);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(_TQuestion q, int index) {
    final answered = (_answers[q.id] ?? '').trim().isNotEmpty;
    final rowCount = q.type == 'long' ? 6 : q.type == 'structured' ? 4 : 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: answered ? _green.withValues(alpha: 0.5) : _border,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Question header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: answered ? _greenBg : _bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(bottom: BorderSide(
              color: answered ? _green.withValues(alpha: 0.3) : _border,
            )),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: answered ? _green : _border2,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${index + 1}',
                      style: TextStyle(
                        color: answered ? Colors.white : _muted,
                        fontWeight: FontWeight.w700, fontSize: 12,
                      )),
                ),
                const SizedBox(width: 8),
                Text('Question ${index + 1}',
                    style: const TextStyle(color: _muted,
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border2),
                  ),
                  child: Text('${q.marks} mark${q.marks != 1 ? "s" : ""}',
                      style: const TextStyle(color: _muted,
                          fontWeight: FontWeight.w600, fontSize: 11)),
                ),
                if (answered) ...[
                  const SizedBox(width: 6),
                  const Text('✓', style: TextStyle(color: _green,
                      fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ]),
            ],
          ),
        ),

        // Question text
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Text(q.text,
              style: const TextStyle(color: _text, fontSize: 14, height: 1.5)),
        ),

        // Answer field
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: TextField(
            focusNode: _focus[q.id],
            maxLines: rowCount,
            style: const TextStyle(color: _text, fontSize: 13),
            onChanged: (v) => setState(() => _answers[q.id] = v),
            decoration: InputDecoration(
              hintText: 'Write your answer here…',
              hintStyle: const TextStyle(color: _subtle, fontSize: 12),
              filled: true,
              fillColor: _bg,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: answered ? _green.withValues(alpha: 0.5) : _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: answered ? _green.withValues(alpha: 0.5) : _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _green, width: 1.5),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _submitBar(int answered, int total) {
    final allDone = answered == total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(children: [
        if (!allDone)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _yellowBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _yellow),
            ),
            child: Row(children: [
              const Text('⚠️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '${total - answered} question${total - answered > 1 ? "s" : ""} unanswered. '
                'You can still submit.',
                style: const TextStyle(color: _yellow, fontSize: 12),
              )),
            ]),
          ),
        ElevatedButton.icon(
          onPressed: _submitting ? null : () => _submit(),
          icon: _submitting
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded),
          label: Text(
            _submitting
                ? 'Submitting…'
                : '📤 Submit Test ($answered/$total answered)',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: allDone ? _green : const Color(0xFF2A4A3A),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: widget.onDone,
          child: const Text('Cancel and go back',
              style: TextStyle(color: _subtle, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _successScreen() => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(
      child: Center(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(32), children: [
          const Center(child: Text('✅', style: TextStyle(fontSize: 72))),
          const SizedBox(height: 20),
          const Center(
            child: Text('Test Submitted!',
                style: TextStyle(color: _green, fontSize: 24,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Your answers have been sent to your teacher.\nYou\'ll be notified when results are ready.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: widget.onDone,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Tests',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ─── Result View (student views marked result) ────────────────────────────────

class _ResultView extends StatefulWidget {
  final _Test        test;
  final VoidCallback onBack;
  const _ResultView({required this.test, required this.onBack});
  @override State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  _Submission? _result;
  bool         _loading = true;
  String?      _error;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await authHeaders();
      final res = await http.get(
        Uri.parse('$kApiBase/structured-tests/${widget.test.id}/my-result'),
        headers: headers,
      );
      if (res.statusCode < 300) {
        setState(() => _result = _Submission.fromJson(
            jsonDecode(res.body) as Map<String, dynamic>));
      } else {
        setState(() => _error = 'No result found. Have you taken this test?');
      }
    } catch (_) {
      setState(() => _error = 'Could not load result. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _text,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(widget.test.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _errorState()
              : _result!.status == 'MARKED'
                  ? _markedView()
                  : _pendingView(),
    );
  }

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📭', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 14)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: widget.onBack,
          style: ElevatedButton.styleFrom(backgroundColor: _green),
          child: const Text('Go back', style: TextStyle(color: Colors.white)),
        ),
      ]),
    ),
  );

  Widget _pendingView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('⏳', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        const Text('Awaiting Marking',
            style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const Text(
          'Your test has been submitted.\nYour teacher will mark it soon.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 14, height: 1.6),
        ),
      ]),
    ),
  );

  Widget _markedView() {
    final pct  = _result!.percentage ?? 0;
    final emoji = pct >= 75 ? '🌟' : pct >= 50 ? '👍' : '💪';

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Score card ──────────────────────────────────────────
        _SCard(
          borderColor: _green,
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text('$pct%',
                style: const TextStyle(color: _green, fontSize: 40,
                    fontWeight: FontWeight.w900)),
            Text('${_result!.totalScore} / ${widget.test.totalMarks} marks',
                style: const TextStyle(color: _muted, fontSize: 14)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: _border,
                valueColor: AlwaysStoppedAnimation(
                  pct >= 75 ? _green : pct >= 50 ? _yellow : _red,
                ),
                minHeight: 8,
              ),
            ),
            if ((_result!.teacherComment ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _greenBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _green.withValues(alpha: 0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Teacher Comment',
                      style: TextStyle(color: _muted,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_result!.teacherComment!,
                      style: const TextStyle(color: _greenL, fontSize: 13)),
                ]),
              ),
            ],
          ]),
        ),

        const SizedBox(height: 16),
        const Text('Question Breakdown',
            style: TextStyle(color: _muted,
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),

        // ── Per-question breakdown ──────────────────────────────
        for (var i = 0; i < widget.test.questions.length; i++) ...[
          _questionResult(widget.test.questions[i], i),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _questionResult(_TQuestion q, int index) {
    final markData = _result!.finalMarks.firstWhere(
      (m) => m['questionId'] == q.id, orElse: () => {},
    );
    final answerData = _result!.answers.firstWhere(
      (a) => a['questionId'] == q.id, orElse: () => {},
    );

    final mark      = (markData['mark'] as num?)?.toInt();
    final feedback  = markData['feedback']?.toString();
    final answer    = answerData['answer']?.toString() ?? '(no answer)';

    Color markColor = _muted;
    if (mark != null) {
      final ratio = q.marks > 0 ? mark / q.marks : 0;
      markColor = ratio >= 0.7 ? _green : ratio >= 0.4 ? _yellow : _red;
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Q${index + 1}.',
                  style: const TextStyle(color: _muted,
                      fontWeight: FontWeight.w700, fontSize: 13)),
              if (mark != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: markColor),
                  ),
                  child: Text('$mark / ${q.marks}',
                      style: TextStyle(color: markColor,
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.text,
                style: const TextStyle(color: _text,
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            // Student answer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your answer',
                    style: TextStyle(color: _subtle,
                        fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(answer,
                    style: const TextStyle(color: _text, fontSize: 13)),
              ]),
            ),
            // Feedback
            if ((feedback ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _blueBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _blue.withValues(alpha: 0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Teacher feedback',
                      style: TextStyle(color: _blue,
                          fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(feedback!,
                      style: const TextStyle(color: _muted, fontSize: 13)),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

