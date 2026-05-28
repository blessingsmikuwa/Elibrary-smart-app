import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart'; // kApiBase, authHeaders()

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
    case 'ppt':
    case 'pptx': return MediaType('application', 'vnd.ms-powerpoint');
    case 'mp4':  return MediaType('video', 'mp4');
    case 'png':  return MediaType('image', 'png');
    case 'jpg':
    case 'jpeg': return MediaType('image', 'jpeg');
    default:     return MediaType('application', 'octet-stream');
  }
}

/// Shown as a full-screen overlay modal, matching the web upload modal.
class UploadModal extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onUploaded;
  final void Function(String, {String type}) toast;

  const UploadModal({
    required this.onClose,
    required this.onUploaded,
    required this.toast,
  });

  @override
  State<UploadModal> createState() => _UploadModalState();
}

class _UploadModalState extends State<UploadModal> {
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

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _classes    = [];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final headers = await authHeaders();
      final catRes = await http.get(Uri.parse('$kApiBase/categories'), headers: headers);
      final clsRes = await http.get(Uri.parse('$kApiBase/classes'),    headers: headers);
      if (catRes.statusCode == 200) {
        final data = jsonDecode(catRes.body);
        setState(() => _categories = List<Map<String, dynamic>>.from(
            data is List ? data : (data['data'] ?? [])));
      }
      if (clsRes.statusCode == 200) {
        final data = jsonDecode(clsRes.body);
        final list = List<Map<String, dynamic>>.from(
            data is List ? data : (data['data'] ?? []));
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
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'mp4', 'png', 'jpg'],
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
    if (_title.trim().isEmpty) {
      widget.toast('Please fill in the title.', type: 'error'); return;
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
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          _fileBytes!,
          filename: _pickedFile!.name,
          contentType: _mimeFor(_pickedFile!.extension ?? ''),
        ));

      if (_categoryId != null) request.fields['categoryId'] = _categoryId!;
      if (_classId    != null) request.fields['classId']    = _classId!;

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
      setState(() { _uploading = false; _progress = 0; });
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
            color: const Color(0xFF161b22),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF30363d)),
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
                child: Row(
                  children: [
                    const Text('📤 Upload New Resource',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF6e7681)),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF21262d)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── File drop zone (tap to browse) ────────────
                      GestureDetector(
                        onTap: _uploading ? null : _pickFile,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: _pickedFile != null
                                ? const Color(0xFF0d1117)
                                : const Color(0xFF0d1117),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _pickedFile != null
                                  ? const Color(0xFF2ea043)
                                  : const Color(0xFF30363d),
                              width: _pickedFile != null ? 2 : 1,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _pickedFile != null ? '📄' : '☁️',
                                style: const TextStyle(fontSize: 30),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _pickedFile != null
                                    ? _pickedFile!.name
                                    : 'Tap to browse a file',
                                style: TextStyle(
                                  color: _pickedFile != null
                                      ? const Color(0xFF2ea043)
                                      : const Color(0xFF8b949e),
                                  fontSize: 13,
                                  fontWeight: _pickedFile != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _pickedFile != null
                                    ? '${(_pickedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB'
                                    : 'PDF, DOCX, MP4, Images',
                                style: const TextStyle(
                                    color: Color(0xFF6e7681), fontSize: 11),
                              ),
                              if (_pickedFile != null) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => setState(
                                      () { _pickedFile = null; _fileBytes = null; }),
                                  child: const Text('Remove file',
                                      style: TextStyle(
                                          color: Color(0xFFf85149),
                                          fontSize: 12)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      if (_uploading) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: const Color(0xFF30363d),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF2ea043)),
                            minHeight: 5,
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // ── Title ─────────────────────────────────────
                      _label('Resource Title *'),
                      _input(
                        hint: 'e.g. Form 3 Biology Notes',
                        onChanged: (v) => _title = v,
                      ),
                      const SizedBox(height: 12),

                      // ── Description ───────────────────────────────
                      _label('Description'),
                      _input(
                        hint: 'Brief description',
                        maxLines: 2,
                        onChanged: (v) => _description = v,
                      ),
                      const SizedBox(height: 12),

                      // ── Subject + Form ────────────────────────────
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Subject'),
                              _dropdown(
                                hint: 'Select subject',
                                value: _categoryId,
                                items: _categories
                                    .map((c) => DropdownMenuItem<String>(
                                          value: c['id']?.toString(),
                                          child: Text(c['name']?.toString() ?? ''),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _categoryId = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Form'),
                              _dropdown(
                                hint: 'Select form',
                                value: _classId,
                                items: _classes
                                    .map((c) => DropdownMenuItem<String>(
                                          value: c['id']?.toString(),
                                          child: Text(c['name']?.toString() ?? ''),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _classId = v),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),

                      // ── Type + Audience ───────────────────────────
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('File Type'),
                              _dropdown(
                                hint: '',
                                value: _selectedLabel,
                                items: _resourceTypes
                                    .map((t) => DropdownMenuItem<String>(
                                          value: t['label'],
                                          child: Text(t['label']!),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) _handleTypeChange(v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Audience'),
                              _dropdown(
                                hint: '',
                                value: _targetAudience,
                                items: ['Students', 'Teachers', 'Both']
                                    .map((v) => DropdownMenuItem<String>(
                                          value: v,
                                          child: Text(v),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _targetAudience = v ?? 'Students'),
                              ),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),

                      // ── Visibility ────────────────────────────────
                      _label('Visibility'),
                      _dropdown(
                        hint: '',
                        value: _visibility,
                        items: const [
                          DropdownMenuItem(value: 'PUBLIC',  child: Text('Public')),
                          DropdownMenuItem(
                              value: 'PRIVATE', child: Text('Private (School Only)')),
                        ],
                        onChanged: (v) =>
                            setState(() => _visibility = v ?? 'PUBLIC'),
                      ),

                      const SizedBox(height: 22),

                      // ── Buttons ───────────────────────────────────
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onClose,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF30363d)),
                              foregroundColor: Colors.white,
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
                              backgroundColor: const Color(0xFF2ea043),
                              disabledBackgroundColor: const Color(0xFF30363d),
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
    child: Text(text,
        style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12)),
  );

  InputDecoration _inputDecoration({String hint = '', int? maxLines}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6e7681)),
        filled: true,
        fillColor: const Color(0xFF0d1117),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF21262d)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF21262d)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2ea043), width: 1.5),
        ),
      );

  Widget _input({
    required String hint,
    int maxLines = 1,
    required void Function(String) onChanged,
  }) =>
      TextField(
        onChanged: onChanged,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: _inputDecoration(hint: hint),
      );

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) =>
      DropdownButtonFormField<T>(
        value: value,
        decoration: _inputDecoration(),
        hint: hint.isNotEmpty
            ? Text(hint, style: const TextStyle(color: Color(0xFF6e7681), fontSize: 13))
            : null,
        dropdownColor: const Color(0xFF161b22),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        items: items,
        onChanged: onChanged,
      );
}

/// Thin wrapper so teacher_home_screen.dart can still push this as a full screen.
class UploadMaterialScreen extends StatelessWidget {
  const UploadMaterialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161b22),
        title: const Text('Upload Material',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          const SizedBox.expand(),
          UploadModal(
            onClose: () => Navigator.pop(context),
            onUploaded: () => Navigator.pop(context),
            toast: (msg, {String type = 'info'}) {
              final colors = {
                'success': const Color(0xFF2ea043),
                'error':   const Color(0xFFf85149),
                'info':    const Color(0xFF58a6ff),
              };
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(msg),
                backgroundColor: colors[type],
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
        ],
      ),
    );
  }
}