import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import 'api_service.dart'; 
import './upload_material_screen.dart';

const Map<String, Color> _subjectColors = {
  'Biology':    Color(0xFF2ea043),
  'Mathematics':Color(0xFF58a6ff),
  'English':    Color(0xFFe3a525),
  'Physics':    Color(0xFFa371f7),
  'Chemistry':  Color(0xFFf85149),
  'History':    Color(0xFF56d364),
};
Color _subjectColor(String? subject) =>
    _subjectColors[subject] ?? const Color(0xFF8b949e);

class TeachingMaterialsScreen extends StatefulWidget {
  const TeachingMaterialsScreen({super.key});

  @override
  State<TeachingMaterialsScreen> createState() => _TeachingMaterialsScreenState();
}

class _TeachingMaterialsScreenState extends State<TeachingMaterialsScreen> {
  List<Map<String, dynamic>> _books      = [];
  bool    _loading      = true;
  String? _error;
  String  _search       = '';
  String  _filterForm    = 'All Forms';
  String  _filterSubject = 'All Subjects';
  Map<String, dynamic>? _deleteTarget;
  bool _showUploadModal = false;

  static const _forms = ['All Forms', 'Form 1', 'Form 2', 'Form 3', 'Form 4'];

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await authHeaders();
      final res = await http.get(Uri.parse('$kApiBase/resources'), headers: headers);
      if (res.statusCode < 300) {
        final body = jsonDecode(res.body);
        final List raw = body is Map ? (body['data'] as List? ?? []) : body as List;
        setState(() {
          _books   = raw.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Failed to load (${res.statusCode})'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _sendDeleteRequest() async {
    final target = _deleteTarget!;
    try {
      final headers = await authHeaders();
      await http.post(
        Uri.parse('$kApiBase/request'),
        headers: headers,
        body: jsonEncode({
          'requestName': 'Delete Resource: ${target['title']}',
          'fromUser':    'Teacher',
          'type':        'DELETE_RESOURCE',
          'description': jsonEncode({
            'resourceId': target['id'],
            'filePath':   target['fileUrl'],
            'bucket':     'online-library',
          }),
        }),
      );
      _toast('Delete request sent to admin.', type: 'success');
    } catch (e) {
      _toast('Error: $e', type: 'error');
    } finally {
      setState(() => _deleteTarget = null);
    }
  }

  void _toast(String msg, {String type = 'info'}) {
    final colors = {
      'success': AppColors.success,
      'error':   AppColors.error,
      'info':    AppColors.primary,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: colors[type],
      behavior: SnackBarBehavior.floating,
    ));
  }

  List<String> get _subjects => [
    'All Subjects',
    ...{..._books.map((b) => b['category']?['name'] as String?).whereType<String>()},
  ];

  List<Map<String, dynamic>> get _filtered => _books.where((b) {
    final matchForm    = _filterForm    == 'All Forms'    || b['targetClass']?['name'] == _filterForm;
    final matchSubject = _filterSubject == 'All Subjects' || b['category']?['name']    == _filterSubject;
    final q = _search.toLowerCase();
    final matchSearch  = q.isEmpty ||
        (b['title']       ?? '').toLowerCase().contains(q) ||
        (b['description'] ?? '').toLowerCase().contains(q);
    return matchForm && matchSubject && matchSearch;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0d1117),
        title: const Text('Resources Library',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchBooks,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header banner ────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a3a2a),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2ea043)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('📚 Resources Library',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  )),
                              SizedBox(height: 4),
                              Text(
                                'Manage and upload books, textbooks, and study materials.',
                                style: TextStyle(color: Color(0xCCffffff), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _showUploadModal = true),
                          icon: const Icon(Icons.add, size: 16, color: Colors.white),
                          label: const Text('Add New',
                              style: TextStyle(color: Colors.white, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ea043),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Stats row ─────────────────────────────────────
                  if (!_loading && _error == null) ...[
                    Row(children: [
                      _statCard('${_books.length}',          'Total Resources'),
                      const SizedBox(width: 10),
                      _statCard(
                        '${_books.map((b) => b['category']?['name']).whereType<String>().toSet().length}',
                        'Subjects',
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        '${_books.fold<int>(0, (s, b) => s + ((b['downloadCount'] as int?) ?? 0))}',
                        'Downloads',
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        '${_books.map((b) => b['targetClass']?['name']).whereType<String>().toSet().length}',
                        'Forms',
                      ),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // ── Search ────────────────────────────────────────
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '🔍  Search resources...',
                      hintStyle: const TextStyle(color: Color(0xFF6e7681)),
                      filled: true,
                      fillColor: const Color(0xFF161b22),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                        borderSide: const BorderSide(color: Color(0xFF2ea043)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Form filter ───────────────────────────────────
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _forms
                          .map((f) => _filterChip(
                                f,
                                _filterForm == f,
                                () => setState(() => _filterForm = f),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subject filter ────────────────────────────────
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _subjects
                          .map((s) => _filterChip(
                                s,
                                _filterSubject == s,
                                () => setState(() => _filterSubject = s),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    '${_filtered.length} resource${_filtered.length != 1 ? 's' : ''} found',
                    style: const TextStyle(color: Color(0xFF6e7681), fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // ── Body ──────────────────────────────────────────
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: Color(0xFF2ea043)),
                      ),
                    )
                  else if (_error != null)
                    Center(
                      child: Column(children: [
                        Text(_error!, style: const TextStyle(color: Color(0xFFf85149))),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _fetchBooks, child: const Text('Retry')),
                      ]),
                    )
                  else if (_filtered.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161b22),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF21262d)),
                      ),
                      child: const Column(children: [
                        Text('📭', style: TextStyle(fontSize: 36)),
                        SizedBox(height: 8),
                        Text('No resources match your filters.',
                            style: TextStyle(color: Color(0xFF6e7681), fontSize: 13)),
                      ]),
                    )
                  else
                    // Grid of cards — 2 columns like web
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _resourceCard(_filtered[i]),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Delete confirm modal ───────────────────────────────────
          if (_deleteTarget != null) _deleteModal(),

          // ── Upload modal ──────────────────────────────────────────
          if (_showUploadModal)
            UploadModal(
              onClose: () => setState(() => _showUploadModal = false),
              onUploaded: () {
                setState(() => _showUploadModal = false);
                _fetchBooks();
              },
              toast: _toast,
            ),
        ],
      ),
    );
  }

  Widget _statCard(String number, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF21262d)),
      ),
      child: Column(
        children: [
          Text(number,
              style: const TextStyle(
                color: Color(0xFF2ea043),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Color(0xFF6e7681), fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  Widget _filterChip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2ea043) : const Color(0xFF161b22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? const Color(0xFF2ea043) : const Color(0xFF21262d),
            ),
          ),
          child: Text(label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF6e7681),
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              )),
        ),
      );

  Widget _resourceCard(Map<String, dynamic> book) {
    final subject = book['category']?['name'] as String? ?? 'Other';
    final form    = book['targetClass']?['name'] as String? ?? '—';
    final color   = _subjectColor(subject);
    final isPublished  = book['status']     == 'PUBLISHED';
    final isPublic     = book['visibility'] == 'PUBLIC';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161b22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF21262d)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color bar (top accent like web)
          Container(height: 4, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(subject,
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      Text(form,
                          style: const TextStyle(
                              color: Color(0xFF6e7681), fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(book['title'] ?? 'Untitled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (book['description'] != null &&
                      (book['description'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(book['description'],
                        style: const TextStyle(
                            color: Color(0xFF6e7681), fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const Spacer(),
                  // Meta chips
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _metaBadge('📄 ${book['type'] ?? ''}'),
                      _metaBadge('⬇️ ${book['downloadCount'] ?? 0}'),
                      _statusBadge(
                        isPublished ? 'Published' : 'Draft',
                        isPublished
                            ? const Color(0xFF2ea043)
                            : const Color(0xFF8b949e),
                        isPublished
                            ? const Color(0xFF1a3a22)
                            : const Color(0xFF21262d),
                      ),
                      _statusBadge(
                        isPublic ? 'Public' : 'Private',
                        isPublic
                            ? const Color(0xFF388bfd)
                            : const Color(0xFFf0883e),
                        isPublic
                            ? const Color(0xFF1a2a3d)
                            : const Color(0xFF2d1f0e),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Action buttons
                  Row(children: [
                    Expanded(
                      child: _cardButton(
                        label: '👁 View',
                        bg: const Color(0xFF21262d),
                        border: const Color(0xFF30363d),
                        textColor: Colors.white,
                        onTap: () {
                          final url = book['fileUrl'] as String?;
                          if (url != null && url.isNotEmpty) {
                            // launch URL via url_launcher if available
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _cardButton(
                        label: '🗑 Remove',
                        bg: const Color(0xFF3d1a1a),
                        border: const Color(0xFFf85149),
                        textColor: const Color(0xFFf85149),
                        onTap: () => setState(() => _deleteTarget = book),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaBadge(String text) => Text(text,
      style: const TextStyle(color: Color(0xFF6e7681), fontSize: 10));

  Widget _statusBadge(String text, Color textColor, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(color: textColor, fontSize: 9)),
  );

  Widget _cardButton({
    required String label,
    required Color bg,
    required Color border,
    required Color textColor,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      );

  Widget _deleteModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161b22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFf85149)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗑️', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              const Text('Request Resource Deletion?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to request deletion of "${_deleteTarget!['title']}"? This cannot be undone.',
                style: const TextStyle(color: Color(0xFF8b949e), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _deleteTarget = null),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF30363d)),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sendDeleteRequest,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFf85149)),
                    child: const Text('Send Request',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}