import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

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
    id:           j['id']?.toString()           ?? '',
    title:        j['title']?.toString()        ?? 'Test',
    subject:      j['subject']?.toString(),
    form:         j['form']?.toString(),
    duration:     j['duration']?.toString(),
    instructions: j['instructions']?.toString(),
    totalMarks:   (j['totalMarks'] as num?)?.toInt() ?? 0,
    questions:    (j['questions'] as List? ?? [])
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
    answers:        List<Map<String, dynamic>>.from(j['answers']    ?? []),
    finalMarks:     List<Map<String, dynamic>>.from(j['finalMarks'] ?? []),
    test:           j['test'] != null
        ? _Test.fromJson(j['test'] as Map<String, dynamic>) : null,
  );
}

// ─── Toast ────────────────────────────────────────────────────────────────────

void _toast(BuildContext ctx, String msg, {bool error = false}) {
  final t = AppTheme.of(ctx);
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Row(children: [
      Icon(
        error ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
        color: error ? t.danger : t.primary,
        size: 18,
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(msg,
          style: TextStyle(
              color: error ? t.danger : t.primary,
              fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
    backgroundColor: error
        ? t.danger.withValues(alpha: 0.15)
        : t.primary.withValues(alpha: 0.15),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: error ? t.danger : t.primary),
    ),
  ));
}

// ─── Shared card widget ────────────────────────────────────────────────────────

class _SCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  const _SCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext ctx) {
    final t = AppTheme.of(ctx);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: borderColor ?? t.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

// ─── Badge widget ──────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color? fg;
  final Color? bg;
  const _Badge(this.label, {this.fg, this.bg});

  @override
  Widget build(BuildContext ctx) {
    final t  = AppTheme.of(ctx);
    final fg = this.fg ?? t.primary;
    final bg = this.bg ?? t.primary.withValues(alpha: 0.15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Main Tab Widget ──────────────────────────────────────────────────────────

class StructuredTestsTab extends StatefulWidget {
  const StructuredTestsTab({super.key});
  @override
  State<StructuredTestsTab> createState() => _StructuredTestsTabState();
}

class _StructuredTestsTabState extends State<StructuredTestsTab> {
  List<_Test> _tests   = [];
  bool        _loading = true;
  _Test?      _taking;
  _Test?      _viewing;

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
    final t = AppTheme.of(context);

    if (_taking != null) {
      return _TestRunner(
        test: _taking!,
        onDone: () { setState(() => _taking = null); _fetchTests(); },
      );
    }

    if (_viewing != null) {
      return _ResultView(
        test: _viewing!,
        onBack: () => setState(() => _viewing = null),
      );
    }

    return RefreshIndicator(
      color: t.primary,
      onRefresh: _fetchTests,
      child: _loading
          ? Center(child: CircularProgressIndicator(color: t.primary))
          : _tests.isEmpty
              ? _emptyState(t)
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _tests.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) return _header(t);
                    return _testCard(_tests[i - 1], t);
                  },
                ),
    );
  }

  Widget _header(AppThemeData t) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: _SCard(
      borderColor: t.primary,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.edit_document, color: t.primary, size: 20),
          const SizedBox(width: 8),
          Text('Written Tests',
              style: TextStyle(color: t.text, fontSize: 17,
                  fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Text('${_tests.length} test${_tests.length != 1 ? "s" : ""} available from your teachers',
            style: TextStyle(color: t.muted, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          _miniStat('${_tests.length}', 'Available', t),
          const SizedBox(width: 10),
          _miniStat(
            '${_tests.map((t) => t.subject).whereType<String>().toSet().length}',
            'Subjects', t,
          ),
          const SizedBox(width: 10),
          _miniStat(
            '${_tests.fold(0, (s, t) => s + t.totalMarks)}',
            'Total Marks', t,
          ),
        ]),
      ]),
    ),
  );

  Widget _miniStat(String val, String lbl, AppThemeData t) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(children: [
        Text(val, style: TextStyle(
            color: t.primary, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(lbl, style: TextStyle(color: t.subtle, fontSize: 10)),
      ]),
    ),
  );

  Widget _testCard(_Test t, AppThemeData th) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    child: _SCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (t.subject != null) _Badge(t.subject!),
          if (t.form    != null) _Badge(t.form!,
              fg: th.muted, bg: th.surface2),
        ]),
        const SizedBox(height: 10),
        Text(t.title,
            style: TextStyle(color: th.text,
                fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(spacing: 16, children: [
          _metaChip(Icons.timer_outlined, t.duration ?? '—', th),
          _metaChip(Icons.help_outline_rounded,
              '${t.questions.length} questions', th),
          _metaChip(Icons.bar_chart_rounded,
              '${t.totalMarks} marks', th),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _viewing = t),
              icon: const Icon(Icons.bar_chart_rounded, size: 16),
              label: const Text('Results', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: th.teal,
                side: BorderSide(color: th.teal),
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
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Take Test',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: th.primary,
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

  Widget _metaChip(IconData icon, String val, AppThemeData t) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: t.muted),
        const SizedBox(width: 4),
        Text(val, style: TextStyle(color: t.muted, fontSize: 12)),
      ]);

  Widget _emptyState(AppThemeData t) => Center(
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(32),
      children: [
        Center(child: Icon(Icons.edit_document,
            size: 56, color: t.subtle)),
        const SizedBox(height: 16),
        Center(child: Text('No tests available yet',
            style: TextStyle(color: t.text, fontSize: 18,
                fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        Center(child: Text(
          'Your teacher will publish tests here.\nPull down to refresh.',
          textAlign: TextAlign.center,
          style: TextStyle(color: t.muted, fontSize: 13),
        )),
      ],
    ),
  );
}

// ─── Test Runner ──────────────────────────────────────────────────────────────

class _TestRunner extends StatefulWidget {
  final _Test        test;
  final VoidCallback onDone;
  const _TestRunner({required this.test, required this.onDone});
  @override
  State<_TestRunner> createState() => _TestRunnerState();
}

class _TestRunnerState extends State<_TestRunner> {
  final Map<String, String>    _answers = {};
  final Map<String, FocusNode> _focus   = {};
  bool   _submitting = false;
  bool   _done       = false;
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final mins = int.tryParse(
        RegExp(r'\d+').firstMatch(widget.test.duration ?? '60')?.group(0) ?? '60') ?? 60;
    _secondsLeft = mins * 60;

    for (final q in widget.test.questions) {
      _focus[q.id] = FocusNode();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
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

  Color _timerColor(AppThemeData t) {
    if (_secondsLeft < 300) return t.danger;
    if (_secondsLeft < 600) return t.amber;
    return t.primary;
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
    final t = AppTheme.of(context);
    if (_done) return _successScreen(t);

    final answered = _answers.values.where((v) => v.trim().isNotEmpty).length;
    final total    = widget.test.questions.length;
    final tc       = _timerColor(t);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Sticky header ──────────────────────────────────────────────
          Container(
            color: t.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.test.title,
                        style: TextStyle(color: t.text,
                            fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${widget.test.subject ?? ""}'
                      '${widget.test.form != null ? " · ${widget.test.form}" : ""}'
                      ' · ${widget.test.totalMarks} marks',
                      style: TextStyle(color: t.muted, fontSize: 11),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tc),
                  ),
                  child: Column(children: [
                    Text(_timeFormatted,
                        style: TextStyle(color: tc,
                            fontWeight: FontWeight.w800, fontSize: 20,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                    Text('remaining',
                        style: TextStyle(
                            color: tc.withValues(alpha: 0.7), fontSize: 10)),
                  ]),
                ),
                const SizedBox(width: 10),
                // Progress counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.border),
                  ),
                  child: Column(children: [
                    Text('$answered/$total',
                        style: TextStyle(color: t.primary,
                            fontWeight: FontWeight.w800, fontSize: 18)),
                    Text('done',
                        style: TextStyle(color: t.subtle, fontSize: 10)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : answered / total,
                  backgroundColor: t.border,
                  valueColor: AlwaysStoppedAnimation(t.primary),
                  minHeight: 5,
                ),
              ),
            ]),
          ),

          // ── Question list ──────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: widget.test.questions.length + 1,
              itemBuilder: (_, i) {
                if (i == widget.test.questions.length) {
                  return _submitBar(answered, total, t);
                }
                return _questionCard(widget.test.questions[i], i, t);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _questionCard(_TQuestion q, int index, AppThemeData t) {
    final answered = (_answers[q.id] ?? '').trim().isNotEmpty;
    final rowCount = q.type == 'long' ? 6 : q.type == 'structured' ? 4 : 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: answered
              ? t.primary.withValues(alpha: 0.5)
              : t.border,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Question header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: answered
                ? t.primary.withValues(alpha: 0.12)
                : t.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(bottom: BorderSide(
              color: answered
                  ? t.primary.withValues(alpha: 0.3)
                  : t.border,
            )),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: answered ? t.primary : t.surface2,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${index + 1}',
                      style: TextStyle(
                        color: answered ? Colors.white : t.muted,
                        fontWeight: FontWeight.w700, fontSize: 12,
                      )),
                ),
                const SizedBox(width: 8),
                Text('Question ${index + 1}',
                    style: TextStyle(color: t.muted,
                        fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.border),
                  ),
                  child: Text('${q.marks} mark${q.marks != 1 ? "s" : ""}',
                      style: TextStyle(color: t.muted,
                          fontWeight: FontWeight.w600, fontSize: 11)),
                ),
                if (answered) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check_circle_rounded,
                      color: t.primary, size: 18),
                ],
              ]),
            ],
          ),
        ),

        // Question text
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Text(q.text,
              style: TextStyle(color: t.text, fontSize: 14, height: 1.5)),
        ),

        // Answer field
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: TextField(
            focusNode: _focus[q.id],
            maxLines: rowCount,
            style: TextStyle(color: t.text, fontSize: 13),
            onChanged: (v) => setState(() => _answers[q.id] = v),
            decoration: InputDecoration(
              hintText: 'Write your answer here…',
              hintStyle: TextStyle(color: t.subtle, fontSize: 12),
              filled: true,
              fillColor: t.bg,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: answered
                        ? t.primary.withValues(alpha: 0.5)
                        : t.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: answered
                        ? t.primary.withValues(alpha: 0.5)
                        : t.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: t.primary, width: 1.5),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _submitBar(int answered, int total, AppThemeData t) {
    final allDone = answered == total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(children: [
        if (!allDone)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: t.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.amber),
            ),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, color: t.amber, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(
                '${total - answered} question${total - answered > 1 ? "s" : ""} unanswered. '
                'You can still submit.',
                style: TextStyle(color: t.amber, fontSize: 12),
              )),
            ]),
          ),
        ElevatedButton.icon(
          onPressed: _submitting ? null : () => _submit(),
          icon: _submitting
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded),
          label: Text(
            _submitting
                ? 'Submitting…'
                : 'Submit Test ($answered/$total answered)',
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: allDone
                ? t.primary
                : t.primary.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: widget.onDone,
          child: Text('Cancel and go back',
              style: TextStyle(color: t.subtle, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _successScreen(AppThemeData t) => Scaffold(
    backgroundColor: t.bg,
    body: SafeArea(
      child: Center(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(32),
            children: [
          Center(child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                color: t.primary, size: 64),
          )),
          const SizedBox(height: 20),
          Center(child: Text('Test Submitted!',
              style: TextStyle(color: t.primary, fontSize: 24,
                  fontWeight: FontWeight.w800))),
          const SizedBox(height: 12),
          Center(child: Text(
            'Your answers have been sent to your teacher.\n'
            'You\'ll be notified when results are ready.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.muted, fontSize: 14, height: 1.6),
          )),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: widget.onDone,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back to Tests',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.primary,
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

// ─── Result View ──────────────────────────────────────────────────────────────

class _ResultView extends StatefulWidget {
  final _Test        test;
  final VoidCallback onBack;
  const _ResultView({required this.test, required this.onBack});
  @override
  State<_ResultView> createState() => _ResultViewState();
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
        Uri.parse(
            '$kApiBase/structured-tests/${widget.test.id}/my-result'),
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
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        foregroundColor: t.text,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
        title: Text(widget.test.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
        elevation: 0,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: t.primary))
          : _error != null
              ? _errorState(t)
              : _result!.status == 'MARKED'
                  ? _markedView(t)
                  : _pendingView(t),
    );
  }

  Widget _errorState(AppThemeData t) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 56, color: t.subtle),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center,
            style: TextStyle(color: t.muted, fontSize: 14)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: widget.onBack,
          style: ElevatedButton.styleFrom(backgroundColor: t.primary),
          child: const Text('Go back',
              style: TextStyle(color: Colors.white)),
        ),
      ]),
    ),
  );

  Widget _pendingView(AppThemeData t) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.amber.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.hourglass_top_rounded,
              size: 56, color: t.amber),
        ),
        const SizedBox(height: 16),
        Text('Awaiting Marking',
            style: TextStyle(
                color: t.text, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
          'Your test has been submitted.\nYour teacher will mark it soon.',
          textAlign: TextAlign.center,
          style: TextStyle(color: t.muted, fontSize: 14, height: 1.6),
        ),
      ]),
    ),
  );

  Widget _markedView(AppThemeData t) {
    final pct = _result!.percentage ?? 0;
    Color scoreColor;
    IconData scoreIcon;
    if (pct >= 75) {
      scoreColor = t.primary;
      scoreIcon  = Icons.star_rounded;
    } else if (pct >= 50) {
      scoreColor = t.teal;
      scoreIcon  = Icons.thumb_up_rounded;
    } else {
      scoreColor = t.amber;
      scoreIcon  = Icons.fitness_center_rounded;
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ── Score card ──────────────────────────────────────────────────
        _SCard(
          borderColor: t.primary,
          child: Column(children: [
            Icon(scoreIcon, color: scoreColor, size: 48),
            const SizedBox(height: 10),
            Text('$pct%',
                style: TextStyle(color: t.primary, fontSize: 40,
                    fontWeight: FontWeight.w900)),
            Text('${_result!.totalScore} / ${widget.test.totalMarks} marks',
                style: TextStyle(color: t.muted, fontSize: 14)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: t.border,
                valueColor: AlwaysStoppedAnimation(
                  pct >= 75 ? t.primary : pct >= 50 ? t.teal : t.amber,
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
                  color: t.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: t.primary.withValues(alpha: 0.4)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Teacher Comment',
                      style: TextStyle(color: t.muted,
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_result!.teacherComment!,
                      style: TextStyle(color: t.primary, fontSize: 13)),
                ]),
              ),
            ],
          ]),
        ),

        const SizedBox(height: 16),
        Text('Question Breakdown',
            style: TextStyle(color: t.muted,
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),

        for (var i = 0; i < widget.test.questions.length; i++) ...[
          _questionResult(widget.test.questions[i], i, t),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _questionResult(_TQuestion q, int index, AppThemeData t) {
    final markData = _result!.finalMarks.firstWhere(
      (m) => m['questionId'] == q.id, orElse: () => {},
    );
    final answerData = _result!.answers.firstWhere(
      (a) => a['questionId'] == q.id, orElse: () => {},
    );

    final mark     = (markData['mark'] as num?)?.toInt();
    final feedback = markData['feedback']?.toString();
    final answer   = answerData['answer']?.toString() ?? '(no answer)';

    Color markColor = t.muted;
    if (mark != null) {
      final ratio = q.marks > 0 ? mark / q.marks : 0;
      markColor = ratio >= 0.7 ? t.primary : ratio >= 0.4 ? t.amber : t.danger;
    }

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(bottom: BorderSide(color: t.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Q${index + 1}.',
                  style: TextStyle(color: t.muted,
                      fontWeight: FontWeight.w700, fontSize: 13)),
              if (mark != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.bg,
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
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.text,
                style: TextStyle(color: t.text,
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            // Student answer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: t.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.border),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Your answer',
                    style: TextStyle(color: t.subtle,
                        fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(answer,
                    style: TextStyle(color: t.text, fontSize: 13)),
              ]),
            ),
            // Feedback
            if ((feedback ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: t.teal.withValues(alpha: 0.4)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Teacher feedback',
                      style: TextStyle(color: t.teal,
                          fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(feedback!,
                      style: TextStyle(color: t.muted, fontSize: 13)),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}