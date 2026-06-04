import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_manager.dart';

// ─── Subject Topics ───────────────────────────────────────────────────────────
const Map<String, List<String>> _subjectTopics = {
  'Biology':         ['Cell Structure','Cell Division','Photosynthesis','Respiration','Transport in Plants','Circulatory System','Nutrition','Excretion','Nervous System','Genetics','Ecology','Disease and Immunity'],
  'Mathematics':     ['Algebra','Linear Equations','Quadratic Equations','Functions and Graphs','Trigonometry','Vectors','Matrices','Statistics','Probability','Mensuration'],
  'Chemistry':       ['Atomic Structure','Periodic Table','Chemical Bonding','Acids and Bases','Redox Reactions','Electrochemistry','Rates of Reaction','Organic Chemistry'],
  'Physics':         ['Motion','Newton\'s Laws','Work, Energy, Power','Waves','Light','Electricity','Magnetism','Radioactivity'],
  'English':         ['Comprehension','Essay Writing','Grammar','Literature','Report Writing','Letter Writing'],
  'Geography':       ['Map Reading','Climate','Physical Features of Malawi','Agriculture','Population','Environmental Conservation'],
  'History':         ['Pre-colonial Malawi','Colonial Rule','Independence','Post-Independence'],
  'Civic Education': ['Human Rights','Constitution','Government','Democracy','Gender Equality'],
  'Computer Studies':['Hardware','Software','Networking','Programming','Web Design','Data Representation'],
};

// ─── Models ───────────────────────────────────────────────────────────────────

class _TQuestion {
  String id, text, type, markingGuidance;
  int marks;
  _TQuestion({required this.id, this.text='', this.type='short',
    this.marks=2, this.markingGuidance=''});
  Map<String,dynamic> toJson() => {
    'id':id,'text':text,'type':type,'marks':marks,
    'markingGuidance':markingGuidance,
  };
  factory _TQuestion.fromJson(Map<String,dynamic> j) => _TQuestion(
    id:               j['id']?.toString()              ?? '',
    text:             j['text']?.toString()            ?? '',
    type:             j['type']?.toString()            ?? 'short',
    marks:            (j['marks'] as num?)?.toInt()    ?? 2,
    markingGuidance:  j['markingGuidance']?.toString() ?? '',
  );
  _TQuestion copy() => _TQuestion(id:id,text:text,type:type,
    marks:marks,markingGuidance:markingGuidance);
}

class _Test {
  final String  id, title, status;
  final String? subject, form, duration;
  final int     totalMarks;
  final List<_TQuestion> questions;
  final DateTime? createdAt;
  const _Test({required this.id,required this.title,required this.status,
    this.subject,this.form,this.duration,required this.totalMarks,
    required this.questions,this.createdAt});
  factory _Test.fromJson(Map<String,dynamic> j) {
    DateTime? ca;
    try { if (j['createdAt'] is String) ca=DateTime.parse(j['createdAt']); } catch(_) {}
    return _Test(
      id:         j['id']?.toString()        ?? '',
      title:      j['title']?.toString()     ?? '',
      status:     j['status']?.toString()    ?? 'DRAFT',
      subject:    j['subject']?.toString(),
      form:       j['form']?.toString(),
      duration:   j['duration']?.toString(),
      totalMarks: (j['totalMarks'] as num?)?.toInt() ?? 0,
      questions:  (j['questions'] as List? ?? [])
          .map((q)=>_TQuestion.fromJson(q as Map<String,dynamic>)).toList(),
      createdAt:  ca,
    );
  }
  String get formattedDate {
    if (createdAt==null) return '—';
    const m=['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${createdAt!.day} ${m[createdAt!.month]} ${createdAt!.year}';
  }
}

class _Submission {
  final String  id, status;
  final String? studentName;
  final int?    totalScore, percentage;
  final List<Map<String,dynamic>> answers, aiMarking, finalMarks;
  final DateTime? submittedAt;
  const _Submission({required this.id,required this.status,this.studentName,
    this.totalScore,this.percentage,required this.answers,
    required this.aiMarking,required this.finalMarks,this.submittedAt});
  factory _Submission.fromJson(Map<String,dynamic> j) {
    DateTime? sa;
    try { if (j['submittedAt'] is String) sa=DateTime.parse(j['submittedAt']); } catch(_) {}
    final student = j['student'] as Map<String,dynamic>?;
    final name = student!=null
        ? '${student['firstName']??''} ${student['lastName']??''}'.trim()
        : 'Student #${j['studentId']}';
    return _Submission(
      id:          j['id']?.toString()     ?? '',
      status:      j['status']?.toString() ?? 'SUBMITTED',
      studentName: name,
      totalScore:  (j['totalScore']  as num?)?.toInt(),
      percentage:  (j['percentage']  as num?)?.toInt(),
      answers:     List<Map<String,dynamic>>.from(j['answers']    ?? []),
      aiMarking:   List<Map<String,dynamic>>.from(j['aiMarking']  ?? []),
      finalMarks:  List<Map<String,dynamic>>.from(j['finalMarks'] ?? []),
      submittedAt: sa,
    );
  }
  String get formattedDate {
    if (submittedAt==null) return '—';
    return '${submittedAt!.day}/${submittedAt!.month}/${submittedAt!.year}';
  }
}

// ─── Toast ────────────────────────────────────────────────────────────────────

void _toast(BuildContext ctx, String msg, {bool error=false}) {
  final t = AppTheme.of(ctx);
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
    content: Row(children:[
      Text(error ? '⚠️ ' : '✅ '),
      Expanded(child:Text(msg, style: TextStyle(
        color: error ? t.redText : t.greenAccent,
        fontWeight: FontWeight.w600, fontSize: 13,
      ))),
    ]),
    backgroundColor: error ? t.redBg : t.greenBg,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: error ? t.redText : t.greenAccent),
    ),
  ));
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  const _Card({required this.child, this.borderColor});

  @override
  Widget build(BuildContext ctx) {
    final t = AppTheme.of(ctx);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardBg,
        border: Border.all(color: borderColor ?? t.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? fg, bg;
  const _Badge(this.label, {this.fg, this.bg});

  @override
  Widget build(BuildContext ctx) {
    final t = AppTheme.of(ctx);
    final fgColor = fg ?? t.greenAccent;
    final bgColor = bg ?? t.greenBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:8, vertical:3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fgColor.withValues(alpha:0.4)),
      ),
      child: Text(label, style: TextStyle(
        color: fgColor, fontSize: 11, fontWeight: FontWeight.w600,
      )),
    );
  }
}

InputDecoration _themedInputDec(AppThemeData t, String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: t.subtle),
  filled: true,
  fillColor: t.inputBg,
  contentPadding: const EdgeInsets.symmetric(horizontal:12, vertical:10),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: t.textFieldBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: t.textFieldBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: t.primary, width: 1.5),
  ),
);

// ─── Main Screen ──────────────────────────────────────────────────────────────

class StructuredTestsTeacherScreen extends StatefulWidget {
  const StructuredTestsTeacherScreen({super.key});
  @override
  State<StructuredTestsTeacherScreen> createState() => _STTState();
}

class _STTState extends State<StructuredTestsTeacherScreen> {
  List<_Test> _tests   = [];
  bool        _loading = true;
  Widget?     _child;

  @override
  void initState() { super.initState(); _fetchTests(); }

  Future<void> _fetchTests() async {
    setState(() => _loading = true);
    try {
      final h = await authHeaders();
      final r = await http.get(Uri.parse('$kApiBase/structured-tests/mine'), headers: h);
      if (r.statusCode < 300 && mounted) {
        setState(() => _tests = (jsonDecode(r.body) as List)
            .map((e) => _Test.fromJson(e as Map<String,dynamic>)).toList());
      }
    } catch(_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  void _push(Widget w) => setState(() => _child = w);
  void _pop({bool refresh=false}) {
    setState(() => _child = null);
    if (refresh) _fetchTests();
  }

  @override
  Widget build(BuildContext ctx) {
    if (_child != null) return _child!;
    final t  = AppTheme.of(ctx);
    context.watch<ThemeManager>(); // rebuild on theme change

    return Scaffold(
      backgroundColor: t.bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: t.primary,
        onPressed: () => _push(_CreateTestScreen(onDone: _pop)),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Test',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: t.primary,
        onRefresh: _fetchTests,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: t.primary))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                itemCount: _tests.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) return _header(t);
                  return _testCard(t, _tests[i - 1]);
                },
              ),
      ),
    );
  }

  Widget _header(AppThemeData t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: _Card(
      borderColor: t.primary,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📝', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text('Structured Tests', style: TextStyle(
              color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Text('${_tests.length} test${_tests.length != 1 ? "s" : ""} created',
            style: TextStyle(color: t.muted, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          _miniStat(t, '${_tests.length}', 'Total'),
          const SizedBox(width: 8),
          _miniStat(t, '${_tests.where((t) => t.status == "PUBLISHED").length}', 'Published'),
          const SizedBox(width: 8),
          _miniStat(t, '${_tests.where((t) => t.status == "DRAFT").length}', 'Drafts'),
        ]),
      ]),
    ),
  );

  Widget _miniStat(AppThemeData t, String val, String lbl) => Expanded(
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

  Widget _testCard(AppThemeData t, _Test test) {
    final statusColor = test.status == 'PUBLISHED' ? t.greenAccent
        : test.status == 'CLOSED' ? t.redText : t.muted;
    final statusBg = test.status == 'PUBLISHED' ? t.greenBg
        : test.status == 'CLOSED' ? t.redBg : t.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(test.title, style: TextStyle(
              color: t.text, fontWeight: FontWeight.w700, fontSize: 15),
              overflow: TextOverflow.ellipsis)),
          _Badge(test.status, fg: statusColor, bg: statusBg),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 14, children: [
          if (test.subject != null) _meta(t, '📚', test.subject!),
          if (test.form != null)    _meta(t, '🎓', test.form!),
          if (test.duration != null) _meta(t, '⏱', test.duration!),
          _meta(t, '❓', '${test.questions.length} questions'),
          _meta(t, '📊', '${test.totalMarks} marks'),
          _meta(t, '📅', test.formattedDate),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _push(_SubmissionsScreen(test: test, onBack: _pop)),
            icon: const Icon(Icons.list_alt, size: 16),
            label: const Text('Submissions', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: t.blueText,
              side: BorderSide(color: t.blueText),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            onPressed: () => _push(_CreateTestScreen(editingTest: test, onDone: _pop)),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.surface,
              foregroundColor: t.text,
              side: BorderSide(color: t.border),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )),
        ]),
      ])),
    );
  }

  Widget _meta(AppThemeData t, String icon, String val) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 3),
        Text(val, style: TextStyle(color: t.muted, fontSize: 11)),
      ]);
}

// ─── Create / Edit Test Screen ────────────────────────────────────────────────

class _CreateTestScreen extends StatefulWidget {
  final _Test?                          editingTest;
  final void Function({bool refresh})   onDone;
  const _CreateTestScreen({this.editingTest, required this.onDone});
  @override
  State<_CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<_CreateTestScreen> {
  int  _step = 1;
  bool _generating = false, _saving = false;

  String _genSubject = 'Biology', _genForm = 'Form 1', _genTopic = '', _genCount = '5';

  late String _title, _subject, _form, _duration, _instructions, _status;
  late List<_TQuestion> _questions;

  @override
  void initState() {
    super.initState();
    final test    = widget.editingTest;
    _title        = test?.title    ?? '';
    _subject      = test?.subject  ?? 'Biology';
    _form         = test?.form     ?? 'Form 1';
    _duration     = test?.duration ?? '60 minutes';
    _instructions = 'Answer all questions. Show your working where appropriate.';
    _questions    = test?.questions.map((q) => q.copy()).toList() ?? [];
    _status       = test?.status   ?? 'DRAFT';
    if (test != null) _step = 2;
  }

  List<String> get _topics => _subjectTopics[_genSubject] ?? [];

  Future<void> _generate() async {
    if (_genTopic.isEmpty) { _toast(context, 'Please select a topic.', error: true); return; }
    setState(() => _generating = true);
    try {
      final h = await authHeaders();
      final r = await http.post(
        Uri.parse('$kApiBase/structured-tests/generate-questions'),
        headers: h,
        body: jsonEncode({'subject':_genSubject,'form':_genForm,
          'topic':_genTopic,'count':int.tryParse(_genCount) ?? 5}),
      );
      if (r.statusCode < 300) {
        final d = jsonDecode(r.body);
        setState(() {
          _questions = (d['questions'] as List)
              .map((q) => _TQuestion.fromJson(q as Map<String,dynamic>)).toList();
          _subject = _genSubject;
          _form    = _genForm;
          if (_title.isEmpty) _title = '$_genSubject — $_genTopic ($_genForm)';
          _step = 2;
        });
      } else {
        _toast(context, 'Generation failed.', error: true);
      }
    } catch(e) { _toast(context, 'Error: $e', error: true); }
    finally { if (mounted) setState(() => _generating = false); }
  }

  Future<void> _save(String publishStatus) async {
    if (_title.trim().isEmpty || _questions.isEmpty) {
      _toast(context, 'Title and at least one question required.', error: true); return;
    }
    setState(() => _saving = true);
    try {
      final h      = await authHeaders();
      final url    = widget.editingTest != null
          ? '$kApiBase/structured-tests/${widget.editingTest!.id}'
          : '$kApiBase/structured-tests';
      final method = widget.editingTest != null ? 'PATCH' : 'POST';
      final body   = jsonEncode({
        'title':_title,'subject':_subject,'form':_form,
        'duration':_duration,'instructions':_instructions,
        'questions':_questions.map((q) => q.toJson()).toList(),
        'status':publishStatus,
      });
      final r = method == 'POST'
          ? await http.post(Uri.parse(url),  headers: h, body: body)
          : await http.patch(Uri.parse(url), headers: h, body: body);
      if (r.statusCode < 300) {
        _toast(context, publishStatus == 'PUBLISHED' ? 'Test published!' : 'Draft saved.');
        widget.onDone(refresh: true);
      } else {
        final d = jsonDecode(r.body);
        _toast(context, d['message']?.toString() ?? 'Failed.', error: true);
      }
    } catch(e) { _toast(context, 'Error: $e', error: true); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext ctx) {
    final t = AppTheme.of(ctx);
    context.watch<ThemeManager>();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        foregroundColor: t.text,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onDone(refresh: false),
        ),
        title: Text(
          widget.editingTest != null ? 'Edit Test' : 'Create Test',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_step == 2) TextButton(
            onPressed: () => setState(() => _step = 1),
            child: Text('🤖 Re-gen', style: TextStyle(color: t.blueText, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          if (_step == 1) _buildGenStep(t),
          if (_step == 2) _buildEditStep(t),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildGenStep(AppThemeData t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Card(
        borderColor: t.primary,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🤖 Generate with AI', style: TextStyle(
              color: t.primary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _lbl(t, 'Subject'),
          _ddField(t,
            value: _genSubject,
            items: _subjectTopics.keys.toList(),
            onChanged: (v) { setState(() { _genSubject = v!; _genTopic = ''; }); },
          ),
          const SizedBox(height: 10),
          _lbl(t, 'Form'),
          _ddField(t,
            value: _genForm,
            items: ['Form 1','Form 2','Form 3','Form 4'],
            onChanged: (v) => setState(() => _genForm = v!),
          ),
          const SizedBox(height: 10),
          _lbl(t, 'Topic'),
          _ddField(t,
            value: _topics.contains(_genTopic) ? _genTopic : null,
            hint: 'Select topic',
            items: _topics,
            onChanged: (v) => setState(() => _genTopic = v ?? ''),
          ),
          const SizedBox(height: 10),
          _lbl(t, 'Number of questions'),
          TextField(
            controller: TextEditingController(text: _genCount),
            keyboardType: TextInputType.number,
            style: TextStyle(color: t.text, fontSize: 13),
            decoration: _themedInputDec(t, '5'),
            onChanged: (v) => _genCount = v,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(width:16, height:16,
                      child: CircularProgressIndicator(strokeWidth:2, color:Colors.white))
                  : const Icon(Icons.smart_toy),
              label: Text(_generating ? 'Generating…' : 'Generate Questions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () {
                _questions = [_TQuestion(id: 'q${DateTime.now().millisecondsSinceEpoch}')];
                setState(() => _step = 2);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: t.muted,
                side: BorderSide(color: t.border),
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Manual'),
            ),
          ]),
        ]),
      ),
    ],
  );

  Widget _buildEditStep(AppThemeData t) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Meta card
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Test Details', style: TextStyle(
            color: t.primary, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _lbl(t, 'Title *'),
        TextField(
          controller: TextEditingController(text: _title),
          style: TextStyle(color: t.text, fontSize: 13),
          decoration: _themedInputDec(t, 'e.g. Biology End of Term Test'),
          onChanged: (v) => _title = v,
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl(t, 'Subject'),
            TextField(
              controller: TextEditingController(text: _subject),
              style: TextStyle(color: t.text, fontSize: 13),
              decoration: _themedInputDec(t, 'Subject'),
              onChanged: (v) => _subject = v,
            ),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl(t, 'Form'),
            TextField(
              controller: TextEditingController(text: _form),
              style: TextStyle(color: t.text, fontSize: 13),
              decoration: _themedInputDec(t, 'Form'),
              onChanged: (v) => _form = v,
            ),
          ])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl(t, 'Duration'),
            TextField(
              controller: TextEditingController(text: _duration),
              style: TextStyle(color: t.text, fontSize: 13),
              decoration: _themedInputDec(t, '60 minutes'),
              onChanged: (v) => _duration = v,
            ),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl(t, 'Total marks'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal:12, vertical:12),
              decoration: BoxDecoration(
                color: t.inputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.textFieldBorder),
              ),
              child: Text(
                '${_questions.fold(0, (s, q) => s + q.marks)}',
                style: TextStyle(color: t.primary, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ])),
        ]),
      ])),
      const SizedBox(height: 14),

      // Questions header
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Questions (${_questions.length})',
            style: TextStyle(color: t.text, fontSize: 14, fontWeight: FontWeight.w700)),
        TextButton.icon(
          onPressed: () => setState(() => _questions.add(
              _TQuestion(id: 'q${DateTime.now().millisecondsSinceEpoch}'))),
          icon: Icon(Icons.add, color: t.primary, size: 16),
          label: Text('Add', style: TextStyle(color: t.primary, fontSize: 13)),
        ),
      ]),
      const SizedBox(height: 8),

      ..._questions.asMap().entries.map((e) => _QuestionCard(
        q: e.value, index: e.key,
        canRemove: _questions.length > 1,
        onChange: (q) { setState(() => _questions[e.key] = q); },
        onRemove: ()  { setState(() => _questions.removeAt(e.key)); },
      )),
      const SizedBox(height: 16),

      // Save buttons
      _Card(child: Column(children: [
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: _saving ? null : () => _save('DRAFT'),
            style: OutlinedButton.styleFrom(
              foregroundColor: t.muted,
              side: BorderSide(color: t.border),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('💾 Save Draft'),
          )),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: _saving ? null : () => _save('PUBLISHED'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_saving ? 'Saving…' :
              widget.editingTest?.status == 'PUBLISHED'
                ? '✅ Save & Keep Published' : '🚀 Publish'),
          )),
        ]),
        if (widget.editingTest?.status == 'PUBLISHED') ...[
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton(
            onPressed: _saving ? null : () => _save('CLOSED'),
            style: OutlinedButton.styleFrom(
              foregroundColor: t.redText,
              side: BorderSide(color: t.redText),
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('🔒 Close Test'),
          )),
        ],
      ])),
    ],
  );

  Widget _lbl(AppThemeData t, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(label, style: TextStyle(color: t.subtle, fontSize: 11)),
  );

  Widget _ddField(AppThemeData t, {
    required String? value, String? hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) => DropdownButtonFormField<String>(
    value: items.contains(value) ? value : null,
    dropdownColor: t.surface,
    style: TextStyle(color: t.text, fontSize: 13),
    decoration: _themedInputDec(t, hint ?? ''),
    hint: hint != null ? Text(hint, style: TextStyle(color: t.subtle, fontSize: 13)) : null,
    items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
    onChanged: onChanged,
  );
}

// ─── Question editor card ─────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final _TQuestion q;
  final int index;
  final bool canRemove;
  final ValueChanged<_TQuestion> onChange;
  final VoidCallback onRemove;
  const _QuestionCard({required this.q, required this.index, required this.canRemove,
    required this.onChange, required this.onRemove});

  @override
  Widget build(BuildContext ctx) {
    final t = AppTheme.of(ctx);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: t.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border(bottom: BorderSide(color: t.border)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: t.greenBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Q${index + 1}', style: TextStyle(
                  color: t.greenAccent, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            const Spacer(),
            if (canRemove) GestureDetector(
              onTap: onRemove,
              child: Text('✕ Remove', style: TextStyle(color: t.redText, fontSize: 12)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: TextEditingController(text: q.text),
              maxLines: 2,
              style: TextStyle(color: t.text, fontSize: 13),
              decoration: _themedInputDec(t, 'Question text…'),
              onChanged: (v) { final n = q.copy(); n.text = v; onChange(n); },
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Type', style: TextStyle(color: t.subtle, fontSize: 11)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: q.type,
                  dropdownColor: t.surface,
                  style: TextStyle(color: t.text, fontSize: 12),
                  decoration: _themedInputDec(t, ''),
                  items: ['short','structured','long'].map((type) =>
                    DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (v) { final n = q.copy(); n.type = v ?? q.type; onChange(n); },
                ),
              ])),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Marks', style: TextStyle(color: t.subtle, fontSize: 11)),
                const SizedBox(height: 4),
                TextField(
                  controller: TextEditingController(text: '${q.marks}'),
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: t.text, fontSize: 13),
                  decoration: _themedInputDec(t, '2'),
                  onChanged: (v) { final n = q.copy(); n.marks = int.tryParse(v) ?? q.marks; onChange(n); },
                ),
              ])),
            ]),
            const SizedBox(height: 10),
            Text('Marking guidance (private)', style: TextStyle(color: t.subtle, fontSize: 11)),
            const SizedBox(height: 4),
            TextField(
              controller: TextEditingController(text: q.markingGuidance),
              maxLines: 2,
              style: TextStyle(color: t.muted, fontSize: 12),
              decoration: _themedInputDec(t, 'Key points the answer must include…'),
              onChanged: (v) { final n = q.copy(); n.markingGuidance = v; onChange(n); },
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Submissions list ─────────────────────────────────────────────────────────

class _SubmissionsScreen extends StatefulWidget {
  final _Test test;
  final void Function({bool refresh}) onBack;
  const _SubmissionsScreen({required this.test, required this.onBack});
  @override
  State<_SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<_SubmissionsScreen> {
  List<_Submission> _subs    = [];
  bool              _loading = true;
  _Submission?      _marking;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final h = await authHeaders();
      final r = await http.get(
        Uri.parse('$kApiBase/structured-tests/${widget.test.id}/submissions'), headers: h);
      if (r.statusCode < 300 && mounted)
        setState(() => _subs = (jsonDecode(r.body) as List)
            .map((e) => _Submission.fromJson(e as Map<String,dynamic>)).toList());
    } catch(_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext ctx) {
    if (_marking != null) return _MarkScreen(
      submission: _marking!, test: widget.test,
      onBack: ({bool refresh=false}) {
        setState(() => _marking = null);
        if (refresh) _fetch();
      },
    );

    final t       = AppTheme.of(ctx);
    context.watch<ThemeManager>();
    final marked  = _subs.where((s) => s.status == 'MARKED').length;
    final pending = _subs.length - marked;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        foregroundColor: t.text,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onBack(refresh: false),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.test.title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
          Text('$marked marked · $pending pending',
              style: TextStyle(color: t.muted, fontSize: 11)),
        ]),
      ),
      body: RefreshIndicator(
        color: t.primary,
        onRefresh: _fetch,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: t.primary))
            : _subs.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('📭', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('No submissions yet.', style: TextStyle(color: t.muted)),
                    ])))
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _subs.length,
                    itemBuilder: (_, i) => _subCard(t, _subs[i]),
                  ),
      ),
    );
  }

  Widget _subCard(AppThemeData t, _Submission s) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    child: _Card(child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.studentName ?? 'Student', style: TextStyle(
            color: t.text, fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: [
          if (s.status == 'MARKED') ...[
            _Badge('Marked', fg: t.greenAccent, bg: t.greenBg),
            _Badge('${s.totalScore}/${widget.test.totalMarks} — ${s.percentage}%',
                fg: t.blueText, bg: t.blueBg),
          ] else
            _Badge('Awaiting', fg: t.amberText, bg: t.amberBg),
          Text(s.formattedDate, style: TextStyle(color: t.subtle, fontSize: 11)),
        ]),
      ])),
      const SizedBox(width: 10),
      ElevatedButton(
        onPressed: () => setState(() => _marking = s),
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(s.status == 'MARKED' ? 'Review' : 'Mark',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ])),
  );
}

// ─── Mark submission screen ───────────────────────────────────────────────────

class _MarkScreen extends StatefulWidget {
  final _Submission submission;
  final _Test       test;
  final void Function({bool refresh}) onBack;
  const _MarkScreen({required this.submission, required this.test, required this.onBack});
  @override
  State<_MarkScreen> createState() => _MarkScreenState();
}

class _MarkScreenState extends State<_MarkScreen> {
  late List<Map<String,dynamic>> _marks;
  late String _comment;
  bool _aiLoading = false, _saving = false;

  @override
  void initState() {
    super.initState();
    _comment = '';
    _marks = widget.test.questions.map((q) {
      final ex = widget.submission.finalMarks
          .firstWhere((m) => m['questionId'] == q.id, orElse: () => {});
      final ai = widget.submission.aiMarking
          .firstWhere((m) => m['questionId'] == q.id, orElse: () => {});
      return {
        'questionId': q.id,
        'mark':       ex['mark']     ?? ai['suggestedMark'] ?? 0,
        'feedback':   ex['feedback'] ?? ai['feedback']      ?? '',
      };
    }).toList();
  }

  Future<void> _runAI() async {
    setState(() => _aiLoading = true);
    try {
      final h = await authHeaders();
      final r = await http.post(
        Uri.parse('$kApiBase/structured-tests/submissions/${widget.submission.id}/ai-mark'),
        headers: h,
      );
      if (r.statusCode < 300) {
        final d  = jsonDecode(r.body);
        final ai = List<Map<String,dynamic>>.from(d['aiMarking'] ?? []);
        setState(() => _marks = _marks.map((m) {
          final a = ai.firstWhere((a) => a['questionId'] == m['questionId'], orElse: () => {});
          if (a.isEmpty) return m;
          return {...m, 'mark': a['suggestedMark'], 'feedback': a['feedback']};
        }).toList());
        _toast(context, 'AI suggestions loaded — review before saving.');
      } else {
        _toast(context, 'AI marking failed.', error: true);
      }
    } catch(e) { _toast(context, 'Error: $e', error: true); }
    finally { if (mounted) setState(() => _aiLoading = false); }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final h = await authHeaders();
      final r = await http.patch(
        Uri.parse('$kApiBase/structured-tests/submissions/${widget.submission.id}/final-marks'),
        headers: h,
        body: jsonEncode({'finalMarks': _marks, 'teacherComment': _comment}),
      );
      if (r.statusCode < 300) {
        _toast(context, 'Marks saved!');
        widget.onBack(refresh: true);
      } else {
        _toast(context, 'Failed to save.', error: true);
      }
    } catch(e) { _toast(context, 'Error: $e', error: true); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  int get _totalAwarded =>
      _marks.fold(0, (s, m) => (s + (m['mark'] as num)).toInt());

  @override
  Widget build(BuildContext ctx) {
    final t = AppTheme.of(ctx);
    context.watch<ThemeManager>();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        foregroundColor: t.text,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onBack(refresh: false),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Marking: ${widget.submission.studentName ?? 'Student'}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(widget.test.title,
              style: TextStyle(color: t.muted, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: Text(
              '$_totalAwarded/${widget.test.totalMarks}',
              style: TextStyle(color: t.primary, fontWeight: FontWeight.w800, fontSize: 16),
            )),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        // AI button
        ElevatedButton.icon(
          onPressed: _aiLoading ? null : _runAI,
          icon: _aiLoading
              ? const SizedBox(width:16, height:16,
                  child: CircularProgressIndicator(strokeWidth:2, color:Colors.white))
              : const Icon(Icons.smart_toy),
          label: Text(_aiLoading ? 'AI is marking…' : '🤖 Get AI Suggestions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: t.blueBg,
            foregroundColor: t.blueText,
            side: BorderSide(color: t.blueText),
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 14),

        // Per-question marking
        ...widget.test.questions.asMap().entries.map((e) {
          final q   = e.value;
          final i   = e.key;
          final m   = _marks[i];
          final ans = widget.submission.answers
              .firstWhere((a) => a['questionId'] == q.id, orElse: () => {})['answer']
              ?.toString() ?? '(no answer)';
          final ai  = widget.submission.aiMarking
              .firstWhere((a) => a['questionId'] == q.id, orElse: () => {});

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text('Q${i+1}. ${q.text}', style: TextStyle(
                    color: t.text, fontWeight: FontWeight.w600, fontSize: 13))),
                _Badge('${q.marks} marks'),
              ]),
              const SizedBox(height: 10),

              // Student answer
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Student answer', style: TextStyle(
                      color: t.subtle, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(ans, style: TextStyle(color: t.text, fontSize: 13)),
                ]),
              ),

              // Marking guidance
              if (q.markingGuidance.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.greenBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.greenBgBorder.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Marking guidance', style: TextStyle(
                        color: t.subtle, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(q.markingGuidance,
                        style: TextStyle(color: t.greenAccent, fontSize: 12)),
                  ]),
                ),
              ],

              // AI suggestion
              if (ai.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.blueBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.blueText.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('🤖 AI suggests', style: TextStyle(
                          color: t.blueText, fontSize: 10, fontWeight: FontWeight.w700)),
                      _Badge('${ai['suggestedMark']}/${ai['maxMark']}',
                          fg: t.blueText, bg: t.blueBg),
                    ]),
                    const SizedBox(height: 4),
                    Text(ai['feedback']?.toString() ?? '',
                        style: TextStyle(color: t.muted, fontSize: 12)),
                  ]),
                ),
              ],
              const SizedBox(height: 10),

              // Mark + feedback inputs
              Row(children: [
                SizedBox(width: 90, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mark', style: TextStyle(color: t.subtle, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: '${m['mark']}',
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: t.text, fontSize: 13),
                    decoration: _themedInputDec(t, '0'),
                    onChanged: (v) {
                      final n = Map<String,dynamic>.from(m);
                      n['mark'] = int.tryParse(v) ?? 0;
                      setState(() => _marks[i] = n);
                    },
                  ),
                ])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Feedback', style: TextStyle(color: t.subtle, fontSize: 11)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: m['feedback']?.toString() ?? '',
                    style: TextStyle(color: t.text, fontSize: 13),
                    decoration: _themedInputDec(t, 'Write feedback…'),
                    onChanged: (v) {
                      final n = Map<String,dynamic>.from(m);
                      n['feedback'] = v;
                      setState(() => _marks[i] = n);
                    },
                  ),
                ])),
              ]),
            ])),
          );
        }),

        // Overall comment
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Overall comment', style: TextStyle(color: t.subtle, fontSize: 11)),
          const SizedBox(height: 6),
          TextField(
            maxLines: 3,
            style: TextStyle(color: t.text, fontSize: 13),
            decoration: _themedInputDec(t, 'Overall comments on student performance…'),
            onChanged: (v) => _comment = v,
          ),
        ])),
        const SizedBox(height: 14),

        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: t.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            _saving ? 'Saving…' : '✅ Save Marks ($_totalAwarded/${widget.test.totalMarks})',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}