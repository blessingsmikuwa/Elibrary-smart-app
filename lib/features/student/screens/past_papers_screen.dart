 import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';

class PastPaper {
  final String id;
  final String title;
  final String? description;
  final String? subject;
  final String? classLevel;
  final String? targetAudience;
  final String? fileUrl;
  final DateTime? createdAt;
  final String? uploaderName;

  const PastPaper({
    required this.id,
    required this.title,
    this.description,
    this.subject,
    this.classLevel,
    this.targetAudience,
    this.fileUrl,
    this.createdAt,
    this.uploaderName,
  });
}

class PastPapersScreen extends StatefulWidget {
  const PastPapersScreen({super.key});

  @override
  State<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends State<PastPapersScreen> {
  static const int _itemsPerPage = 12;

  static const List<List<Color>> _paperGradients = [
    [Color(0xFF2563EB), Color(0xFF1E3A8A)],
    [Color(0xFF16A34A), Color(0xFF14532D)],
    [Color(0xFF9333EA), Color(0xFF581C87)],
    [Color(0xFFF97316), Color(0xFF9A3412)],
    [Color(0xFFEAB308), Color(0xFFA16207)],
    [Color(0xFF14B8A6), Color(0xFF115E59)],
    [Color(0xFFDC2626), Color(0xFF7F1D1D)],
    [Color(0xFF4F46E5), Color(0xFF312E81)],
  ];

  final TextEditingController _searchController = TextEditingController();

  List<PastPaper> _papers = [];
  bool _isLoading = true;
  String? _error;

  String _selectedLevel = 'All Levels';
  String _selectedSubject = 'All Subjects';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchPapers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🔥 DUMMY DATA LOADER (replace later with API)
  Future<void> _fetchPapers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    try {
      final papers = [
        PastPaper(
          id: '1',
          title: 'Mathematics Final Exam 2023',
          subject: 'Mathematics',
          classLevel: 'Form 4',
          targetAudience: 'Students',
          description: 'Final exam paper with marking scheme.',
          fileUrl: 'https://example.com/math.pdf',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          uploaderName: 'Admin',
        ),
        PastPaper(
          id: '2',
          title: 'Biology Mock Paper',
          subject: 'Biology',
          classLevel: 'Form 3',
          description: 'Practice paper for revision.',
          fileUrl: 'https://example.com/bio.pdf',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          uploaderName: 'Teacher John',
        ),
        PastPaper(
          id: '3',
          title: 'English Past Paper',
          subject: 'English',
          classLevel: 'Form 2',
          description: 'Comprehension and grammar.',
          fileUrl: '',
          createdAt: DateTime.now(),
          uploaderName: 'Admin',
        ),
      ];

      if (!mounted) return;

      setState(() {
        _papers = papers;
        _currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 FILTERING
  List<String> get _subjects {
    final subjects = _papers
        .map((p) => p.subject)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return ['All Subjects', ...subjects];
  }

  List<PastPaper> get _filteredPapers {
    final query = _searchController.text.toLowerCase();

    return _papers.where((paper) {
      final matchesSearch =
          query.isEmpty ||
          paper.title.toLowerCase().contains(query) ||
          (paper.description?.toLowerCase().contains(query) ?? false);

      final matchesLevel =
          _selectedLevel == 'All Levels' ||
          paper.classLevel == _selectedLevel;

      final matchesSubject =
          _selectedSubject == 'All Subjects' ||
          paper.subject == _selectedSubject;

      return matchesSearch && matchesLevel && matchesSubject;
    }).toList();
  }

  int get _totalPages {
    final pages = (_filteredPapers.length / _itemsPerPage).ceil();
    return pages == 0 ? 1 : pages;
  }

  List<PastPaper> get _currentPapers {
    final start = (_currentPage - 1) * _itemsPerPage;
    return _filteredPapers.skip(start).take(_itemsPerPage).toList();
  }

  void _showFileMessage(PastPaper paper, String action) {
    final fileUrl = paper.fileUrl;

    final message = fileUrl == null || fileUrl.isEmpty
        ? 'No file URL available for ${paper.title}'
        : '$action link copied: $fileUrl';

    if (fileUrl != null && fileUrl.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: fileUrl));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _previewPaper(PastPaper paper) async {
    _showFileMessage(paper, 'Preview');
  }

  Future<void> _downloadPaper(PastPaper paper) async {
    _showFileMessage(paper, 'Download');
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedLevel = 'All Levels';
      _selectedSubject = 'All Subjects';
      _currentPage = 1;
    });
  }

  void _onFilterChanged(VoidCallback update) {
    setState(() {
      update();
      _currentPage = 1;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPapers;

    return Scaffold(
      appBar: AppBar(title: const Text('Past Papers')),
      body: RefreshIndicator(
        onRefresh: _fetchPapers,
        child: ListView(
          children: [
            _buildFilters(),
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ))
            else if (_currentPapers.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No past papers found'),
              ))
            else
              ..._currentPapers.map((paper) => _PastPaperCard(
                    paper: paper,
                    gradient: _paperGradients[
                        _currentPapers.indexOf(paper) %
                            _paperGradients.length],
                    formattedDate: _formatDate(paper.createdAt),
                    onPreview: () => _previewPaper(paper),
                    onDownload: () => _downloadPaper(paper),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => _onFilterChanged(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  items: const [
                    'All Levels',
                    'Form 1',
                    'Form 2',
                    'Form 3',
                    'Form 4',
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) =>
                      _onFilterChanged(() => _selectedLevel = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedSubject,
                  items: _subjects
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) =>
                      _onFilterChanged(() => _selectedSubject = v!),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _PastPaperCard extends StatelessWidget {
  final PastPaper paper;
  final List<Color> gradient;
  final String formattedDate;
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  const _PastPaperCard({
    required this.paper,
    required this.gradient,
    required this.formattedDate,
    required this.onPreview,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(paper.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (formattedDate.isNotEmpty) Text(formattedDate),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (paper.subject != null) Chip(label: Text(paper.subject!)),
                if (paper.classLevel != null)
                  Chip(label: Text(paper.classLevel!)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                    onPressed: onPreview, child: const Text('Preview')),
                const SizedBox(width: 10),
                OutlinedButton(
                    onPressed: onDownload, child: const Text('Download')),
              ],
            )
          ],
        ),
      ),
    );
  }
}