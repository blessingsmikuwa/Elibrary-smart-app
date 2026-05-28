import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/api_service.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class _Paper {
  final String  id;
  final String  title;
  final String? description;
  final String? subject;
  final String? classLevel;
  final String? targetAudience;
  final String? fileUrl;
  final String? uploaderName;
  final DateTime? createdAt;

  const _Paper({
    required this.id,
    required this.title,
    this.description,
    this.subject,
    this.classLevel,
    this.targetAudience,
    this.fileUrl,
    this.uploaderName,
    this.createdAt,
  });

  factory _Paper.fromJson(Map<String, dynamic> json) {
    final uploader = json['uploader'] as Map<String, dynamic>?;
    final uploaderName = uploader != null
        ? '${uploader['firstName'] ?? ''} ${uploader['lastName'] ?? ''}'.trim()
        : null;

    DateTime? createdAt;
    if (json['createdAt'] is String) {
      try { createdAt = DateTime.parse(json['createdAt']); } catch (_) {}
    }

    return _Paper(
      id:             json['id']?.toString()            ?? '',
      title:          json['title']?.toString()         ?? 'Untitled',
      description:    json['description']?.toString(),
      subject:        (json['category']    as Map<String, dynamic>?)?['name']?.toString(),
      classLevel:     (json['targetClass'] as Map<String, dynamic>?)?['name']?.toString(),
      targetAudience: json['targetAudience']?.toString(),
      fileUrl:        json['fileUrl']?.toString(),
      uploaderName:   uploaderName?.isEmpty ?? true ? null : uploaderName,
      createdAt:      createdAt,
    );
  }

  String get formattedDate {
    if (createdAt == null) return '—';
    final d = createdAt!;
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ─── Gradients ────────────────────────────────────────────────────────────────

const _gradients = <List<Color>>[
  [Color(0xFF2563EB), Color(0xFF1E3A8A)],
  [Color(0xFF16A34A), Color(0xFF14532D)],
  [Color(0xFF9333EA), Color(0xFF581C87)],
  [Color(0xFFF97316), Color(0xFF9A3412)],
  [Color(0xFFEAB308), Color(0xFFA16207)],
  [Color(0xFF14B8A6), Color(0xFF115E59)],
  [Color(0xFFDC2626), Color(0xFF7F1D1D)],
  [Color(0xFF4F46E5), Color(0xFF312E81)],
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class PastPapersScreen extends StatefulWidget {
  const PastPapersScreen({super.key});

  @override
  State<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends State<PastPapersScreen> {
  static const _primary = Color(0xFF2EA043);
  static const _bg      = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);
  static const _subtle  = Color(0xFF6E7681);

  static const _perPage = 12;

  List<_Paper> _papers = [];
  bool         _loading = true;
  String?      _error;

  String _search  = 'All Levels';
  String _level   = 'All Levels';
  String _subject = 'All Subjects';
  int    _page    = 1;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await authHeaders();
      final res = await http.get(
        Uri.parse('$kApiBase/resources'),
        headers: headers,
      );
      if (res.statusCode != 200) throw Exception('Failed to load resources (${res.statusCode})');

      final body = jsonDecode(res.body);
      final rawList = body is Map ? (body['data'] as List?) ?? [] : body as List;

      final papers = (rawList as List<dynamic>)
          .where((e) => (e as Map<String, dynamic>)['form'] == 'OTHER')
          .map((e) => _Paper.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() { _papers = papers; _page = 1; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logActivity(String action, String title) async {
    try {
      final headers = await authHeaders();
      await http.post(
        Uri.parse('$kApiBase/activity'),
        headers: headers,
        body: jsonEncode({'action': action, 'resourceTitle': title}),
      );
    } catch (_) {}
  }

  Future<void> _open(_Paper paper, String action) async {
    if (paper.fileUrl == null || paper.fileUrl!.isEmpty) {
      _snack('No file available for "${paper.title}"');
      return;
    }
    // Log download separately
    if (action == 'DOWNLOAD') {
      try {
        final headers = await authHeaders();
        await http.post(
          Uri.parse('$kApiBase/resources/${paper.id}/download'),
          headers: headers,
        );
      } catch (_) {}
    }
    await _logActivity(action, paper.title);
    try {
      await launchUrl(Uri.parse(paper.fileUrl!), mode: LaunchMode.externalApplication);
    } catch (_) {
      _snack('Could not open file');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<String> get _subjects {
    final s = _papers.map((p) => p.subject).whereType<String>().toSet().toList()..sort();
    return ['All Subjects', ...s];
  }

  List<_Paper> get _filtered => _papers.where((p) {
    final q = _searchCtrl.text.toLowerCase();
    final matchSearch  = q.isEmpty ||
        p.title.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false);
    final matchLevel   = _level   == 'All Levels'   || p.classLevel == _level;
    final matchSubject = _subject == 'All Subjects'  || p.subject    == _subject;
    return matchSearch && matchLevel && matchSubject;
  }).toList();

  List<_Paper> get _page_items {
    final start = (_page - 1) * _perPage;
    return _filtered.skip(start).take(_perPage).toList();
  }

  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 9999);

  void _resetPage() => setState(() => _page = 1);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Past Papers'),
        backgroundColor: _bg,
        foregroundColor: _text,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D1A1A),
                        border: Border.all(color: const Color(0xFFF85149)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: const TextStyle(color: Color(0xFFF85149))),
                    ),

                  // Search
                  TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: _text),
                    decoration: InputDecoration(
                      hintText: 'Search past papers...',
                      hintStyle: const TextStyle(color: _subtle),
                      prefixIcon: const Icon(Icons.search, color: _muted),
                      filled: true,
                      fillColor: _surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _border),
                      ),
                    ),
                    onChanged: (_) => _resetPage(),
                  ),
                  const SizedBox(height: 10),

                  // Filters
                  Row(children: [
                    Expanded(child: _buildDropdown(
                      value: _level,
                      items: const ['All Levels', 'Form 1', 'Form 2', 'Form 3', 'Form 4'],
                      label: 'Level',
                      onChanged: (v) { setState(() => _level = v!); _resetPage(); },
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _buildDropdown(
                      value: _subject,
                      items: _subjects,
                      label: 'Subject',
                      onChanged: (v) { setState(() => _subject = v!); _resetPage(); },
                    )),
                  ]),
                  const SizedBox(height: 14),

                  // Count
                  Text(
                    'Showing ${_page_items.length} of ${_filtered.length} past papers',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  if (_page_items.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('No past papers found.', style: TextStyle(color: _subtle)),
                      ),
                    )
                  else
                    ...(_page_items.mapIndexed((i, paper) => _buildCard(paper, i))),

                  if (_totalPages > 1) _buildPagination(),
                ],
              ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    final v = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: v,
      isExpanded: true,
      dropdownColor: _surface,
      style: const TextStyle(color: _text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCard(_Paper paper, int index) {
    final gradient = _gradients[index % _gradients.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Gradient icon
        Container(
          width: 52, height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.picture_as_pdf, color: Colors.white54, size: 28),
        ),
        const SizedBox(width: 14),

        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paper.title,
              style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            if (paper.uploaderName != null)
              Text(
                'By ${paper.uploaderName}  ·  ${paper.formattedDate}',
                style: const TextStyle(color: _subtle, fontSize: 12),
              ),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              if (paper.subject != null)
                _Tag(label: paper.subject!, color: _primary),
              if (paper.classLevel != null)
                const _Tag(label: '', outlined: true, passthrough: true)
                    .copyWith(label: paper.classLevel!),
              if (paper.targetAudience != null)
                _Tag(label: paper.targetAudience!, outlined: true),
            ]),
            if (paper.description != null) ...[
              const SizedBox(height: 4),
              Text(
                paper.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _subtle, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Row(children: [
              _Btn(
                label: '👁️ Preview',
                color: _primary,
                onTap: () => _open(paper, 'RESOURCE_VIEWED'),
              ),
              const SizedBox(width: 8),
              _Btn(
                label: '⬇️ Download',
                color: const Color(0xFF1F6FEB),
                onTap: () => _open(paper, 'DOWNLOAD'),
              ),
            ]),
          ],
        )),
      ]),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: _page == 1 ? _subtle : _text,
          onPressed: _page == 1 ? null : () => setState(() => _page--),
        ),
        Text('$_page / $_totalPages', style: const TextStyle(color: _text)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          color: _page == _totalPages ? _subtle : _text,
          onPressed: _page == _totalPages ? null : () => setState(() => _page++),
        ),
      ]),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final bool outlined;
  final bool passthrough;

  const _Tag({
    required this.label,
    this.color,
    this.outlined = false,
    this.passthrough = false,
  });

  _Tag copyWith({required String label}) => _Tag(
    label: label, color: color, outlined: outlined, passthrough: passthrough,
  );

  @override
  Widget build(BuildContext context) {
    if (passthrough) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color?.withValues(alpha: 0.15) ?? Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: outlined ? Border.all(color: const Color(0xFF21262D)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: outlined ? const Color(0xFF6E7681) : (color ?? const Color(0xFF2EA043)),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Extension ────────────────────────────────────────────────────────────────

extension _IndexedMap<T> on List<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T item) fn) sync* {
    for (var i = 0; i < length; i++) yield fn(i, this[i]);
  }
}