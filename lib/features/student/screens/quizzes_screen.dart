import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:elibrary_smartapp/features/student/screens/structured_tests_tab.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

// ─── Subject / topic map (unchanged) ─────────────────────────────────────────

const Map<String, List<String>> _subjectTopics = {
  'Biology': ['Cell Structure and Function','Cell Division (Mitosis and Meiosis)','Photosynthesis','Respiration','Transport in Plants','Transport in Animals (Circulatory System)','Nutrition in Plants','Nutrition in Animals (Human Digestive System)','Excretion in Humans','Nervous System','Endocrine System','Reproduction in Plants','Reproduction in Humans','Genetics and Heredity','Evolution and Natural Selection','Ecology and Ecosystems','Classification of Living Things','Disease and Immunity','Biotechnology','Environmental Issues in Malawi'],
  'Mathematics': ['Number and Numeration','Fractions, Decimals and Percentages','Ratio and Proportion','Algebra: Simplification and Expansion','Linear Equations','Simultaneous Equations','Quadratic Equations','Inequalities','Functions and Graphs','Sequences and Series','Geometry: Lines and Angles','Triangles and Congruence','Circle Theorems','Mensuration: Area and Perimeter','Mensuration: Volume and Surface Area','Trigonometry','Vectors','Matrices','Statistics: Mean, Median and Mode','Probability'],
  'Chemistry': ['Atomic Structure','The Periodic Table','Chemical Bonding (Ionic and Covalent)','States of Matter','Chemical Reactions and Equations','Acids, Bases and Salts','Oxidation and Reduction (Redox)','Electrochemistry','Rates of Reaction','Energy Changes in Reactions','The Mole Concept','Gases and Gas Laws','Water and Solutions','Metals and Non-Metals','Carbon and Its Compounds','Organic Chemistry: Alkanes and Alkenes','Organic Chemistry: Alcohols and Acids','Polymers and Plastics','Environmental Chemistry','Industrial Chemistry in Malawi'],
  'Physics': ['Measurements and Units','Motion: Speed, Velocity and Acceleration','Newton\'s Laws of Motion','Forces and Equilibrium','Work, Energy and Power','Momentum and Collisions','Pressure in Solids, Liquids and Gases','Heat and Temperature','Thermal Expansion','Transfer of Heat','Waves: Properties and Types','Sound Waves','Light: Reflection','Light: Refraction and Lenses','Electricity: Current and Circuits','Ohm\'s Law and Resistance','Magnetism and Electromagnetism','Electromagnetic Induction','Radioactivity','Electronics and Logic Gates'],
  'English': ['Reading Comprehension','Summary Writing','Essay Writing: Argumentative','Essay Writing: Descriptive','Essay Writing: Narrative','Letter Writing: Formal','Letter Writing: Informal','Report Writing','Grammar: Parts of Speech','Grammar: Tenses','Grammar: Active and Passive Voice','Grammar: Direct and Indirect Speech','Vocabulary and Word Formation','Punctuation and Spelling','Poetry: Analysis and Appreciation','Prose: Novel Study','Drama: Play Study','Oral Communication Skills','Debate and Discussion','Literature in Malawian Context'],
  'Geography': ['Map Reading and Interpretation','Weather and Climate','Climate Regions of Malawi','Malawi: Physical Features','Malawi: Lake Malawi','Malawi: Rivers and Water Resources','Population Distribution in Malawi','Rural and Urban Settlements','Agriculture in Malawi','Cash Crops: Tobacco, Tea and Sugar','Fishing Industry in Malawi','Mining and Natural Resources','Transport and Communication in Malawi','Trade and Economic Development','Africa: Physical Geography','Africa: Political Geography','Plate Tectonics and Earthquakes','Volcanoes','Soil Types and Erosion','Environmental Conservation in Malawi'],
  'History': ['Early Peoples of Malawi','Migration and Settlement of Bantu People','Maravi Kingdom','Ngoni Migration and Settlement','Yao and Arab Slave Trade','European Exploration of Africa','Livingstone and Missionaries in Malawi','British Central Africa Protectorate','Colonial Administration in Nyasaland','Resistance to Colonial Rule','John Chilembwe Rising 1915','Nyasaland African Congress','Federation of Rhodesia and Nyasaland','Malawi Congress Party and Independence','Dr Hastings Kamuzu Banda and Independence 1964','One Party State in Malawi','Multiparty Democracy 1993','Post-Independence Development in Malawi','Africa: Colonisation and Independence','World War I and World War II'],
  'Civic Education': ['Citizenship and Responsibilities','Human Rights','Children\'s Rights in Malawi','The Constitution of Malawi','Branches of Government','The Executive: President and Cabinet','The Legislature: Parliament of Malawi','The Judiciary and Rule of Law','Local Government in Malawi','Elections and Democracy','Political Parties in Malawi','Gender Equality and Equity','HIV and AIDS Awareness','Drug and Substance Abuse','Environmental Rights and Duties','Community Development','Conflict Resolution','National Symbols of Malawi','Regional and International Organisations (AU, SADC, UN)','Corruption and Good Governance'],
  'Computer Studies': ['Introduction to Computers','Computer Hardware Components','Computer Software: System and Application','Operating Systems','File Management','Word Processing (Microsoft Word)','Spreadsheets (Microsoft Excel)','Presentation Software (Microsoft PowerPoint)','Database Concepts','Internet and Email','World Wide Web and Browsers','Computer Networks and Types','Network Security and Cyber Safety','Introduction to Programming','Algorithms and Flowcharts','Basic Programming in Python','HTML and Web Design Basics','Data Representation (Binary and Hexadecimal)','ICT in Society and Development','ICT in Malawi: E-government and Mobile Money'],
};

const _levels = ['Form 1', 'Form 2', 'Form 3', 'Form 4'];

const Map<String, Color> _subjectColors = {
  'Biology':         Color(0xFF10B981),
  'Mathematics':     Color(0xFF34D399),
  'Chemistry':       Color(0xFFA371F7),
  'Physics':         Color(0xFFF0883E),
  'English':         Color(0xFFE3B341),
  'Geography':       Color(0xFF6EE7B7),
  'History':         Color(0xFFDA3633),
  'Civic Education': Color(0xFF059669),
  'Computer Studies':Color(0xFF0D9488),
};

// ─── Models (unchanged) ───────────────────────────────────────────────────────

class _Question {
  final String       text;
  final List<String> options;
  final int          correct;

  const _Question({required this.text, required this.options, required this.correct});

  factory _Question.fromJson(Map<String, dynamic> j) => _Question(
    text:    j['question']?.toString() ?? j['text']?.toString() ?? '',
    options: List<String>.from(j['options'] as List? ?? []),
    correct: (j['correct'] ?? j['answer']) as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {'question': text, 'options': options, 'correct': correct};
}

class _SavedQuiz {
  final String          id;
  final String          title;
  final String?         subject;
  final String?         form;
  final String?         description;
  final String?         visibility;
  final List<_Question> questions;
  final DateTime?       createdAt;

  const _SavedQuiz({
    required this.id, required this.title, this.subject, this.form,
    this.description, this.visibility, required this.questions, this.createdAt,
  });

  factory _SavedQuiz.fromJson(Map<String, dynamic> j) {
    DateTime? ca;
    try { if (j['createdAt'] is String) ca = DateTime.parse(j['createdAt']); } catch (_) {}
    return _SavedQuiz(
      id:          j['id']?.toString()    ?? '',
      title:       j['title']?.toString() ?? 'Quiz',
      subject:     j['subject']?.toString(),
      form:        j['form']?.toString(),
      description: j['description']?.toString(),
      visibility:  j['visibility']?.toString(),
      questions:   (j['questions'] as List? ?? []).map((q) => _Question.fromJson(q as Map<String, dynamic>)).toList(),
      createdAt:   ca,
    );
  }

  String get formattedDate {
    if (createdAt == null) return '—';
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${createdAt!.day} ${m[createdAt!.month]} ${createdAt!.year}';
  }
}

class _Attempt {
  final String?   id;
  final String    subject;
  final String?   topic;
  final String?   level;
  final String    source;
  final int       score;
  final int       total;
  final int       percentage;
  final String?   quizId;
  final DateTime? completedAt;

  const _Attempt({
    this.id, required this.subject, this.topic, this.level,
    required this.source, required this.score, required this.total,
    required this.percentage, this.quizId, this.completedAt,
  });

  factory _Attempt.fromJson(Map<String, dynamic> j) {
    DateTime? ca;
    try { if (j['completedAt'] is String) ca = DateTime.parse(j['completedAt']); } catch (_) {}
    return _Attempt(
      id:          j['id']?.toString(),
      subject:     j['subject']?.toString() ?? '',
      topic:       j['topic']?.toString(),
      level:       j['level']?.toString(),
      source:      j['source']?.toString() ?? '',
      score:       (j['score']      as num?)?.toInt() ?? 0,
      total:       (j['total']      as num?)?.toInt() ?? 0,
      percentage:  (j['percentage'] as num?)?.toInt() ?? 0,
      quizId:      j['quizId']?.toString(),
      completedAt: ca,
    );
  }

  String get formattedDate {
    if (completedAt == null) return '';
    final d = completedAt!;
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }
}

// ─── Toast helper ─────────────────────────────────────────────────────────────

enum _ToastType { success, info, warning, error }

void _showToast(BuildContext context, String msg, [_ToastType type = _ToastType.success]) {
  const primary = Color(0xFF10B981);
  final colors = {
    _ToastType.success: (primary,                    const Color(0xFF064E3B)),
    _ToastType.info:    (const Color(0xFF34D399),    const Color(0xFF022C22)),
    _ToastType.warning: (const Color(0xFFF59E0B),    const Color(0xFF3D2E0A)),
    _ToastType.error:   (const Color(0xFFF85149),    const Color(0xFF3D1F1F)),
  };
  final icons = {
    _ToastType.success: '✅',
    _ToastType.info:    'ℹ️',
    _ToastType.warning: '⚡',
    _ToastType.error:   '⚠️',
  };
  final (fg, bg) = colors[type]!;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    duration: const Duration(seconds: 4),
    backgroundColor: bg,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: fg),
    ),
    content: Row(children: [
      Text(icons[type]!, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  ));
}

// ─── API helpers ──────────────────────────────────────────────────────────────

Future<void> _logAttempt({
  required String source,
  String?         quizId,
  required String subject,
  required String topic,
  required String level,
  required int    score,
  required int    total,
  required int    percentage,
}) async {
  try {
    final headers = await authHeaders();
    await http.post(
      Uri.parse('$kApiBase/quizzes/attempts'),
      headers: headers,
      body: jsonEncode({
        'source': source,
        if (quizId != null) 'quizId': quizId,
        'subject': subject, 'topic': topic, 'level': level,
        'score': score, 'total': total, 'percentage': percentage,
      }),
    );
  } catch (_) {}
}

// ─── Main screen ──────────────────────────────────────────────────────────────

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  static void jumpToTab(int index) => _QuizzesScreenState._jump(index);

  @override State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static _QuizzesScreenState? _instance;
  static void _jump(int i) => _instance?._tabs.animateTo(i);

  @override
  void initState() {
    super.initState();
    _instance = this;
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        title: Text('🧠 Quizzes', style: TextStyle(color: t.text)),
        backgroundColor: t.bg,
        foregroundColor: t.text,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: t.text,
          unselectedLabelColor: t.muted,
          indicatorColor: t.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: '🤖 AI Quiz'),
            Tab(text: '💾 Saved AI'),
            Tab(text: '👩‍🏫 Teacher'),
            Tab(text: '📝 Tests'),
            Tab(text: '📊 Progress'),
            Tab(text: '🕐 History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AITab(),
          _SavedAITab(),
          _TeacherTab(),
          StructuredTestsTab(),
          _ProgressTab(),
          _HistoryTab(),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _ProgressBar extends StatefulWidget {
  final int   value;
  final Color? color;
  const _ProgressBar({required this.value, this.color});
  @override State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double _width = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _width = widget.value.toDouble());
    });
  }

  Color _resolveColor(AppThemeData t) {
    final base = widget.color ?? t.primary;
    if (widget.value >= 75) return base;
    if (widget.value >= 50) return t.amber;
    return t.danger;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _width / 100,
        backgroundColor: t.border,
        valueColor: AlwaysStoppedAnimation<Color>(_resolveColor(t)),
        minHeight: 6,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.surface, border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _Tag extends StatelessWidget {
  final String label; final Color? fg; final Color? bg; final bool outlined;
  const _Tag({required this.label, this.fg, this.bg, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bg,
        border: outlined ? Border.all(color: t.border) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600,
        color: outlined ? t.subtle : fg,
      )),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String label; final String? value; final List<String> items;
  final ValueChanged<String?>? onChanged;
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final safe = (value != null && items.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      value: safe, isExpanded: true, dropdownColor: t.surface,
      style: TextStyle(color: t.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: t.muted),
        filled: true, fillColor: t.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      hint: Text(label, style: TextStyle(color: t.muted, fontSize: 14)),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}

// ─── Quiz Runner ──────────────────────────────────────────────────────────────

class _QuizRunner extends StatefulWidget {
  final List<_Question> questions;
  final String subject, level, topic, source;
  final String?       quizId;
  final bool          isSaved;
  final VoidCallback  onDone;

  const _QuizRunner({
    required this.questions, required this.subject, required this.level,
    required this.topic, required this.source, required this.onDone,
    this.quizId, this.isSaved = false,
  });

  @override State<_QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<_QuizRunner> {
  final Map<int, int> _answers = {};
  int?  _score;
  bool  _autoSaveFired = false;

  void _select(int qi, int oi) {
    if (_score != null) return;
    setState(() => _answers[qi] = oi);
  }

  Future<void> _submit() async {
    if (_answers.length < widget.questions.length) {
      final missing = widget.questions.length - _answers.length;
      _showToast(context,
        'Please answer all questions. $missing question${missing > 1 ? "s" : ""} still unanswered.',
        _ToastType.warning,
      );
      return;
    }

    var correct = 0;
    for (var i = 0; i < widget.questions.length; i++) {
      if (_answers[i] == widget.questions[i].correct) correct++;
    }
    setState(() => _score = correct);

    final pct = ((correct / widget.questions.length) * 100).round();

    await _logAttempt(
      source: widget.source, quizId: widget.quizId,
      subject: widget.subject, topic: widget.topic, level: widget.level,
      score: correct, total: widget.questions.length, percentage: pct,
    );

    if (widget.source == 'AI' && !widget.isSaved && !_autoSaveFired && mounted) {
      _autoSaveFired = true;
      try {
        final headers = await authHeaders();
        final res = await http.post(
          Uri.parse('$kApiBase/quizzes/save-ai'),
          headers: headers,
          body: jsonEncode({
            'subject':   widget.subject,
            'level':     widget.level,
            'topic':     widget.topic,
            'questions': widget.questions.map((q) => q.toJson()).toList(),
          }),
        );
        if (res.statusCode < 300 && mounted) {
          _showToast(context, 'Quiz saved to your library! Find it in 💾 Saved AI.', _ToastType.info);
        }
      } catch (_) {}
    }
  }

  Color _optionBg(int qi, int oi, AppThemeData t) {
    if (_score == null) return _answers[qi] == oi ? t.primary.withValues(alpha: 0.15) : Colors.transparent;
    final correct  = widget.questions[qi].correct;
    final selected = _answers[qi] == oi;
    if (correct  == oi) return t.primary.withValues(alpha: 0.15);
    if (selected)        return t.danger.withValues(alpha: 0.15);
    return Colors.transparent;
  }

  Color _optionBorder(int qi, int oi, AppThemeData t) {
    if (_score == null) return _answers[qi] == oi ? t.primary : t.border;
    final correct  = widget.questions[qi].correct;
    final selected = _answers[qi] == oi;
    if (correct  == oi) return t.primary;
    if (selected)        return t.danger;
    return t.border;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final answered = _answers.length;
    final total    = widget.questions.length;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text('${widget.subject}  ·  ${widget.level}  ·  ${widget.topic}',
            style: TextStyle(color: t.muted, fontSize: 12)),
        Text('$answered / $total answered',
            style: TextStyle(color: t.subtle, fontSize: 12)),
        const SizedBox(height: 6),
        _ProgressBar(value: total == 0 ? 0 : (answered * 100 ~/ total)),
        const SizedBox(height: 14),

        for (var i = 0; i < total; i++) ...[
          _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${i + 1}. ${widget.questions[i].text}',
                style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            for (var j = 0; j < widget.questions[i].options.length; j++)
              GestureDetector(
                onTap: () => _select(i, j),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _optionBg(i, j, t),
                    border: Border.all(color: _optionBorder(i, j, t)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(
                      _answers[i] == j ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: _answers[i] == j ? t.primary : t.subtle, size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.questions[i].options[j],
                        style: TextStyle(color: t.text))),
                    if (_score != null && widget.questions[i].correct == j)
                      const Text('✅'),
                    if (_score != null && _answers[i] == j && widget.questions[i].correct != j)
                      const Text('❌'),
                  ]),
                ),
              ),
          ])),
          const SizedBox(height: 12),
        ],

        if (_score == null)
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Submit Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.primary,
              minimumSize: const Size.fromHeight(48),
            ),
          )
        else ...[
          _Card(child: Column(children: [
            Text('Quiz Complete! 🎉',
                style: TextStyle(color: t.primary, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Score: $_score / $total  (${((_score! / total) * 100).round()}%)',
              style: TextStyle(color: t.text, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            _ProgressBar(value: ((_score! / total) * 100).round()),
            const SizedBox(height: 6),
            Text(
              _score == total ? 'Perfect! Excellent work!'
              : _score! >= (total * 0.7) ? 'Great job! Keep it up!'
              : 'Good effort! Try again to improve.',
              style: TextStyle(color: t.muted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onDone,
              icon: const Icon(Icons.refresh),
              label: const Text('🔄 Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.primary,
                minimumSize: const Size(180, 44),
              ),
            ),
          ])),
        ],
      ],
    );
  }
}

// ─── AI Tab ───────────────────────────────────────────────────────────────────

class _AITab extends StatefulWidget {
  const _AITab();
  @override State<_AITab> createState() => _AITabState();
}

class _AITabState extends State<_AITab> {
  String? _subject, _level, _topic;
  bool    _loading = false;
  List<_Question>?      _questions;
  Map<String, String>?  _meta;

  List<String> get _topics => _subject == null ? [] : _subjectTopics[_subject] ?? [];

  Future<void> _generate() async {
    if (_subject == null || _level == null || _topic == null) {
      _showToast(context, 'Please select subject, level and topic.', _ToastType.warning);
      return;
    }
    setState(() { _loading = true; _questions = null; _meta = null; });
    try {
      final headers = await authHeaders();
      final res = await http.post(
        Uri.parse('$kApiBase/quizzes/generate'),
        headers: headers,
        body: jsonEncode({'subject': _subject, 'level': _level, 'topic': _topic}),
      );
      if (res.statusCode >= 300) {
        Map<String, dynamic> d = {};
        try { d = jsonDecode(res.body) as Map<String, dynamic>; } catch (_) {}
        _showToast(context, d['message']?.toString() ?? 'Failed to generate quiz (${res.statusCode}).', _ToastType.error);
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final qs   = (data['questions'] as List? ?? [])
          .map((q) => _Question.fromJson(q as Map<String, dynamic>))
          .toList();
      setState(() {
        _questions = qs;
        _meta = {
          'subject': data['subject']?.toString() ?? _subject!,
          'level':   data['level']?.toString()   ?? _level!,
          'topic':   data['topic']?.toString()   ?? _topic!,
        };
      });
    } catch (e) {
      _showToast(context, 'Network error. Check your connection and try again.', _ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    if (_questions != null && _meta != null) {
      return _QuizRunner(
        questions: _questions!,
        subject:   _meta!['subject']!,
        level:     _meta!['level']!,
        topic:     _meta!['topic']!,
        source:    'AI',
        onDone:    () => setState(() { _questions = null; _meta = null; }),
      );
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.psychology_outlined, color: t.primary),
          const SizedBox(width: 10),
          Text('AI Quiz Generator',
              style: TextStyle(color: t.primary, fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 16),
        _Dropdown(
          label: 'Subject', value: _subject,
          items: _subjectTopics.keys.toList(),
          onChanged: _loading ? null : (v) => setState(() { _subject = v; _topic = null; }),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Dropdown(
            label: 'Level', value: _level, items: _levels,
            onChanged: _loading ? null : (v) => setState(() => _level = v),
          )),
          const SizedBox(width: 12),
          Expanded(child: _Dropdown(
            label: _subject == null ? 'Select subject first' : 'Topic',
            value: _topic, items: _topics,
            onChanged: (_loading || _subject == null) ? null : (v) => setState(() => _topic = v),
          )),
        ]),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loading ? null : _generate,
          icon: Icon(_loading ? Icons.hourglass_top : Icons.smart_toy),
          label: Text(_loading ? 'Generating...' : '🤖 Generate Quiz'),
          style: ElevatedButton.styleFrom(
            backgroundColor: t.primary, minimumSize: const Size.fromHeight(48),
          ),
        ),
      ])),
      if (_loading)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(children: [
            CircularProgressIndicator(color: t.primary),
            const SizedBox(height: 12),
            Text('Generating your quiz, please wait…', style: TextStyle(color: t.muted)),
          ]),
        ),
    ]);
  }
}

// ─── Saved AI Tab ─────────────────────────────────────────────────────────────

class _SavedAITab extends StatefulWidget {
  const _SavedAITab();
  @override State<_SavedAITab> createState() => _SavedAITabState();
}

class _SavedAITabState extends State<_SavedAITab> {
  List<_SavedQuiz> _saved    = [];
  List<_Attempt>   _attempts = [];
  bool             _loading  = true;
  String           _search   = '';
  _SavedQuiz?      _retake;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final headers = await authHeaders();
      final results = await Future.wait([
        http.get(Uri.parse('$kApiBase/quizzes/saved-ai'),      headers: headers),
        http.get(Uri.parse('$kApiBase/quizzes/attempts/mine'), headers: headers),
      ]);
      if (!mounted) return;
      if (results[0].statusCode < 300) {
        _saved = (jsonDecode(results[0].body) as List)
            .map((e) => _SavedQuiz.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (results[1].statusCode < 300) {
        _attempts = (jsonDecode(results[1].body) as List)
            .map((e) => _Attempt.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      if (mounted) _showToast(context, 'Failed to load saved quizzes.', _ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      final headers = await authHeaders();
      final res = await http.delete(Uri.parse('$kApiBase/quizzes/$id'), headers: headers);
      if (res.statusCode < 300) {
        setState(() => _saved.removeWhere((q) => q.id == id));
        if (mounted) _showToast(context, 'Quiz deleted.');
      } else {
        if (mounted) _showToast(context, 'Failed to delete quiz.', _ToastType.error);
      }
    } catch (_) {
      if (mounted) _showToast(context, 'Failed to delete quiz.', _ToastType.error);
    }
  }

  Map<String, int> get _lastScoreMap {
    final m = <String, int>{};
    for (final a in _attempts) {
      if (a.quizId != null && !m.containsKey(a.quizId)) {
        m[a.quizId!] = a.percentage;
      }
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    if (_retake != null) {
      return _QuizRunner(
        questions: _retake!.questions,
        subject:   _retake!.subject ?? '',
        level:     _retake!.form    ?? '',
        topic:     _retake!.title,
        source:    'AI',
        quizId:    _retake!.id,
        isSaved:   true,
        onDone:    () => setState(() => _retake = null),
      );
    }

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: t.primary));
    }

    final scoreMap = _lastScoreMap;
    final filtered = _saved.where((q) =>
      (q.subject ?? '').toLowerCase().contains(_search.toLowerCase()) ||
      q.title.toLowerCase().contains(_search.toLowerCase())
    ).toList();

    return RefreshIndicator(
      color: t.primary,
      onRefresh: _fetch,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        TextField(
          style: TextStyle(color: t.text),
          decoration: InputDecoration(
            hintText: 'Search saved quizzes…', hintStyle: TextStyle(color: t.subtle),
            prefixIcon: Icon(Icons.search, color: t.muted),
            filled: true, fillColor: t.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.border)),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(children: [
                const Text('🤖', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('No saved AI quizzes yet.\nGenerate a quiz — it will be saved here automatically.',
                    style: TextStyle(color: t.subtle), textAlign: TextAlign.center),
              ]),
            ),
          )
        else
          ...filtered.map((q) {
            final lastScore = scoreMap[q.id];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 6, children: [
                  if (q.subject != null)
                    _Tag(label: q.subject!, fg: t.primary, bg: t.primary.withValues(alpha: 0.15)),
                  if (q.form != null) _Tag(label: q.form!, outlined: true),
                  _Tag(label: '🤖 AI Saved', fg: t.teal, bg: t.teal.withValues(alpha: 0.15)),
                ]),
                const SizedBox(height: 8),
                Text(q.title,
                    style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 15)),
                Text('${q.questions.length} questions · Saved ${q.formattedDate}',
                    style: TextStyle(color: t.subtle, fontSize: 12)),
                if (lastScore != null) ...[
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Last score', style: TextStyle(color: t.subtle, fontSize: 12)),
                    Text('$lastScore%',
                        style: TextStyle(color: t.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                  _ProgressBar(value: lastScore),
                ],
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _retake = q),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(lastScore != null ? '▶ Retake Quiz' : '▶ Take Quiz',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: t.danger),
                    onPressed: () => _delete(q.id),
                  ),
                ]),
              ])),
            );
          }),
      ]),
    );
  }
}

// ─── Teacher Tab ──────────────────────────────────────────────────────────────

class _TeacherTab extends StatefulWidget {
  const _TeacherTab();
  @override State<_TeacherTab> createState() => _TeacherTabState();
}

class _TeacherTabState extends State<_TeacherTab> {
  List<_SavedQuiz> _online  = [];
  List<_SavedQuiz> _offline = [];
  bool             _loading = true;
  bool             _showOffline = false;
  String           _search  = '';
  _SavedQuiz?      _active;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final headers = await authHeaders();
      final results = await Future.wait([
        http.get(Uri.parse('$kApiBase/quizzes/available'),         headers: headers),
        http.get(Uri.parse('$kApiBase/quizzes/available/offline'), headers: headers),
      ]);
      if (!mounted) return;
      if (results[0].statusCode < 300) {
        _online = (jsonDecode(results[0].body) as List)
            .map((e) => _SavedQuiz.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (results[1].statusCode < 300) {
        _offline = (jsonDecode(results[1].body) as List)
            .map((e) => _SavedQuiz.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      if (mounted) _showToast(context, 'Failed to load quizzes.', _ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_SavedQuiz> get _filtered {
    final list = _showOffline ? _offline : _online;
    if (_search.isEmpty) return list;
    final q = _search.toLowerCase();
    return list.where((quiz) =>
      quiz.title.toLowerCase().contains(q) ||
      (quiz.subject?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    if (_active != null) {
      return _QuizRunner(
        questions: _active!.questions,
        subject:   _active!.subject ?? '',
        level:     _active!.form    ?? '',
        topic:     _active!.title,
        source:    'TEACHER',
        quizId:    _active!.id,
        onDone:    () => setState(() => _active = null),
      );
    }

    return ListView(padding: const EdgeInsets.all(14), children: [
      TextField(
        style: TextStyle(color: t.text),
        decoration: InputDecoration(
          hintText: 'Search quizzes…', hintStyle: TextStyle(color: t.subtle),
          prefixIcon: Icon(Icons.search, color: t.muted),
          filled: true, fillColor: t.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: t.border)),
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _SubTabBtn(label: '🌐 Online', selected: !_showOffline, theme: t,
            onTap: () => setState(() => _showOffline = false))),
        const SizedBox(width: 8),
        Expanded(child: _SubTabBtn(label: '📄 Offline / Print', selected: _showOffline, theme: t,
            onTap: () => setState(() => _showOffline = true))),
      ]),
      const SizedBox(height: 14),
      if (_loading)
        Center(child: CircularProgressIndicator(color: t.primary))
      else if (_filtered.isEmpty)
        Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            _showOffline ? 'No offline quizzes available.' : 'No online quizzes available.',
            style: TextStyle(color: t.subtle),
          ),
        ))
      else
        ..._filtered.map((quiz) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, children: [
              if (quiz.subject != null)
                _Tag(label: quiz.subject!, fg: t.primary, bg: t.primary.withValues(alpha: 0.15)),
              if (quiz.form != null) _Tag(label: quiz.form!, outlined: true),
              _Tag(
                label: quiz.visibility == 'PUBLIC' ? '🌐 Public' : '🔒 School',
                fg:    quiz.visibility == 'PUBLIC' ? t.teal : const Color(0xFFA371F7),
                bg:    quiz.visibility == 'PUBLIC' ? t.teal.withValues(alpha: 0.15) : const Color(0xFF2A1A3A),
              ),
            ]),
            const SizedBox(height: 8),
            Text(quiz.title,
                style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 15)),
            if (quiz.description != null)
              Text(quiz.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.subtle, fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              Text('❓ ${quiz.questions.length} questions · 📅 ${quiz.formattedDate}',
                  style: TextStyle(color: t.subtle, fontSize: 12)),
              const Spacer(),
              if (!_showOffline)
                ElevatedButton(
                  onPressed: () => setState(() => _active = quiz),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  child: const Text('▶ Take Quiz',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                )
              else
                Text('📄 Offline', style: TextStyle(color: t.teal, fontSize: 12)),
            ]),
          ])),
        )),
    ]);
  }
}

class _SubTabBtn extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  final AppThemeData theme;
  const _SubTabBtn({required this.label, required this.selected, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected ? theme.primary : theme.surface,
        border: Border.all(color: selected ? theme.primary : theme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(
        color: selected ? Colors.white : theme.muted,
        fontWeight: FontWeight.w600, fontSize: 13,
      )),
    ),
  );
}

// ─── Progress Tab ─────────────────────────────────────────────────────────────

class _ProgressTab extends StatefulWidget {
  const _ProgressTab();
  @override State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  List<_Attempt> _attempts = [];
  bool           _loading  = true;
  String?        _selected;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final headers = await authHeaders();
      final res = await http.get(Uri.parse('$kApiBase/quizzes/attempts/mine'), headers: headers);
      if (res.statusCode < 300 && mounted) {
        _attempts = (jsonDecode(res.body) as List)
            .map((e) => _Attempt.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    if (_loading) return Center(child: CircularProgressIndicator(color: t.primary));

    final bySubject = <String, List<_Attempt>>{};
    for (final a in _attempts) {
      bySubject.putIfAbsent(a.subject, () => []).add(a);
    }
    final subjects   = bySubject.keys.toList();
    final overallAvg = _attempts.isEmpty ? 0
        : (_attempts.fold(0, (s, a) => s + a.percentage) / _attempts.length).round();

    final recent    = _attempts.take(5).toList();
    final prev      = _attempts.skip(5).take(5).toList();
    final recentAvg = recent.isEmpty ? 0 : (recent.fold(0,(s,a)=>s+a.percentage)/recent.length).round();
    final prevAvg   = prev.isEmpty   ? 0 : (prev.fold(0,(s,a)=>s+a.percentage)/prev.length).round();
    final trend     = recentAvg - prevAvg;

    return RefreshIndicator(
      color: t.primary,
      onRefresh: _fetch,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Overall Progress',
                  style: TextStyle(color: t.text, fontSize: 16, fontWeight: FontWeight.w700)),
              Text('${_attempts.length} attempts · ${subjects.length} subjects',
                  style: TextStyle(color: t.subtle, fontSize: 12)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$overallAvg%',
                  style: TextStyle(color: t.primary, fontSize: 28, fontWeight: FontWeight.w800)),
              if (trend != 0 && prev.isNotEmpty)
                Text(
                  '${trend > 0 ? "↑" : "↓"} ${trend.abs()}% vs last period',
                  style: TextStyle(color: trend > 0 ? t.primary : t.danger, fontSize: 11),
                ),
            ]),
          ]),
          const SizedBox(height: 10),
          _ProgressBar(value: overallAvg),
          const SizedBox(height: 8),
          Text(
            overallAvg >= 75 ? '🌟 Excellent work! Keep it up!'
            : overallAvg >= 50 ? '📈 Good progress! Push for 75%+'
            : '💪 Keep practising — you\'ll get there!',
            style: TextStyle(color: t.subtle, fontSize: 12),
          ),
        ])),
        const SizedBox(height: 14),

        if (subjects.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(children: [
                const Text('📊', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('No quiz data yet.\nTake some quizzes to track your progress!',
                    style: TextStyle(color: t.subtle), textAlign: TextAlign.center),
              ]),
            ),
          )
        else ...[
          Text('Subject Breakdown',
              style: TextStyle(color: t.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...subjects.map((sub) {
            final list  = bySubject[sub]!;
            final avg   = (list.fold(0,(s,a)=>s+a.percentage) / list.length).round();
            final best  = list.map((a)=>a.percentage).reduce((a,b)=>a>b?a:b);
            final color = _subjectColors[sub] ?? t.primary;
            final isSelected = _selected == sub;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                GestureDetector(
                  onTap: () => setState(() => _selected = isSelected ? null : sub),
                  child: Row(children: [
                    Expanded(child: Text(sub,
                        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14))),
                    Text('${list.length} attempt${list.length!=1?"s":""}',
                        style: TextStyle(color: t.subtle, fontSize: 12)),
                    Icon(isSelected ? Icons.expand_less : Icons.expand_more, color: t.muted, size: 18),
                  ]),
                ),
                const SizedBox(height: 6),
                _ProgressBar(value: avg, color: color),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Avg: $avg%', style: TextStyle(color: t.subtle, fontSize: 11)),
                  Text('Best: $best%', style: TextStyle(color: t.subtle, fontSize: 11)),
                ]),
                if (isSelected) ...[
                  Divider(color: t.border, height: 20),
                  Text('By Topic', style: TextStyle(color: t.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...() {
                    final byTopic = <String, List<_Attempt>>{};
                    for (final a in list) {
                      byTopic.putIfAbsent(a.topic ?? 'Unknown', () => []).add(a);
                    }
                    return byTopic.entries.map((e) {
                      final tAvg = (e.value.fold(0,(s,a)=>s+a.percentage)/e.value.length).round();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Text(e.key,
                                style: TextStyle(color: t.text, fontSize: 12),
                                overflow: TextOverflow.ellipsis)),
                            Text('$tAvg% · ${e.value.length}x',
                                style: TextStyle(color: t.muted, fontSize: 11)),
                          ]),
                          const SizedBox(height: 4),
                          _ProgressBar(value: tAvg, color: color),
                        ]),
                      );
                    }).toList();
                  }(),
                ],
              ])),
            );
          }),
        ],
      ]),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<_Attempt>        _attempts = [];
  Map<String, dynamic>? _stats;
  bool                  _loading  = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final headers = await authHeaders();
      final results = await Future.wait([
        http.get(Uri.parse('$kApiBase/quizzes/attempts/mine'),  headers: headers),
        http.get(Uri.parse('$kApiBase/quizzes/attempts/stats'), headers: headers),
      ]);
      if (!mounted) return;
      if (results[0].statusCode < 300) {
        _attempts = (jsonDecode(results[0].body) as List)
            .map((e) => _Attempt.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (results[1].statusCode < 300) {
        _stats = jsonDecode(results[1].body) as Map<String, dynamic>;
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    if (_loading) return Center(child: CircularProgressIndicator(color: t.primary));

    return RefreshIndicator(
      color: t.primary,
      onRefresh: _fetch,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        if (_stats != null) ...[
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
            children: [
              _StatCard(label: 'Total Quizzes',   value: _stats!['total']?.toString()        ?? '—'),
              _StatCard(label: 'Average Score',   value: '${_stats!['avgScore']             ?? '—'}%'),
              _StatCard(label: 'AI Quizzes',      value: _stats!['aiCount']?.toString()      ?? '—'),
              _StatCard(label: 'Teacher Quizzes', value: _stats!['teacherCount']?.toString() ?? '—'),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (_attempts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('No quiz history yet. Take a quiz to see results here.',
                  textAlign: TextAlign.center, style: TextStyle(color: t.subtle)),
            ),
          )
        else
          ..._attempts.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: _Card(child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${a.subject}${a.topic != null ? " — ${a.topic}" : ""}',
                  style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  '${a.level ?? ""}  ·  ${a.source == "AI" ? "🤖 AI Generated" : "👩‍🏫 Teacher Quiz"}',
                  style: TextStyle(color: t.subtle, fontSize: 12),
                ),
                if (a.formattedDate.isNotEmpty)
                  Text(a.formattedDate, style: TextStyle(color: t.subtle, fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${a.score}/${a.total}',
                    style: TextStyle(color: t.primary, fontSize: 18, fontWeight: FontWeight.w800)),
                Text('${a.percentage}%', style: TextStyle(color: t.subtle, fontSize: 13)),
              ]),
            ])),
          )),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.surface, border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: TextStyle(color: t.primary, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: t.subtle, fontSize: 11), textAlign: TextAlign.center),
      ]),
    );
  }
}