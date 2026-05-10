import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class UploadMaterialScreen extends StatefulWidget {
  const UploadMaterialScreen({super.key});

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  String _selectedType = 'Lesson Plan';
  String _selectedForm = 'Form 3';
  String _selectedSubject = 'Biology';
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isUploading = false;

  final List<String> _materialTypes = ['Lesson Plan', 'Worksheet', 'Presentation', 'Notes', 'Exam'];
  final List<String> _forms = ['Form 1', 'Form 2', 'Form 3', 'Form 4'];
  final List<String> _subjects = ['Biology', 'Chemistry', 'Physics', 'Mathematics', 'English'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Material'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadMaterial,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Upload',
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
            // Upload Header
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
                  Icon(Icons.upload_file, size: 40, color: AppColors.primary),
                  SizedBox(height: 12),
                  Text(
                    'Upload Teaching Material',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Share your teaching resources with students',
                    style: TextStyle(
                      color: Color(0xFFc9d1d9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Material Type
            _buildSectionTitle('Material Type'),
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
                  value: _selectedType,
                  isExpanded: true,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                  items: _materialTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
              ),
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

            // Title
            _buildSectionTitle('Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Enter material title',
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

            // Description
            _buildSectionTitle('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Describe your teaching material',
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
            const SizedBox(height: 24),

            // File Upload Area
            _buildSectionTitle('Upload File'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 60,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Drag & drop your file here',
                    style: TextStyle(
                      color: Color(0xFF8b949e),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'or',
                    style: TextStyle(
                      color: Color(0xFF8b949e),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_open, size: 18),
                    label: const Text('Browse Files'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21262d),
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: Color(0xFF30363d)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Supported formats: PDF, DOC, PPT, XLS (Max 50MB)',
                    style: TextStyle(
                      color: Color(0xFF8b949e),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadMaterial,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Material'),
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

  Future<void> _uploadMaterial() async {
    setState(() {
      _isUploading = true;
    });

    // Simulate upload
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Material uploaded successfully!'),
          backgroundColor: AppColors.primary,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}