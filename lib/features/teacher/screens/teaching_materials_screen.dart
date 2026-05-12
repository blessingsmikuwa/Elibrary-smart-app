import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'upload_material_screen.dart';

class TeachingMaterialsScreen extends StatefulWidget {
  const TeachingMaterialsScreen({super.key});

  @override
  State<TeachingMaterialsScreen> createState() => _TeachingMaterialsScreenState();
}

class _TeachingMaterialsScreenState extends State<TeachingMaterialsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  
  final List<Map<String, dynamic>> _allMaterials = [
    {
      'type': 'LESSON PLAN',
      'title': 'Cell Structure and Function',
      'form': 'Form 3',
      'subject': 'Biology',
      'views': 142,
      'downloads': 67,
      'date': 'Feb 5, 2026',
      'typeColor': const Color(0xFFe3a525),
      'size': '2.4 MB',
    },
    {
      'type': 'WORKSHEET',
      'title': 'Photosynthesis Practice',
      'form': 'Form 2',
      'subject': 'Biology',
      'views': 98,
      'downloads': 45,
      'date': 'Feb 4, 2026',
      'typeColor': const Color(0xFF2ea043),
      'size': '1.8 MB',
    },
    {
      'type': 'PRESENTATION',
      'title': 'Human Digestive System',
      'form': 'Form 3',
      'subject': 'Biology',
      'views': 187,
      'downloads': 92,
      'date': 'Feb 3, 2026',
      'typeColor': const Color(0xFFa371f7),
      'size': '5.2 MB',
    },
    {
      'type': 'NOTES',
      'title': 'Chemical Bonding',
      'form': 'Form 4',
      'subject': 'Chemistry',
      'views': 234,
      'downloads': 156,
      'date': 'Feb 2, 2026',
      'typeColor': const Color(0xFF58a6ff),
      'size': '3.1 MB',
    },
    {
      'type': 'EXAM',
      'title': 'Algebra Practice Test',
      'form': 'Form 2',
      'subject': 'Mathematics',
      'views': 312,
      'downloads': 245,
      'date': 'Feb 1, 2026',
      'typeColor': const Color(0xFFf85149),
      'size': '4.5 MB',
    },
  ];

  List<Map<String, dynamic>> get filteredMaterials {
    return _allMaterials.where((material) {
      final matchesFilter = _selectedFilter == 'All' || material['type'] == _selectedFilter.toUpperCase();
      final matchesSearch = _searchQuery.isEmpty || 
          material['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          material['subject'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teaching Materials'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort, color: AppColors.text2),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Search materials...',
                hintStyle: const TextStyle(color: AppColors.text2),
                prefixIcon: const Icon(Icons.search, color: AppColors.text2),
                filled: true,
                fillColor: AppColors.background,
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

          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Lesson Plan'),
                const SizedBox(width: 8),
                _buildFilterChip('Worksheet'),
                const SizedBox(width: 8),
                _buildFilterChip('Presentation'),
                const SizedBox(width: 8),
                _buildFilterChip('Notes'),
                const SizedBox(width: 8),
                _buildFilterChip('Exam'),
              ],
            ),
          ),

          // Materials Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredMaterials.length} materials',
                  style: const TextStyle(
                    color: Color(0xFF8b949e),
                    fontSize: 14,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UploadMaterialScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                  label: const Text(
                    'Add New',
                    style: TextStyle(color: AppColors.primary, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // Materials List
          Expanded(
            child: filteredMaterials.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_off, size: 60, color: Color(0xFF8b949e)),
                        SizedBox(height: 12),
                        Text(
                          'No materials found',
                          style: TextStyle(color: Color(0xFF8b949e), fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredMaterials.length,
                    itemBuilder: (context, index) {
                      final material = filteredMaterials[index];
                      return _buildMaterialCard(material);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFF30363d),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.text2,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (material['typeColor'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  material['type'],
                  style: TextStyle(
                    color: material['typeColor'],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF8b949e), size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            material['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(Icons.school, '${material['form']} | ${material['subject']}'),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.visibility, '${material['views']}'),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.download, '${material['downloads']}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(Icons.insert_drive_file, material['size']),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.calendar_today, material['date']),
              const Spacer(),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility, size: 16, color: Color(0xFFda3633)),
                    label: const Text('View', style: TextStyle(color: Color(0xFFda3633), fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 16, color: AppColors.text2),
                    label: const Text('Edit', style: TextStyle(color: AppColors.text2, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8b949e)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12),
        ),
      ],
    );
  }
}