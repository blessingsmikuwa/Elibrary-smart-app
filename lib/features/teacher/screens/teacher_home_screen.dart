import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'upload_material_screen.dart';
import 'teaching_materials_screen.dart';
import 'create_quiz_screen.dart';
import 'student_progress_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;
  
  final List<String> _titles = ['Dashboard', 'Materials', 'Create Quiz', 'Progress', 'Profile'];
  
  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const DashboardContent();
      case 1:
        return TeachingMaterialsScreen();
      case 2:
        return CreateQuizScreen();
      case 3:
        return StudentProgressScreen();
      case 4:
        return TeacherProfileScreen();
      default:
        return const DashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF30363d), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.text2,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              activeIcon: Icon(Icons.dashboard, color: AppColors.primary),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              activeIcon: Icon(Icons.book, color: AppColors.primary),
              label: 'Materials',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz),
              activeIcon: Icon(Icons.quiz, color: AppColors.primary),
              label: 'Create Quiz',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              activeIcon: Icon(Icons.bar_chart, color: AppColors.primary),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              activeIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Content Widget (embedded in the same file)
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _isLoading = true;
  String _teacherName = '';
  String _role = '';
  String _school = '';
  List<Map<String, String>> _stats = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _quizResults = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _teacherName = 'Mr. Phiri';
      _role = 'Biology Teacher';
      _school = 'Zomba Secondary School';
      
      _stats = [
        {'number': '28', 'label': 'Teaching Materials Uploaded'},
        {'number': '156', 'label': 'Total Students'},
        {'number': '12', 'label': 'Active Quizzes'},
        {'number': '78%', 'label': 'Average Class Score'},
      ];
      
      _materials = [
        {
          'type': 'LESSON PLAN',
          'title': 'Cell Structure and Function',
          'form': 'Form 3',
          'views': 142,
          'downloads': 67,
          'description': 'Comprehensive lesson plan covering prokaryotic and eukaryotic cells, organelles, and their functions.',
          'typeColor': const Color(0xFFe3a525),
        },
        {
          'type': 'WORKSHEET',
          'title': 'Photosynthesis Practice',
          'form': 'Form 2',
          'views': 98,
          'downloads': 45,
          'description': 'Practice questions and diagrams covering the process of photosynthesis and factors affecting it.',
          'typeColor': const Color(0xFF2ea043),
        },
        {
          'type': 'PRESENTATION',
          'title': 'Human Digestive System',
          'form': 'Form 3',
          'views': 187,
          'downloads': 92,
          'description': 'Slide presentation with diagrams and explanations of digestive organs and processes.',
          'typeColor': const Color(0xFFa371f7),
        },
      ];
      
      _quizResults = [
        {'student': 'Chisomo Banda', 'quiz': 'Cell Biology Quiz', 'form': 'Form 3', 'score': 18, 'total': 20, 'date': 'Feb 5, 2026'},
        {'student': 'Mphatso Chirwa', 'quiz': 'Cell Biology Quiz', 'form': 'Form 3', 'score': 14, 'total': 20, 'date': 'Feb 5, 2026'},
        {'student': 'Thandiwe Mwale', 'quiz': 'Photosynthesis Quiz', 'form': 'Form 2', 'score': 19, 'total': 20, 'date': 'Feb 4, 2026'},
        {'student': 'Kondwani Phiri', 'quiz': 'Cell Biology Quiz', 'form': 'Form 3', 'score': 10, 'total': 20, 'date': 'Feb 5, 2026'},
        {'student': 'Grace Mkandawire', 'quiz': 'Photosynthesis Quiz', 'form': 'Form 2', 'score': 17, 'total': 20, 'date': 'Feb 4, 2026'},
      ];
      
      _isLoading = false;
    });
  }

  Color _getScoreColor(int score, int total) {
    double pct = (score / total) * 100;
    if (pct >= 80) return AppColors.success;
    if (pct >= 60) return AppColors.warning;
    return AppColors.error;
  }

  Color _getScoreBgColor(int score, int total) {
    double pct = (score / total) * 100;
    if (pct >= 80) return const Color(0xFF1a4731);
    if (pct >= 60) return const Color(0xFF3d2f0a);
    return const Color(0xFF3d1a1a);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Loading dashboard...',
                style: TextStyle(color: AppColors.text2, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 32),
              _buildTeachingMaterialsSection(),
              const SizedBox(height: 32),
              _buildQuizResultsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Teacher Dashboard'),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.text2),
          onPressed: () {},
        ),
        CircleAvatar(
          backgroundColor: AppColors.primary,
          radius: 16,
          child: Text(
            _teacherName.isNotEmpty ? _teacherName[0] : 'T',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1a3a2a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _teacherName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_role | $_school',
                      style: const TextStyle(
                        color: Color(0xFFc9d1d9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to Create Quiz
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('✏️ Create Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe3a525),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to Upload Material
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploadMaterialScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('📤 Upload Material'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: Color(0xFF30363d)),
                  backgroundColor: const Color(0xFF21262d),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TeachingMaterialsScreen()),
                        );
                      },
                      icon: const Icon(Icons.library_books, size: 18),
                      label: const Text('Materials'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateQuizScreen()),
                        );
                      },
                      icon: const Icon(Icons.quiz, size: 18),
                      label: const Text('Create Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StudentProgressScreen()),
                        );
                      },
                      icon: const Icon(Icons.bar_chart, size: 18),
                      label: const Text('Progress'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TeacherProfileScreen()),
                        );
                      },
                      icon: const Icon(Icons.person, size: 18),
                      label: const Text('Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: _stats.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363d)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _stats[index]['number']!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _stats[index]['label']!,
                style: const TextStyle(
                  color: Color(0xFF8b949e),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeachingMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📖 My Teaching Materials',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // TODO: Navigate to Materials
              },
              icon: const Icon(Icons.add, size: 18, color: Color(0xFFda3633)),
              label: const Text(
                '+ Manage Materials',
                style: TextStyle(
                  color: Color(0xFFda3633),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _materials.length,
            itemBuilder: (context, index) {
              final material = _materials[index];
              return Container(
                width: 300,
                margin: EdgeInsets.only(
                  right: index < _materials.length - 1 ? 16 : 0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF30363d)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (material['typeColor'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: (material['typeColor'] as Color).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        material['type'],
                        style: TextStyle(
                          color: material['typeColor'],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      material['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.school, size: 14, color: Color(0xFF8b949e)),
                        const SizedBox(width: 4),
                        Text(
                          '📅 ${material['form']}',
                          style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.visibility, size: 14, color: Color(0xFF8b949e)),
                        const SizedBox(width: 4),
                        Text(
                          '👁 ${material['views']}',
                          style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.download, size: 14, color: Color(0xFF8b949e)),
                        const SizedBox(width: 4),
                        Text(
                          '⬇ ${material['downloads']}',
                          style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Text(
                        material['description'],
                        style: const TextStyle(
                          color: Color(0xFF8b949e),
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFda3633),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('View'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.text,
                                side: const BorderSide(color: Color(0xFF30363d)),
                                backgroundColor: const Color(0xFF21262d),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Edit'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuizResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '📊 Recent Quiz Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: View all quiz results
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF8b949e),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF30363d)),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF1a3a2a),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Student Name', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                    Expanded(flex: 2, child: Text('Quiz', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('Form', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('Score', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                    Expanded(flex: 1, child: Text('Date', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
              // Table Rows
              ..._quizResults.asMap().entries.map((entry) {
                final index = entry.key;
                final result = entry.value;
                final scoreColor = _getScoreColor(result['score'], result['total']);
                final scoreBg = _getScoreBgColor(result['score'], result['total']);
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: index < _quizResults.length - 1
                        ? const Border(bottom: BorderSide(color: Color(0xFF30363d)))
                        : null,
                    color: index.isEven ? AppColors.surface : const Color(0xFF0d1117),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          result['student'],
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          result['quiz'],
                          style: const TextStyle(color: Color(0xFF8b949e), fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          result['form'],
                          style: const TextStyle(color: Color(0xFF8b949e), fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${result['score']}/${result['total']}',
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          result['date'],
                          style: const TextStyle(color: Color(0xFF8b949e), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}