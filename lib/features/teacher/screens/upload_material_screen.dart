import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';

const _resourceTypes = [
  {'label': 'PDF Document',  'type': 'PDF',   'form': 'DOCUMENT'},
  {'label': 'Word Document', 'type': 'PDF',   'form': 'DOCUMENT'},
  {'label': 'Past Paper',    'type': 'PDF',   'form': 'OTHER'},
  {'label': 'Video',         'type': 'VIDEO', 'form': 'VIDEO'},
  {'label': 'Image',         'type': 'IMAGE', 'form': 'OTHER'},
];

MediaType _mimeFor(String ext) {
  switch (ext.toLowerCase()) {
    case 'pdf':  return MediaType('application', 'pdf');
    case 'doc':
    case 'docx': return MediaType('application', 'msword');
    case 'mp4':  return MediaType('video', 'mp4');
    case 'png':  return MediaType('image', 'png');
    case 'jpg':
    case 'jpeg': return MediaType('image', 'jpeg');
    default:     return MediaType('application', 'octet-stream');
  }
}

const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _border  = Color(0xFF21262D);
const _text    = Color(0xFFE6EDF3);
const _muted   = Color(0xFF8B949E);
const _subtle  = Color(0xFF6E7681);
const _primary = Color(0xFF2EA043);
const _danger  = Color(0xFFF85149);
const _amber   = Color(0xFFE3A525);

class UploadModal extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onUploaded;
  final void Function(String, {String type}) toast;

  const UploadModal({
    super.key,
    required this.onClose,
    required this.onUploaded,
    required this.toast,
  });

  @override
  State<UploadModal> createState() => _UploadModalState();
}

class _UploadModalState extends State<UploadModal> {
  // Form values
  String        _title          = '';
  String        _description    = '';
  String?       _categoryId;
  String?       _classId;
  String        _selectedLabel  = 'PDF Document';
  String        _type           = 'PDF';
  String        _resourceForm   = 'DOCUMENT';
  String        _targetAudience = 'Students';
  String        _visibility     = 'PUBLIC';
  PlatformFile? _pickedFile;
  Uint8List?    _fileBytes;
  bool          _uploading      = false;
  double        _progress       = 0;

  // Dropdown data
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _classes    = [];

  // Teacher's school (fetched from profile)
  String? _teacherSchoolId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final headers = await authHeaders();

      // Fetch profile, categories, classes in parallel
      final results = await Future.wait([
        http.get(Uri.parse('$kApiBase/auth/me'),    headers: headers),
        http.get(Uri.parse('$kApiBase/categories'), headers: headers),
        http.get(Uri.parse('$kApiBase/classes'),    headers: headers),
      ]);

      // Profile → schoolId
      if (results[0].statusCode == 200) {
        final d = jsonDecode(results[0].body);
        final id = d['schoolId']
            ?? d['school']?['id']
            ?? d['data']?['schoolId'];
        if (id != null) setState(() => _teacherSchoolId = id.toString());
      }

      // Categories
      if (results[1].statusCode == 200) {
        final d = jsonDecode(results[1].body);
        setState(() => _categories = List<Map<String, dynamic>>.from(
            d is List ? d : (d['data'] ?? [])));
      }

      // Classes — sorted numerically
      if (results[2].statusCode == 200) {
        final d    = jsonDecode(results[2].body);
        final list = List<Map<String, dynamic>>.from(
            d is List ? d : (d['data'] ?? []));
        list.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
        setState(() => _classes = list);
      }
    } catch (_) {}
  }

  void _handleTypeChange(String label) {
    final matched = _resourceTypes.firstWhere(
        (t) => t['label'] == label,
        orElse: () => _resourceTypes.first);
    setState(() {
      _selectedLabel = label;
      _type          = matched['type']!;
      _resourceForm  = matched['form']!;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'mp4', 'png', 'jpg'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedFile = result.files.first;
        _fileBytes  = result.files.first.bytes;
      });
    }
  }

  Future<void> _upload() async {
    // Validation
    if (_title.trim().isEmpty) {
      widget.toast('Please enter a title.', type: 'error'); return;
    }
    if (_categoryId == null) {
      widget.toast('Please select a subject.', type: 'error'); return;
    }
    if (_classId == null) {
      widget.toast('Please select a form level.', type: 'error'); return;
    }
    if (_pickedFile == null || _fileBytes == null) {
      widget.toast('Please select a file.', type: 'error'); return;
    }

    setState(() { _uploading = true; _progress = 0; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final uri     = Uri.parse('$kApiBase/resources/create-with-file');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['title']          = _title.trim()
        ..fields['description']    = _description.trim()
        ..fields['type']           = _type
        ..fields['form']           = _resourceForm
        ..fields['status']         = 'PUBLISHED'
        ..fields['targetAudience'] = _targetAudience
        ..fields['visibility']     = _visibility
        ..fields['categoryId']     = _categoryId!
        ..fields['classId']        = _classId!
        ..fields['isPremium']      = 'false'
        ..fields['price']          = '0'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _fileBytes!,
          filename:    _pickedFile!.name,
          contentType: _mimeFor(_pickedFile!.extension ?? ''),
        ));

      // Only send schoolId when visibility is PRIVATE
      if (_visibility == 'PRIVATE' && _teacherSchoolId != null) {
        request.fields['schoolId'] = _teacherSchoolId!;
      }

      setState(() => _progress = 0.3);
      final streamed = await request.send();
      setState(() => _progress = 0.8);
      final res = await http.Response.fromStream(streamed);
      setState(() => _progress = 1.0);

      if (res.statusCode < 300) {
        widget.toast('"$_title" uploaded successfully!', type: 'success');
        widget.onUploaded();
      } else {
        final body = jsonDecode(res.body);
        widget.toast(body['message']?.toString() ?? 'Upload failed', type: 'error');
      }
    } catch (e) {
      widget.toast('Error: $e', type: 'error');
    } finally {
      if (mounted) setState(() { _uploading = false; _progress = 0; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                child: Row(children: [
                  const Text('📤 Upload New Resource',
                      style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: _muted),
                    onPressed: widget.onClose,
                  ),
                ]),
              ),
              const Divider(color: _border),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── File picker ───────────────────────────────
                      GestureDetector(
                        onTap: _uploading ? null : _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _pickedFile != null ? _primary : const Color(0xFF30363D),
                              width: _pickedFile != null ? 2 : 1,
                            ),
                          ),
                          child: Column(children: [
                            Text(_pickedFile != null ? '📄' : '☁️',
                                style: const TextStyle(fontSize: 30)),
                            const SizedBox(height: 8),
                            Text(
                              _pickedFile != null ? _pickedFile!.name : 'Tap to browse a file',
                              style: TextStyle(
                                color: _pickedFile != null ? _primary : _muted,
                                fontSize: 13,
                                fontWeight: _pickedFile != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _pickedFile != null
                                  ? '${(_pickedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB'
                                  : 'PDF, DOCX, MP4, Images',
                              style: const TextStyle(color: _subtle, fontSize: 11),
                            ),
                            if (_pickedFile != null) ...[
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => setState(() { _pickedFile = null; _fileBytes = null; }),
                                child: const Text('Remove file',
                                    style: TextStyle(color: _danger, fontSize: 12)),
                              ),
                            ],
                          ]),
                        ),
                      ),

                      if (_uploading) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: const Color(0xFF30363D),
                            valueColor: const AlwaysStoppedAnimation(_primary),
                            minHeight: 5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // ── Title ─────────────────────────────────────
                      _label('Resource Title *'),
                      _input(hint: 'e.g. Form 3 Biology Notes',
                          onChanged: (v) => _title = v),
                      const SizedBox(height: 12),

                      // ── Description ───────────────────────────────
                      _label('Description'),
                      _input(hint: 'Brief description', maxLines: 2,
                          onChanged: (v) => _description = v),
                      const SizedBox(height: 12),

                      // ── Subject + Form (both required) ────────────
                      Row(children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Subject *'),
                            _dropdown<String>(
                              hint: 'Select subject',
                              value: _categoryId,
                              items: _categories.map((c) => DropdownMenuItem<String>(
                                value: c['id']?.toString(),
                                child: Text(c['name']?.toString() ?? ''),
                              )).toList(),
                              onChanged: (v) => setState(() => _categoryId = v),
                              hasError: _categoryId == null,
                            ),
                          ],
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Form Level *'),
                            _dropdown<String>(
                              hint: 'Select form',
                              value: _classId,
                              items: _classes.map((c) => DropdownMenuItem<String>(
                                value: c['id']?.toString(),
                                child: Text(c['name']?.toString() ?? ''),
                              )).toList(),
                              onChanged: (v) => setState(() => _classId = v),
                              hasError: _classId == null,
                            ),
                          ],
                        )),
                      ]),
                      const SizedBox(height: 12),

                      // ── Type + Audience ───────────────────────────
                      Row(children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('File Type'),
                            _dropdown<String>(
                              hint: '',
                              value: _selectedLabel,
                              items: _resourceTypes.map((t) => DropdownMenuItem<String>(
                                value: t['label'],
                                child: Text(t['label']!),
                              )).toList(),
                              onChanged: (v) { if (v != null) _handleTypeChange(v); },
                            ),
                          ],
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Audience'),
                            _dropdown<String>(
                              hint: '',
                              value: _targetAudience,
                              items: ['Students', 'Teachers', 'Both'].map((v) =>
                                  DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
                              onChanged: (v) => setState(() => _targetAudience = v ?? 'Students'),
                            ),
                          ],
                        )),
                      ]),
                      const SizedBox(height: 12),

                      // ── Visibility ────────────────────────────────
                      _label('Visibility'),
                      _dropdown<String>(
                        hint: '',
                        value: _visibility,
                        items: const [
                          DropdownMenuItem(value: 'PUBLIC',  child: Text('Public')),
                          DropdownMenuItem(value: 'PRIVATE', child: Text('Private (School Only)')),
                        ],
                        onChanged: (v) => setState(() => _visibility = v ?? 'PUBLIC'),
                      ),

                      // Info banner when PRIVATE
                      if (_visibility == 'PRIVATE') ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A2A1A),
                            border: Border.all(color: _amber),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _teacherSchoolId != null
                                ? '🏫 Visible only to your school.'
                                : '⚠️ School not found on your profile.',
                            style: const TextStyle(color: _amber, fontSize: 12),
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // ── Buttons ───────────────────────────────────
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onClose,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF30363D)),
                              foregroundColor: _text,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _uploading ? null : _upload,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              disabledBackgroundColor: _border,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              _uploading ? 'Uploading...' : 'Upload Resource',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: _muted, fontSize: 12)),
  );

  InputDecoration _inputDeco({String hint = '', bool hasError = false}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _subtle),
    filled: true,
    fillColor: _bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: hasError ? _danger : _border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: hasError ? _danger : _border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _primary, width: 1.5),
    ),
  );

  Widget _input({required String hint, int maxLines = 1, required void Function(String) onChanged}) =>
      TextField(
        onChanged: onChanged,
        maxLines: maxLines,
        style: const TextStyle(color: _text, fontSize: 13),
        decoration: _inputDeco(hint: hint),
      );

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool hasError = false,
  }) =>
      DropdownButtonFormField<T>(
        value: value,
        decoration: _inputDeco(hasError: hasError),
        hint: hint.isNotEmpty
            ? Text(hint, style: const TextStyle(color: _subtle, fontSize: 13))
            : null,
        dropdownColor: _surface,
        style: const TextStyle(color: _text, fontSize: 13),
        items: items,
        onChanged: onChanged,
      );
}

/// Thin wrapper for pushing as a full screen from teacher_home_screen.dart
class UploadMaterialScreen extends StatelessWidget {
  const UploadMaterialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text('Upload Material', style: TextStyle(color: _text)),
        iconTheme: const IconThemeData(color: _text),
      ),
      body: Stack(children: [
        const SizedBox.expand(),
        UploadModal(
          onClose:    () => Navigator.pop(context),
          onUploaded: () => Navigator.pop(context),
          toast: (msg, {String type = 'info'}) {
            final colors = {
              'success': _primary,
              'error':   _danger,
              'info':    const Color(0xFF58A6FF),
            };
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg),
              backgroundColor: colors[type],
              behavior: SnackBarBehavior.floating,
            ));
          },
        ),
      ]),
    );
  }
}