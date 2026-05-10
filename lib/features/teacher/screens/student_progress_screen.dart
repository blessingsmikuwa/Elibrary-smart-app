import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  String _selectedView = 'All Students';
  String _selectedForm = 'Form 3';
  
  final List<Map<String, dynamic>> _students = [
    {'name': 'Chisomo Banda', 'form': 'Form 3', 'avgScore': 85, 'quizzesTaken': 12, 'lastActive': 'Feb 5, 2026', 'trend': 'up'},
    {'name': 'Mphatso Chirwa', 'form': 'Form 3', 'avgScore': 70, 'quizzesTaken': 10, 'lastActive': 'Feb 4, 2026', 'trend': 'down'},
    {'name': 'Thandiwe Mwale', 'form': 'Form 2', 'avgScore': 92, 'quizzesTaken': 15, 'lastActive': 'Feb 5, 2026', 'trend': 'up'},
    {'name': 'Kondwani Phiri', 'form': 'Form 3', 'avgScore': 55, 'quizzesTaken': 8, 'lastActive': 'Feb 3, 2026', 'trend': 'down'},
    {'name': 'Grace Mkandawire', 'form': 'Form 2', 'avgScore': 88, 'quizzesTaken': 14, 'lastActive': 'Feb 5, 2026', 'trend': 'up'},
    {'name': 'Peter Nyirenda', 'form': 'Form 4', 'avgScore': 65, 'quizzesTaken': 9, 'lastActive': 'Feb 2, 2026', 'trend': 'stable'},
    {'name': 'Maria Banda', 'form': 'Form 1', 'avgScore': 78, 'quizzesTaken': 11, 'lastActive': 'Feb 5, 2026', 'trend': 'up'},
    {'name': 'John Chirwa', 'form': 'Form 4', 'avgScore': 45, 'quizzesTaken': 6, 'lastActive': 'Feb 1, 2026', 'trend': 'down'},
  ];

  List<Map<String, dynamic>> get filteredStudents {
    if (_selectedView == 'All Students') return _students;
    if (_selectedView == 'By Form') {
      return _students.where((s) => s['form'] == _selectedForm).toList();
    }
    return _students;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Progress'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: AppColors.text2),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.text2),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(
                bottom: BorderSide(color: Color(0xFF30363d)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard('Total Students', '156', Icons.people, AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard('Avg. Score', '78%', Icons.trending_up, AppColors.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard('Pass Rate', '85%', Icons.check_circle, AppColors.success),
                ),
              ],
            ),
          ),

          // View Selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildViewButton('All Students'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildViewButton('By Form'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildViewButton('Low Performance'),
                ),
              ],
            ),
          ),

          // Form Selector (when By Form is selected)
          if (_selectedView == 'By Form')
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFormChip('Form 1'),
                  const SizedBox(width: 8),
                  _buildFormChip('Form 2'),
                  const SizedBox(width: 8),
                  _buildFormChip('Form 3'),
                  const SizedBox(width: 8),
                  _buildFormChip('Form 4'),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Students List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return _buildStudentCard(student);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8b949e),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewButton(String label) {
    final isSelected = _selectedView == label;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedView = label;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
        foregroundColor: isSelected ? Colors.white : AppColors.text2,
        side: BorderSide(
          color: isSelected ? AppColors.primary : const Color(0xFF30363d),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }

  Widget _buildFormChip(String form) {
    final isSelected = _selectedForm == form;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedForm = form;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF30363d),
          ),
        ),
        child: Text(
          form,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.text2,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final avgScore = student['avgScore'] as int;
    final scoreColor = avgScore >= 80 ? AppColors.success : avgScore >= 60 ? AppColors.warning : AppColors.error;
    final trendIcon = student['trend'] == 'up' ? Icons.trending_up : 
                      student['trend'] == 'down' ? Icons.trending_down : Icons.trending_flat;
    final trendColor = student['trend'] == 'up' ? AppColors.success : 
                        student['trend'] == 'down' ? AppColors.error : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scoreColor.withOpacity(0.2),
                radius: 20,
                child: Icon(Icons.person, color: scoreColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student['form']} • ${student['quizzesTaken']} quizzes taken',
                      style: const TextStyle(
                        color: Color(0xFF8b949e),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${student['avgScore']}%',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(trendIcon, size: 16, color: trendColor),
                      const SizedBox(width: 4),
                      Text(
                        'Avg Score',
                        style: TextStyle(color: trendColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last active: ${student['lastActive']}',
                style: const TextStyle(
                  color: Color(0xFF8b949e),
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility, size: 16, color: AppColors.text2),
                    label: const Text('Details', style: TextStyle(color: AppColors.text2, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.message, size: 16, color: AppColors.primary),
                    label: const Text('Message', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}