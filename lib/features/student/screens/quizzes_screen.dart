import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_theme.dart';
import 'api_service.dart';

// ─── Subject / topic map (mirrors web app) ────────────────────────────────────

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

// ─── Models ───────────────────────────────────────────────────────────────────

class _Question {
  final String        text;
  final List<String>  options;
  final int           correct; // index

  const _Question({
    required this.text,
    required this.options,
    required this.correct,
  });

  factory _Question.fromJson(Map<String, dynamic> json) {
    final opts = List<String>.from(json['options'] as List? ?? []);
    final correct = (json['correct'] ?? json['answer']) as int? ?? 0;
    return _Question(
      text:    json['question']?.toString() ?? json['text']?.toString() ?? '',
      options: opts,
      correct: correct,
    );
  }
}

class _TeacherQuiz {
  final String         id;
  final String         title;
  final String?        description;
  final String?        subject;
  final String?        form;
  final String?        visibility;
  final String?        duration;
  final List<_Question> questions;
  final DateTime?      createdAt;

  const _TeacherQuiz({
    required this.id,
    required this.title,
    this.description,
    this.subject,
    this.form,
    this.visibility,
    this.duration,
    required this.questions,
    this.createdAt,
  });

  factory _TeacherQuiz.fromJson(Map<String, dynamic> json) {
    final qs = (json['questions'] as List? ?? [])
        .map((q) => _Question.fromJson(q as Map<String, dynamic>))
        .toList();
    DateTime? createdAt;
    if (json['createdAt'] is String) {
      try { createdAt = DateTime.parse(json['createdAt']); } catch (_) {}
    }
    return _TeacherQuiz(
      id:          json['id']?.toString()          ?? '',
      title:       json['title']?.toString()       ?? 'Quiz',
      description: json['description']?.toString(),
      subject:     json['subject']?.toString(),
      form:        json['form']?.toString(),
      visibility:  json['visibility']?.toString(),
      duration:    json['duration']?.toString(),
      questions:   qs,
      createdAt:   createdAt,
    );
  }

  String get formattedDate {
    if (createdAt == null) return '—';
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${createdAt!.day} ${m[createdAt!.month]} ${createdAt!.year}';
  }
}

class _AttemptRecord {
  final String  subject;
  final String? topic;
  final String? level;
  final String  source;
  final int     score;
  final int     total;
  final int     percentage;
  final DateTime? completedAt;

  const _AttemptRecord({
    required this.subject,
    this.topic,
    this.level,
    required this.source,
    required this.score,
    required this.total,
    required this.percentage,
    this.completedAt,
  });

  factory _AttemptRecord.fromJson(Map<String, dynamic> json) {
    DateTime? completedAt;
    if (json['completedAt'] is String) {
      try { completedAt = DateTime.parse(json['completedAt']); } catch (_) {}
    }
    return _AttemptRecord(
      subject:     json['subject']?.toString()    ?? '',
      topic:       json['topic']?.toString(),
      level:       json['level']?.toString(),
      source:      json['source']?.toString()     ?? '',
      score:       (json['score']    as num?)?.toInt() ?? 0,
      total:       (json['total']    as num?)?.toInt() ?? 0,
      percentage:  (json['percentage'] as num?)?.toInt() ?? 0,
      completedAt: completedAt,
    );
  }

  String get formattedDate {
    if (completedAt == null) return '';
    final d = completedAt!;
    return '${d.day}/${d.month}/${d.year} '
           '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }
}

// ─── Log attempt helper ───────────────────────────────────────────────────────

Future<void> _logAttempt({
  required String  source,
  String?          quizId,
  required String  subject,
  required String  topic,
  required String  level,
  required int     score,
  required int     total,
  required int     percentage,
}) async {
  try {
    final headers = await authHeaders();
    await http.post(
      Uri.parse('$kApiBase/quizzes/attempts'),
      headers: headers,
      body: jsonEncode({
        'source': source,
        if (quizId != null) 'quizId': quizId,
        'subject': subject,
        'topic':   topic,
        'level':   level,
        'score':   score,
        'total':   total,
        'percentage': percentage,
      }),
    );
  } catch (_) {}
}

// ─── Main screen (tabs) ───────────────────────────────────────────────────────

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  static const _primary = Color(0xFF2EA043);
  static const _bg      = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('🧠 Quizzes'),
        backgroundColor: _bg,
        foregroundColor: _text,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: _text,
          unselectedLabelColor: _muted,
          indicatorColor: _primary,
          tabs: const [
            Tab(text: '🤖 AI Quiz'),
            Tab(text: '👩‍🏫 Teacher'),
            Tab(text: '📊 History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _AITab(),
          _TeacherTab(),
          _HistoryTab(),
        ],
      ),
    );
  }
}

// ─── AI Tab ───────────────────────────────────────────────────────────────────

class _AITab extends StatefulWidget {
  const _AITab();

  @override
  State<_AITab> createState() => _AITabState();
}

class _AITabState extends State<_AITab> {
  static const _primary = Color(0xFF2EA043);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);
  static const _subtle  = Color(0xFF6E7681);

  String? _subject;
  String? _level;
  String? _topic;
  String? _error;
  bool    _loading = false;

  List<_Question>? _questions;
  Map<String, String>? _meta; // subject, level, topic

  List<String> get _topics => _subject == null ? [] : _subjectTopics[_subject] ?? [];

  Future<void> _generate() async {
    if (_subject == null || _level == null || _topic == null) {
      setState(() => _error = 'Please select subject, level and topic.');
      return;
    }
    setState(() { _loading = true; _error = null; _questions = null; _meta = null; });
    try {
      final headers = await authHeaders();
      final res = await http.post(
        Uri.parse('$kApiBase/quizzes/generate'),
        headers: headers,
        body: jsonEncode({'subject': _subject, 'level': _level, 'topic': _topic}),
      );
      if (res.statusCode != 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        throw Exception(d['message']?.toString() ?? 'Failed to generate quiz');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final qs = (data['questions'] as List? ?? [])
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
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [
                Icon(Icons.psychology_outlined, color: _primary),
                SizedBox(width: 10),
                Text(
                  'AI Quiz Generator',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _subject,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Subject',
              prefixIcon: Icon(Icons.auto_stories_outlined),
            ),
            items: _subjectTopics.keys.map(_dropdownItem).toList(),
            onChanged: _loading
                ? null
                : (value) {
                    setState(() {
                      _subject = value;
                      _topic = null;
                      _error = null;
                      _questions = [];
                      _answers.clear();
                      _score = null;
                    });
                  },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _level,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: _levels.map(_dropdownItem).toList(),
                  onChanged: _loading
                      ? null
                      : (value) {
                          setState(() {
                            _level = value;
                            _error = null;
                            _questions = [];
                            _answers.clear();
                            _score = null;
                          });
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _topic,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _subject == null
                        ? 'Select subject first'
                        : 'Topic',
                    prefixIcon: const Icon(Icons.topic_outlined),
                  ),
                  items: _topics.map(_dropdownItem).toList(),
                  onChanged: _loading || _subject == null
                      ? null
                      : (value) {
                          setState(() {
                            _topic = value;
                            _error = null;
                            _questions = [];
                            _answers.clear();
                            _score = null;
                          });
                        },
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent4),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.accent4),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loading ? null : _generateQuiz,
            icon: Icon(_loading ? Icons.hourglass_top : Icons.smart_toy),
            label: Text(_loading ? 'Generating...' : 'Generate Quiz'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _dropdownItem(String value) {
    return DropdownMenuItem(
      value: value,
      child: Text(value, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 12),
          Text(
            'Generating your static quiz preview...',
            style: TextStyle(color: AppColors.text2),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_subject ?? ''} - ${_level ?? ''} - ${_topic ?? ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.text2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${_answers.length} / ${_questions.length} answered',
          style: const TextStyle(color: AppColors.text2),
        ),
      ],
    );
  }
}

class _SubTabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SubTabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2EA043) : const Color(0xFF161B22),
          border: Border.all(color: selected ? const Color(0xFF2EA043) : const Color(0xFF21262D)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF8B949E),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TeacherQuizCard extends StatelessWidget {
  final _TeacherQuiz quiz;
  final bool isOffline;
  final VoidCallback onTake;

  const _TeacherQuizCard({
    required this.quiz,
    required this.isOffline,
    required this.onTake,
  });

  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);
  static const _text    = Color(0xFFE6EDF3);
  static const _subtle  = Color(0xFF6E7681);
  static const _primary = Color(0xFF2EA043);

  @override
  Widget build(BuildContext context) {
    final isPublic = quiz.visibility == 'PUBLIC';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Tags row
        Wrap(spacing: 6, children: [
          if (quiz.subject != null)
            _MiniTag(label: quiz.subject!, bg: const Color(0xFF1A3A2A), color: _primary),
          if (quiz.form != null)
            _MiniTag(label: quiz.form!, outlined: true),
          _MiniTag(
            label: isPublic ? '🌐 Public' : '🔒 School',
            bg: isPublic ? const Color(0xFF1A2A3A) : const Color(0xFF2A1A3A),
            color: isPublic ? const Color(0xFF58A6FF) : const Color(0xFFA371F7),
          ),
        ]),
        const SizedBox(height: 8),

        Text(quiz.title, style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 15)),

        if (quiz.description != null)
          Text(quiz.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _subtle, fontSize: 12)),

        const SizedBox(height: 10),

        Row(children: [
          Text(
            '❓ ${quiz.questions.length} questions  ·  📅 ${quiz.formattedDate}',
            style: const TextStyle(color: _subtle, fontSize: 12),
          ),
          const Spacer(),
          if (isOffline)
            const Text('📄 Offline', style: TextStyle(color: Color(0xFF58A6FF), fontSize: 12))
          else
            GestureDetector(
              onTap: onTake,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('▶ Take Quiz', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color? bg;
  final Color? color;
  final bool outlined;

  const _MiniTag({required this.label, this.bg, this.color, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bg,
        border: outlined ? Border.all(color: const Color(0xFF21262D)) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: outlined ? const Color(0xFF6E7681) : color,
        ),
      ),
    );
  }
}

// ─── History Tab ──────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  static const _primary = Color(0xFF2EA043);
  static const _bg      = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);
  static const _subtle  = Color(0xFF6E7681);

  List<_AttemptRecord> _attempts = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final headers = await authHeaders();
      final results = await Future.wait([
        http.get(Uri.parse('$kApiBase/quizzes/attempts/mine'),  headers: headers),
        http.get(Uri.parse('$kApiBase/quizzes/attempts/stats'), headers: headers),
      ]);
      if (!mounted) return;
      if (results[0].statusCode == 200) {
        _attempts = (jsonDecode(results[0].body) as List)
            .map((e) => _AttemptRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (results[1].statusCode == 200) {
        _stats = jsonDecode(results[1].body) as Map<String, dynamic>;
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // Stats
          if (_stats != null)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10, mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _StatCard(label: 'Total Quizzes',   value: _stats!['total']?.toString()        ?? '—'),
                _StatCard(label: 'Average Score',   value: '${_stats!['avgScore'] ?? '—'}%'),
                _StatCard(label: 'AI Quizzes',      value: _stats!['aiCount']?.toString()      ?? '—'),
                _StatCard(label: 'Teacher Quizzes', value: _stats!['teacherCount']?.toString() ?? '—'),
              ],
            ),
          if (_stats != null) const SizedBox(height: 16),

          if (_attempts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No quiz history yet. Take a quiz to see results here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _subtle),
                ),
              ),
            )
          else
            ...(_attempts.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${a.subject}${a.topic != null ? " — ${a.topic}" : ""}',
                    style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    '${a.level ?? ""}  ·  ${a.source == "AI" ? "🤖 AI Generated" : "👩‍🏫 Teacher Quiz"}',
                    style: const TextStyle(color: _subtle, fontSize: 12),
                  ),
                  if (a.formattedDate.isNotEmpty)
                    Text(a.formattedDate, style: const TextStyle(color: _subtle, fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    '${a.score}/${a.total}',
                    style: const TextStyle(color: _primary, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text('${a.percentage}%', style: const TextStyle(color: _subtle, fontSize: 13)),
                ]),
              ]),
            ))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border.all(color: const Color(0xFF21262D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: const TextStyle(color: Color(0xFF2EA043), fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF6E7681), fontSize: 11), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── Quiz runner (shared) ─────────────────────────────────────────────────────

class _QuizRunner extends StatefulWidget {
  final List<_Question> questions;
  final String          subject;
  final String          level;
  final String          topic;
  final String          source;
  final String?         quizId;
  final VoidCallback    onDone;

  const _QuizRunner({
    required this.questions,
    required this.subject,
    required this.level,
    required this.topic,
    required this.source,
    required this.onDone,
    this.quizId,
  });

  @override
  State<_QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<_QuizRunner> {
  static const _primary = Color(0xFF2EA043);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);
  static const _subtle  = Color(0xFF6E7681);
  static const _blue    = Color(0xFF1F6FEB);
  static const _red     = Color(0xFFDA3633);

  final Map<int, int> _answers = {};
  int? _score;
  String? _error;

  void _select(int qi, int oi) {
    if (_score != null) return;
    setState(() => _answers[qi] = oi);
  }

  Future<void> _submit() async {
    if (_answers.length < widget.questions.length) {
      setState(() => _error = 'Please answer all questions before submitting.');
      return;
    }
    setState(() => _error = null);

    var correct = 0;
    for (var i = 0; i < widget.questions.length; i++) {
      if (_answers[i] == widget.questions[i].correct) correct++;
    }
    setState(() => _score = correct);

    final pct = ((correct / widget.questions.length) * 100).round();
    await _logAttempt(
      source:     widget.source,
      quizId:     widget.quizId,
      subject:    widget.subject,
      topic:      widget.topic,
      level:      widget.level,
      score:      correct,
      total:      widget.questions.length,
      percentage: pct,
    );
  }

  Color _optionBg(int qi, int oi) {
    if (_score == null) {
      return _answers[qi] == oi
          ? _primary.withValues(alpha: 0.15)
          : Colors.transparent;
    }
    final correct  = widget.questions[qi].correct;
    final selected = _answers[qi] == oi;
    if (correct == oi) return _primary.withValues(alpha: 0.15);
    if (selected)       return _red.withValues(alpha: 0.15);
    return Colors.transparent;
  }

  Color _optionBorder(int qi, int oi) {
    if (_score == null) {
      return _answers[qi] == oi ? _primary : _border;
    }
    final correct  = widget.questions[qi].correct;
    final selected = _answers[qi] == oi;
    if (correct == oi) return _primary;
    if (selected)       return _red;
    return _border;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Header
        Text(
          '${widget.subject}  ·  ${widget.level}  ·  ${widget.topic}',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        Text(
          '${_answers.length} / ${widget.questions.length} answered',
          style: const TextStyle(color: _subtle, fontSize: 12),
        ),
        const SizedBox(height: 14),

        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3D1F1F),
              border: Border.all(color: const Color(0xFFF85149)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFF85149), fontSize: 13)),
          ),

        // Questions
        for (var i = 0; i < widget.questions.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${i + 1}. ${widget.questions[i].text}',
                style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const SizedBox(height: 12),
              for (var j = 0; j < widget.questions[i].options.length; j++) ...[
                GestureDetector(
                  onTap: () => _select(i, j),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _optionBg(i, j),
                      border: Border.all(color: _optionBorder(i, j)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(
                        _answers[i] == j ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: _answers[i] == j ? _primary : _subtle,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(widget.questions[i].options[j], style: const TextStyle(color: _text))),
                      if (_score != null && widget.questions[i].correct == j)
                        const Text('✅'),
                      if (_score != null && _answers[i] == j && widget.questions[i].correct != j)
                        const Text('❌'),
                    ]),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),
        ],

        // Action button / result
        if (_score == null)
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Submit Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              minimumSize: const Size.fromHeight(48),
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              const Text('Quiz Complete! 🎉', style: TextStyle(color: _primary, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Score: $_score / ${widget.questions.length}  (${((_score! / widget.questions.length) * 100).round()}%)',
                style: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _score == widget.questions.length
                    ? 'Perfect! Excellent work!'
                    : _score! >= (widget.questions.length * 0.7)
                        ? 'Great job! Keep it up!'
                        : 'Good effort! Try again to improve.',
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: widget.onDone,
                icon: const Icon(Icons.refresh),
                label: const Text('🔄 Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  minimumSize: const Size(180, 44),
                ),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}

// ─── Styled dropdown ──────────────────────────────────────────────────────────

class _StyledDropdown extends StatelessWidget {
  final String       label;
  final String?      value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const _StyledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  static const _surface = Color(0xFF0D1117);
  static const _border  = Color(0xFF21262D);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);

  @override
  Widget build(BuildContext context) {
    final safeValue = (value != null && items.contains(value)) ? value : null;
    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      dropdownColor: const Color(0xFF161B22),
      style: const TextStyle(color: _text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      hint: Text(label, style: const TextStyle(color: _muted, fontSize: 14)),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }
}