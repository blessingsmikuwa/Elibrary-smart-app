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

final List<PastPaper> _dummyPastPapers = [
  PastPaper(
    id: 'paper-001',
    title: 'Mathematics Paper 1',
    description: 'Practice algebra, geometry, and number theory questions.',
    subject: 'Mathematics',
    classLevel: 'Form 4',
    targetAudience: 'Students',
    fileUrl: 'https://example.com/past-papers/mathematics-paper-1.pdf',
    createdAt: DateTime(2025, 10, 12),
    uploaderName: 'Admin',
  ),
  PastPaper(
    id: 'paper-002',
    title: 'English Language Paper 2',
    description: 'Essay writing, comprehension, and grammar revision paper.',
    subject: 'English',
    classLevel: 'Form 3',
    targetAudience: 'Students',
    fileUrl: 'https://example.com/past-papers/english-language-paper-2.pdf',
    createdAt: DateTime(2025, 9, 28),
    uploaderName: 'Admin',
  ),
  PastPaper(
    id: 'paper-003',
    title: 'Biology Practical Revision',
    description: 'Common practical questions with diagrams and observations.',
    subject: 'Biology',
    classLevel: 'Form 4',
    targetAudience: 'Students',
    fileUrl: 'https://example.com/past-papers/biology-practical-revision.pdf',
    createdAt: DateTime(2025, 8, 18),
    uploaderName: 'Science Department',
  ),
  PastPaper(
    id: 'paper-004',
    title: 'Physical Science Paper 1',
    description: 'Mechanics, electricity, waves, and basic chemistry revision.',
    subject: 'Physical Science',
    classLevel: 'Form 2',
    targetAudience: 'Students',
    fileUrl: 'https://example.com/past-papers/physical-science-paper-1.pdf',
    createdAt: DateTime(2025, 7, 5),
    uploaderName: 'Science Department',
  ),
  PastPaper(
    id: 'paper-005',
    title: 'Geography Paper 1',
    description: 'Map reading, weather, population, and settlement questions.',
    subject: 'Geography',
    classLevel: 'Form 3',
    targetAudience: 'Students',
    fileUrl: 'https://example.com/past-papers/geography-paper-1.pdf',
    createdAt: DateTime(2025, 6, 21),
    uploaderName: 'Humanities Department',
  ),
  PastPaper(
    id: 'paper-006',
    title: 'History Paper 2',
    description: 'Regional history, source analysis, and structured responses.',
    subject: 'History',
    classLevel: 'Form 1',
    targetAudience: 'Students',
    fileUrl: 'https://example.com/past-papers/history-paper-2.pdf',
    createdAt: DateTime(2025, 5, 14),
    uploaderName: 'Humanities Department',
  ),
];

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

  List<PastPaper> _papers = List.of(_dummyPastPapers);
  String _selectedLevel = 'All Levels';
  String _selectedSubject = 'All Subjects';
  int _currentPage = 1;

  List<String> get _subjects {
    final subjects =
        _papers
            .map((paper) => paper.subject)
            .whereType<String>()
            .where((subject) => subject.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All Subjects', ...subjects];
  }

  List<PastPaper> get _filteredPapers {
    final query = _searchController.text.trim().toLowerCase();

    return _papers.where((paper) {
      final matchesSearch =
          query.isEmpty ||
          paper.title.toLowerCase().contains(query) ||
          (paper.description?.toLowerCase().contains(query) ?? false);
      final matchesLevel =
          _selectedLevel == 'All Levels' || paper.classLevel == _selectedLevel;
      final matchesSubject =
          _selectedSubject == 'All Subjects' ||
          paper.subject == _selectedSubject;

      return matchesSearch && matchesLevel && matchesSubject;
    }).toList();
  }

  int get _totalPages {
    final pages = (_filteredPapers.length / _itemsPerPage).ceil();
    return pages < 1 ? 1 : pages;
  }

  List<PastPaper> get _currentPapers {
    final start = (_currentPage - 1) * _itemsPerPage;
    return _filteredPapers.skip(start).take(_itemsPerPage).toList();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPapers() async {
    setState(() {
      _papers = List.of(_dummyPastPapers);
      _currentPage = 1;
    });
  }

  Future<void> _previewPaper(PastPaper paper) async {
    if (!mounted) return;
    _showFileMessage(paper, 'Preview');
  }

  Future<void> _downloadPaper(PastPaper paper) async {
    if (!mounted) return;
    _showFileMessage(paper, 'Download');
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
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
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
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPapers;
    final startItem = filtered.isEmpty
        ? 0
        : ((_currentPage - 1) * _itemsPerPage) + 1;
    final endItem = filtered.isEmpty
        ? 0
        : (startItem + _currentPapers.length - 1);

    return RefreshIndicator(
      onRefresh: _refreshPapers,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildFilters()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Showing $startItem-$endItem of ${filtered.length} past papers',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_currentPapers.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverList.separated(
              itemCount: _currentPapers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final paper = _currentPapers[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    index == 0 ? 4 : 0,
                    16,
                    index == _currentPapers.length - 1 ? 12 : 0,
                  ),
                  child: _PastPaperCard(
                    paper: paper,
                    gradient: _paperGradients[index % _paperGradients.length],
                    formattedDate: _formatDate(paper.createdAt),
                    onPreview: () => _previewPaper(paper),
                    onDownload: () => _downloadPaper(paper),
                  ),
                );
              },
            ),
          if (filtered.isNotEmpty)
            SliverToBoxAdapter(child: _buildPagination()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search past papers...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          _onFilterChanged(_searchController.clear),
                    ),
            ),
            onChanged: (_) => _onFilterChanged(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Level',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: const [
                    'All Levels',
                    'Form 1',
                    'Form 2',
                    'Form 3',
                    'Form 4',
                  ].map(_dropdownItem).toList(),
                  onChanged: (value) => _onFilterChanged(
                    () => _selectedLevel = value ?? 'All Levels',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _subjects.contains(_selectedSubject)
                      ? _selectedSubject
                      : 'All Subjects',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _subjects.map(_dropdownItem).toList(),
                  onChanged: (value) => _onFilterChanged(
                    () => _selectedSubject = value ?? 'All Subjects',
                  ),
                ),
              ),
            ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.text2),
          const SizedBox(height: 16),
          const Text(
            'No past papers found',
            style: TextStyle(fontSize: 18, color: AppColors.text2),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.outlined(
            tooltip: 'Previous page',
            onPressed: _currentPage == 1
                ? null
                : () => setState(() => _currentPage--),
            icon: const Icon(Icons.chevron_left),
          ),
          const SizedBox(width: 12),
          Text(
            'Page $_currentPage of $_totalPages',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          IconButton.outlined(
            tooltip: 'Next page',
            onPressed: _currentPage == _totalPages
                ? null
                : () => setState(() => _currentPage++),
            icon: const Icon(Icons.chevron_right),
          ),
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Colors.white54,
                    size: 30,
                  ),
                ),
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.download,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_metaLine.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _metaLine,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      if (paper.subject != null)
                        _InfoChip(
                          label: paper.subject!,
                          color: AppColors.primary,
                        ),
                      if (paper.classLevel != null)
                        _InfoChip(label: paper.classLevel!),
                      if (paper.targetAudience != null)
                        _InfoChip(label: paper.targetAudience!),
                    ],
                  ),
                  if (paper.description != null &&
                      paper.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      paper.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.text2,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onPreview,
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Preview'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Download'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _metaLine {
    final parts = <String>[
      if (paper.uploaderName != null && paper.uploaderName!.isNotEmpty)
        'Uploaded by ${paper.uploaderName}',
      if (formattedDate.isNotEmpty) formattedDate,
    ];
    return parts.join(' - ');
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, this.color = AppColors.text2});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: color == AppColors.primary ? FontWeight.w700 : null,
      ),
    );
  }
}
