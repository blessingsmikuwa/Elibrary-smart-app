import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

// ─── Model (unchanged) ────────────────────────────────────────────────────────
class _Paper {
  final String  id, title;
  final String? description, subject, classLevel, targetAudience, fileUrl, uploaderName;
  final DateTime? createdAt;

  const _Paper({
    required this.id, required this.title,
    this.description, this.subject, this.classLevel,
    this.targetAudience, this.fileUrl, this.uploaderName, this.createdAt,
  });

  factory _Paper.fromJson(Map<String, dynamic> json) {
    final uploader     = json['uploader'] as Map<String, dynamic>?;
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
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${createdAt!.day} ${months[createdAt!.month]} ${createdAt!.year}';
  }
}

// ─── Gradients ────────────────────────────────────────────────────────────────
const _gradients = <List<Color>>[
  [Color(0xFF059669), Color(0xFF065F46)],
  [Color(0xFF10B981), Color(0xFF047857)],
  [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
  [Color(0xFFF97316), Color(0xFFC2410C)],
  [Color(0xFFF59E0B), Color(0xFFB45309)],
  [Color(0xFF14B8A6), Color(0xFF0F766E)],
  [Color(0xFFEF4444), Color(0xFF991B1B)],
  [Color(0xFF34D399), Color(0xFF059669)],
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class PastPapersScreen extends StatefulWidget {
  const PastPapersScreen({super.key});
  @override
  State<PastPapersScreen> createState() => _PastPapersScreenState();
}

class _PastPapersScreenState extends State<PastPapersScreen> {
  static const _perPage = 12;

  List<_Paper> _papers  = [];
  bool         _loading = true;
  String?      _error;

  String _level   = 'All Levels';
  String _subject = 'All Subjects';
  int    _page    = 1;

  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _fetch(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await authHeaders();
      final res = await http.get(Uri.parse('$kApiBase/resources'), headers: headers);
      if (res.statusCode != 200) throw Exception('Failed to load resources (${res.statusCode})');
      final body    = jsonDecode(res.body);
      final rawList = body is Map ? (body['data'] as List?) ?? [] : body as List;
      final papers  = (rawList as List<dynamic>)
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
      await http.post(Uri.parse('$kApiBase/activity'), headers: headers,
          body: jsonEncode({'action': action, 'resourceTitle': title}));
    } catch (_) {}
  }

  Future<void> _open(_Paper paper, String action) async {
    if (paper.fileUrl == null || paper.fileUrl!.isEmpty) {
      _snack('No file available for "${paper.title}"'); return;
    }
    if (action == 'DOWNLOAD') {
      try {
        final headers = await authHeaders();
        await http.post(
            Uri.parse('$kApiBase/resources/${paper.id}/download'), headers: headers);
      } catch (_) {}
    }
    await _logActivity(action, paper.title);
    try {
      await launchUrl(Uri.parse(paper.fileUrl!), mode: LaunchMode.externalApplication);
    } catch (_) { _snack('Could not open file'); }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  List<String> get _subjects {
    final s = _papers.map((p) => p.subject).whereType<String>().toSet().toList()..sort();
    return ['All Subjects', ...s];
  }

  List<_Paper> get _filtered => _papers.where((p) {
        final q            = _searchCtrl.text.toLowerCase();
        final matchSearch  = q.isEmpty ||
            p.title.toLowerCase().contains(q) ||
            (p.description?.toLowerCase().contains(q) ?? false);
        final matchLevel   = _level   == 'All Levels'   || p.classLevel == _level;
        final matchSubject = _subject == 'All Subjects'  || p.subject    == _subject;
        return matchSearch && matchLevel && matchSubject;
      }).toList();

  List<_Paper> get _pageItems {
    final start = (_page - 1) * _perPage;
    return _filtered.skip(start).take(_perPage).toList();
  }

  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 9999);
  void _resetPage() => setState(() => _page = 1);

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: t.primary,
          onRefresh: _fetch,
          child: _loading
              ? Center(child: CircularProgressIndicator(color: t.primary))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Hero ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          t.primary.withValues(alpha: 0.2),
                          t.teal.withValues(alpha: 0.2),
                        ]),
                        border: Border.all(color: t.primary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [t.primary, t.teal]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.assignment_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Past Papers',
                              style: TextStyle(
                                  color: t.text, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Access and download past examination papers',
                              style: TextStyle(
                                  color: t.primary.withValues(alpha: 0.8),
                                  fontSize: 13)),
                        ]),
                      ]),
                    ),

                    // ── Filter card ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: t.surface, border: Border.all(color: t.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(children: [
                        if (_error != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: t.errorBg,
                              border: Border.all(color: t.errorBorder),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Icon(Icons.error_outline_rounded, color: t.danger, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!,
                                  style: TextStyle(color: t.danger, fontSize: 14))),
                            ]),
                          ),
                        ],

                        Row(children: [
                          Expanded(child: TextField(
                            controller: _searchCtrl,
                            style: TextStyle(color: t.text, fontSize: 15),
                            decoration: InputDecoration(
                              hintText:  'Search past papers...',
                              hintStyle: TextStyle(color: t.subtle),
                              prefixIcon: Icon(Icons.search, color: t.muted),
                              filled: true, fillColor: t.inputFill,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              border:        OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.border)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: t.primary)),
                            ),
                            onChanged: (_) => _resetPage(),
                          )),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [t.primary, t.teal]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.search, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),

                        Row(children: [
                          Expanded(child: _buildDropdown(
                            value: _level,
                            items: const ['All Levels','Form 1','Form 2','Form 3','Form 4'],
                            label: 'Level',
                            theme: t,
                            onChanged: (v) { setState(() => _level = v!); _resetPage(); },
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _buildDropdown(
                            value: _subject,
                            items: _subjects,
                            label: 'Subject',
                            theme: t,
                            onChanged: (v) { setState(() => _subject = v!); _resetPage(); },
                          )),
                        ]),
                      ]),
                    ),

                    Text(
                      'Showing ${_pageItems.length} of ${_filtered.length} past papers',
                      style: TextStyle(color: t.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    if (_pageItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: t.surface, border: Border.all(color: t.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(children: [
                          Icon(Icons.description_outlined, size: 44, color: t.subtle),
                          const SizedBox(height: 14),
                          Text('No past papers found.',
                              style: TextStyle(color: t.subtle, fontSize: 15)),
                        ]),
                      )
                    else
                      ...(_pageItems.asMap().entries.map((e) => _buildCard(e.value, e.key, t))),

                    if (_totalPages > 1) _buildPagination(t),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value, required List<String> items,
    required String label, required ValueChanged<String?> onChanged,
    required AppThemeData theme,
  }) {
    final v = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: v, isExpanded: true,
      dropdownColor: theme.surface,
      style: TextStyle(color: theme.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: theme.muted, fontSize: 13),
        filled: true, fillColor: theme.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border:        OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primary)),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCard(_Paper paper, int index, AppThemeData t) {
    final gradient = _gradients[index % _gradients.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface, border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Container(
            width: 56, height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: gradient),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Colors.white54, size: 28),
          ),
          Positioned(
            top: -2, right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [t.primary, t.teal]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('PDF',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(width: 14),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(paper.title,
              style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 16)),

          if (paper.uploaderName != null)
            Text('By ${paper.uploaderName}  ·  ${paper.formattedDate}',
                style: TextStyle(color: t.subtle, fontSize: 12)),

          const SizedBox(height: 8),

          Wrap(spacing: 6, runSpacing: 4, children: [
            if (paper.subject != null)
              _Tag(label: paper.subject!, color: t.primary, theme: t),
            if (paper.classLevel != null)
              _Tag(label: paper.classLevel!, outlined: true, theme: t),
            if (paper.targetAudience != null)
              _Tag(label: paper.targetAudience!, outlined: true, theme: t),
          ]),

          if (paper.description != null) ...[
            const SizedBox(height: 6),
            Text(paper.description!,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.subtle, fontSize: 13)),
          ],

          const SizedBox(height: 12),

          Wrap(spacing: 8, runSpacing: 8, children: [
            _Btn(
              label: '👁️ Preview',
              color: t.primary,
              onTap: () => _open(paper, 'RESOURCE_VIEWED'),
            ),
            _Btn(
              label: '⬇️ Download',
              color: t.teal,
              onTap: () => _open(paper, 'DOWNLOAD'),
            ),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildPagination(AppThemeData t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _PagBtn(enabled: _page > 1, icon: Icons.chevron_left, theme: t,
              onTap: () => setState(() => _page--)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$_page / $_totalPages',
                style: TextStyle(color: t.text, fontSize: 15)),
          ),
          _PagBtn(enabled: _page < _totalPages, icon: Icons.chevron_right, theme: t,
              onTap: () => setState(() => _page++)),
        ]),
      );
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final bool   outlined;
  final AppThemeData theme;
  const _Tag({required this.label, required this.theme, this.color, this.outlined = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color?.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: outlined ? Border.all(color: theme.border) : null,
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: outlined ? theme.subtle : (color ?? theme.primary),
        )),
      );
}

class _Btn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.85)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
}

class _PagBtn extends StatelessWidget {
  final IconData icon; final bool enabled; final VoidCallback onTap;
  final AppThemeData theme;
  const _PagBtn({required this.icon, required this.enabled, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: enabled ? theme.border : theme.border.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: enabled ? theme.text : theme.subtle, size: 20),
        ),
      );
}