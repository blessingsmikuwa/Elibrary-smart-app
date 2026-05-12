import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedForm = 'Form 1';
  String _selectedSubject = 'Biology';
  int _numberOfQuestions = 10;
  int _timeLimit = 30;
  final List<Map<String, dynamic>> _questions = [];

  final List<String> _forms = ['Form 1', 'Form 2', 'Form 3', 'Form 4'];
  final List<String> _subjects = ['Biology', 'Chemistry', 'Physics', 'Mathematics', 'English'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        actions: [
          TextButton(
            onPressed: _saveQuiz,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a3a2a),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.quiz, size: 40, color: AppColors.primary),
                    SizedBox(height: 12),
                    SizedBox(height: 4),
                    Text(
                      'Fill in the details below to create a new quiz for your students',
                      style: TextStyle(
                        color: Color(0xFFc9d1d9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quiz Title
              _buildSectionTitle('Quiz Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Enter quiz title',
                  hintStyle: const TextStyle(color: AppColors.text2),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF30363d)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF30363d)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a quiz title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Subject and Form
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Subject'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF30363d)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSubject,
                              isExpanded: true,
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(color: AppColors.text, fontSize: 14),
                              items: _subjects.map((subject) {
                                return DropdownMenuItem(
                                  value: subject,
                                  child: Text(subject),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSubject = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Form'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF30363d)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedForm,
                              isExpanded: true,
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(color: AppColors.text, fontSize: 14),
                              items: _forms.map((form) {
                                return DropdownMenuItem(
                                  value: form,
                                  child: Text(form),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedForm = value!;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              _buildSectionTitle('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Enter quiz description and instructions',
                  hintStyle: const TextStyle(color: AppColors.text2),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF30363d)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF30363d)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quiz Settings
              _buildSectionTitle('Quiz Settings'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF30363d)),
                ),
                child: Column(
                  children: [
                    // Number of Questions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Number of Questions',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_numberOfQuestions > 1) {
                                  setState(() {
                                    _numberOfQuestions--;
                                  });
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.text2),
                            ),
                            Text(
                              '$_numberOfQuestions',
                              style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_numberOfQuestions < 50) {
                                  setState(() {
                                    _numberOfQuestions++;
                                  });
                                }
                              },
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF30363d)),
                    // Time Limit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Time Limit (minutes)',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_timeLimit > 5) {
                                  setState(() {
                                    _timeLimit -= 5;
                                  });
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.text2),
                            ),
                            Text(
                              '$_timeLimit',
                              style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_timeLimit < 120) {
                                  setState(() {
                                    _timeLimit += 5;
                                  });
                                }
                              },
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Add Questions Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _addQuestions,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Questions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _previewQuiz,
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview Quiz'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: const BorderSide(color: Color(0xFF30363d)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _saveQuiz() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz saved successfully!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _addQuestions() {
    // Navigate to add questions screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuestionsScreen(
          onQuestionsAdded: (questions) {
            setState(() {
              _questions.addAll(questions);
            });
          },
        ),
      ),
    );
  }

  void _previewQuiz() {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add questions first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPreviewScreen(
          title: _titleController.text,
          description: _descriptionController.text,
          subject: _selectedSubject,
          form: _selectedForm,
          timeLimit: _timeLimit,
          questions: _questions,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class AddQuestionsScreen extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onQuestionsAdded;

  const AddQuestionsScreen({super.key, required this.onQuestionsAdded});

  @override
  State<AddQuestionsScreen> createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  final List<Map<String, dynamic>> _questions = [];
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctAnswerIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Questions'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        actions: [
          TextButton(
            onPressed: _saveQuestions,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current questions count
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF30363d)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.quiz, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    '${_questions.length} questions added',
                    style: const TextStyle(color: AppColors.text, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Question input
            const Text(
              'Question',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Enter your question',
                hintStyle: const TextStyle(color: AppColors.text2),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF30363d)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF30363d)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Options
            const Text(
              'Options',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...List.generate(4, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _correctAnswerIndex,
                      onChanged: (value) {
                        setState(() {
                          _correctAnswerIndex = value!;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[index],
                        style: const TextStyle(color: AppColors.text),
                        decoration: InputDecoration(
                          hintText: 'Option ${index + 1}',
                          hintStyle: const TextStyle(color: AppColors.text2),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF30363d)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF30363d)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Add question button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
                label: const Text('Add Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addQuestion() {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    final options = _optionControllers.map((c) => c.text).toList();
    if (options.any((option) => option.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all options')),
      );
      return;
    }

    setState(() {
      _questions.add({
        'question': _questionController.text,
        'options': options,
        'correctAnswer': _correctAnswerIndex,
      });

      // Clear fields
      _questionController.clear();
      for (var controller in _optionControllers) {
        controller.clear();
      }
      _correctAnswerIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question added!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _saveQuestions() {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    widget.onQuestionsAdded(_questions);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}

class QuizPreviewScreen extends StatelessWidget {
  final String title;
  final String description;
  final String subject;
  final String form;
  final int timeLimit;
  final List<Map<String, dynamic>> questions;

  const QuizPreviewScreen({
    super.key,
    required this.title,
    required this.description,
    required this.subject,
    required this.form,
    required this.timeLimit,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Preview'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF30363d)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.text2, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(Icons.subject, subject),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.school, form),
                      const SizedBox(width: 12),
                      _buildInfoChip(Icons.timer, '${timeLimit}min'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Questions
            Text(
              'Questions (${questions.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF30363d)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${index + 1}: ${question['question']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(question['options'].length, (optionIndex) {
                      final isCorrect = optionIndex == question['correctAnswer'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isCorrect ? AppColors.success : const Color(0xFF30363d),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isCorrect ? AppColors.success : AppColors.text2,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                question['options'][optionIndex],
                                style: TextStyle(
                                  color: isCorrect ? AppColors.success : AppColors.text,
                                  fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: AppColors.primary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}