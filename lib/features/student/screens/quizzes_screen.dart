import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correct;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correct,
  });
}

class QuizRecord {
  final String subject;
  final String level;
  final String topic;
  final int score;
  final int total;
  final DateTime completedAt;

  const QuizRecord({
    required this.subject,
    required this.level,
    required this.topic,
    required this.score,
    required this.total,
    required this.completedAt,
  });

  int get percentage => ((score / total) * 100).round();
}

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  static const Map<String, List<String>> _subjectTopics = {
    'Biology': [
      'Cell Structure and Function',
      'Photosynthesis',
      'Transport in Animals',
      'Genetics and Heredity',
      'Ecology and Ecosystems',
    ],
    'Mathematics': [
      'Fractions, Decimals and Percentages',
      'Linear Equations',
      'Quadratic Equations',
      'Trigonometry',
      'Probability',
    ],
    'Chemistry': [
      'Atomic Structure',
      'The Periodic Table',
      'Chemical Bonding',
      'Acids, Bases and Salts',
      'The Mole Concept',
    ],
    'Physics': [
      'Measurements and Units',
      'Newton\'s Laws of Motion',
      'Work, Energy and Power',
      'Light: Reflection',
      'Electricity: Current and Circuits',
    ],
    'English': [
      'Reading Comprehension',
      'Essay Writing',
      'Grammar: Tenses',
      'Active and Passive Voice',
      'Poetry Analysis',
    ],
    'Geography': [
      'Map Reading and Interpretation',
      'Weather and Climate',
      'Agriculture in Malawi',
      'Population Distribution in Malawi',
      'Environmental Conservation',
    ],
    'History': [
      'Early Peoples of Malawi',
      'Maravi Kingdom',
      'John Chilembwe Rising 1915',
      'Malawi Independence 1964',
      'World War I and World War II',
    ],
    'Civic Education': [
      'Citizenship and Responsibilities',
      'Human Rights',
      'The Constitution of Malawi',
      'Elections and Democracy',
      'Corruption and Good Governance',
    ],
    'Computer Studies': [
      'Introduction to Computers',
      'Computer Hardware Components',
      'Operating Systems',
      'Computer Networks',
      'Algorithms and Flowcharts',
    ],
    'Agriculture': [
      'Importance of Agriculture in Malawi',
      'Soil Fertility and Improvement',
      'Crop Production',
      'Irrigation in Malawi',
      'Animal Husbandry',
    ],
    'Business Studies': [
      'Introduction to Business',
      'Entrepreneurship',
      'Banking Services in Malawi',
      'Marketing and the Marketing Mix',
      'Accounting: Basic Concepts',
    ],
    'Home Economics': [
      'Nutrition and Balanced Diet',
      'Kitchen Hygiene and Safety',
      'Food Preservation',
      'Clothing and Textile Fibres',
      'Budget and Financial Planning',
    ],
    'Chichewa': [
      'Kusoma ndi Kumvetsa',
      'Kulemba Kalata',
      'Mau Ogwirizana',
      'Nthano ndi Miyambo',
      'Ndakatulo',
    ],
    'French': [
      'Greetings and Introductions',
      'Numbers and Counting',
      'Family and Relationships',
      'Present Tense Verbs',
      'Question Formation',
    ],
  };

  static const List<String> _levels = ['Form 1', 'Form 2', 'Form 3', 'Form 4'];

  String? _subject;
  String? _level;
  String? _topic;
  String? _error;
  int? _score;
  bool _loading = false;

  List<QuizQuestion> _questions = [];
  final Map<int, int> _answers = {};
  final List<QuizRecord> _history = [];

  List<String> get _topics =>
      _subject == null ? const [] : _subjectTopics[_subject] ?? const [];

  void _generateQuiz() {
    if (_subject == null || _level == null || _topic == null) {
      setState(() => _error = 'Please select a subject, level and topic.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _questions = [];
      _answers.clear();
      _score = null;
    });

    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _questions = _staticQuestions(_subject!, _level!, _topic!);
        _loading = false;
      });
    });
  }

  void _selectAnswer(int questionIndex, int optionIndex) {
    if (_score != null) return;
    setState(() => _answers[questionIndex] = optionIndex);
  }

  void _submitQuiz() {
    if (_answers.length < _questions.length) {
      setState(() => _error = 'Please answer all questions before submitting.');
      return;
    }

    var correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].correct) correct++;
    }

    setState(() {
      _score = correct;
      _error = null;
      _history.insert(
        0,
        QuizRecord(
          subject: _subject!,
          level: _level!,
          topic: _topic!,
          score: correct,
          total: _questions.length,
          completedAt: DateTime.now(),
        ),
      );
      if (_history.length > 10) _history.removeLast();
    });
  }

  void _resetQuiz() {
    setState(() {
      _questions = [];
      _answers.clear();
      _score = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => _generateQuiz(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGenerator(),
          if (_loading) _buildLoading(),
          if (!_loading && _questions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildQuizHeader(),
            const SizedBox(height: 12),
            for (var i = 0; i < _questions.length; i++) ...[
              _QuestionCard(
                index: i,
                question: _questions[i],
                selectedAnswer: _answers[i],
                score: _score,
                onSelect: (optionIndex) => _selectAnswer(i, optionIndex),
              ),
              const SizedBox(height: 12),
            ],
            _buildActionButton(),
          ],
          if (_score != null) ...[
            const SizedBox(height: 16),
            _buildResultCard(),
          ],
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildHistory(),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_outlined, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
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

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _score == null
          ? ElevatedButton.icon(
              onPressed: _submitQuiz,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Submit Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6FEB),
                minimumSize: const Size.fromHeight(48),
              ),
            )
          : ElevatedButton.icon(
              onPressed: _resetQuiz,
              icon: const Icon(Icons.refresh),
              label: const Text('New Quiz'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
    );
  }

  Widget _buildResultCard() {
    final score = _score!;
    final percentage = ((score / _questions.length) * 100).round();
    final message = score == _questions.length
        ? 'Perfect! Excellent work!'
        : score >= (_questions.length * 0.7)
            ? 'Great job! Keep it up!'
            : 'Good effort! Try again to improve your score.';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Quiz Complete!',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $score / ${_questions.length} ($percentage%)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(message, style: const TextStyle(color: AppColors.text2)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _ResultMeta(label: 'Subject', value: _subject!)),
                const SizedBox(width: 8),
                Expanded(child: _ResultMeta(label: 'Level', value: _level!)),
              ],
            ),
            const SizedBox(height: 8),
            _ResultMeta(label: 'Topic', value: _topic!),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Quiz History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        for (final record in _history) ...[
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text(
                '${record.subject} - ${record.topic}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${record.level} - ${record.total} questions - ${_formatDate(record.completedAt)}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${record.score}/${record.total}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${record.percentage}%',
                    style: const TextStyle(color: AppColors.text2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    final date =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }

  List<QuizQuestion> _staticQuestions(
    String subject,
    String level,
    String topic,
  ) {
    return [
      QuizQuestion(
        question: 'Which statement best matches $topic in $subject?',
        options: [
          'It is a key concept learners should be able to explain clearly.',
          'It is only used outside the school curriculum.',
          'It has no connection to $level work.',
          'It should be memorised without understanding.',
        ],
        correct: 0,
      ),
      QuizQuestion(
        question: 'What is the best first step when studying $topic?',
        options: [
          'Skip definitions and attempt the hardest questions first.',
          'Identify the main terms, examples, and common exam commands.',
          'Avoid practice questions until the exam week.',
          'Read only the answer key.',
        ],
        correct: 1,
      ),
      QuizQuestion(
        question: 'Why are worked examples useful for $level learners?',
        options: [
          'They replace revision completely.',
          'They hide mistakes from the learner.',
          'They show the thinking steps used to reach an answer.',
          'They make every question have the same answer.',
        ],
        correct: 2,
      ),
      QuizQuestion(
        question: 'Which habit improves quiz performance over time?',
        options: [
          'Changing topics whenever a question feels difficult.',
          'Guessing every answer quickly.',
          'Reviewing only questions answered correctly.',
          'Checking mistakes and practising similar questions again.',
        ],
        correct: 3,
      ),
      QuizQuestion(
        question: 'How should a student use feedback after this quiz?',
        options: [
          'Review weak areas in $topic and retry after revision.',
          'Ignore the score and move on immediately.',
          'Study unrelated topics only.',
          'Assume one attempt is enough.',
        ],
        correct: 0,
      ),
    ];
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final QuizQuestion question;
  final int? selectedAnswer;
  final int? score;
  final ValueChanged<int> onSelect;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selectedAnswer,
    required this.score,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${question.question}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < question.options.length; i++) ...[
              _OptionTile(
                text: question.options[i],
                selected: selectedAnswer == i,
                correct: score == null ? null : question.correct == i,
                wrongSelection: score != null &&
                    selectedAnswer == i &&
                    question.correct != i,
                onTap: () => onSelect(i),
              ),
              if (i != question.options.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final bool selected;
  final bool? correct;
  final bool wrongSelection;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.selected,
    required this.correct,
    required this.wrongSelection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSubmitted = correct != null;
    final borderColor = correct == true
        ? AppColors.primary
        : wrongSelection
            ? AppColors.accent4
            : selected
                ? AppColors.primary
                : AppColors.border;
    final backgroundColor = correct == true || selected
        ? (correct == false && wrongSelection
            ? AppColors.accent4.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.12))
        : AppColors.surface2;

    return InkWell(
      onTap: isSubmitted ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: isSubmitted && correct != true && !wrongSelection ? 0.62 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
              if (isSubmitted && correct == true)
                const Icon(Icons.check_circle, color: AppColors.primary),
              if (wrongSelection)
                const Icon(Icons.cancel, color: AppColors.accent4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultMeta extends StatelessWidget {
  final String label;
  final String value;

  const _ResultMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.text2)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
