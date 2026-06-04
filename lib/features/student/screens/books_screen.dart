import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import 'payment_result_screen.dart';

// ─── Offline service (unchanged) ──────────────────────────────────────────────
class _OfflineService {
  static const _metaKey = 'offline_books_meta';

  static Future<String> _booksDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir  = Directory('${base.path}/offline_books');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  static Future<String?> localPath(String bookId) async {
    final dir  = await _booksDir();
    final file = File('$dir/$bookId.pdf');
    return file.existsSync() ? file.path : null;
  }

  static Future<bool> isSaved(String bookId) async => (await localPath(bookId)) != null;

  static Future<void> save({
    required String bookId,
    required String title,
    required String fileUrl,
    void Function(double)? onProgress,
  }) async {
    final dir    = await _booksDir();
    final file   = File('$dir/$bookId.pdf');
    final client = http.Client();
    try {
      final req  = http.Request('GET', Uri.parse(fileUrl));
      final resp = await client.send(req);
      final total = resp.contentLength ?? 0;
      int received = 0;
      final sink = file.openWrite();
      await for (final chunk in resp.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.close();
    } catch (e) {
      if (file.existsSync()) file.deleteSync();
      rethrow;
    } finally {
      client.close();
    }
    await _addMeta(bookId, title);
  }

  static Future<void> remove(String bookId) async {
    final dir  = await _booksDir();
    final file = File('$dir/$bookId.pdf');
    if (file.existsSync()) file.deleteSync();
    await _removeMeta(bookId);
  }

  static Future<List<Map<String, dynamic>>> savedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_metaKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  static Future<void> _addMeta(String bookId, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final list  = await savedBooks();
    if (!list.any((b) => b['id'] == bookId)) {
      list.add({'id': bookId, 'title': title, 'savedAt': DateTime.now().toIso8601String()});
      await prefs.setString(_metaKey, jsonEncode(list));
    }
  }

  static Future<void> _removeMeta(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final list  = await savedBooks();
    list.removeWhere((b) => b['id'] == bookId);
    await prefs.setString(_metaKey, jsonEncode(list));
  }
}

// ─── Model (unchanged) ────────────────────────────────────────────────────────
class _Book {
  final String  id;
  final String  title;
  final String? description;
  final String? categoryName;
  final String? targetClassName;
  final double  price;
  final String? currency;
  final bool    isPurchased;
  final String? fileUrl;

  const _Book({
    required this.id, required this.title,
    this.description, this.categoryName, this.targetClassName,
    required this.price, this.currency,
    required this.isPurchased, this.fileUrl,
  });

  bool get isPaid    => price > 0;
  bool get canAccess => !isPaid || isPurchased;

  String get formattedPrice {
    if (price <= 0) return 'Free';
    return '${currency ?? 'MWK'} ${price.toStringAsFixed(2)}';
  }

  factory _Book.fromJson(Map<String, dynamic> json, Set<String> purchasedIds) {
    double price = 0;
    final raw = json['price'] ?? json['amount'] ?? json['cost'];
    if (raw is num)    price = raw.toDouble();
    if (raw is String) price = double.tryParse(raw) ?? 0;

    final purchased =
        purchasedIds.contains(json['id'] as String? ?? '') ||
        json['purchased']   == true ||
        json['isPurchased'] == true ||
        json['hasAccess']   == true;

    return _Book(
      id:              json['id']?.toString()           ?? '',
      title:           json['title']?.toString()        ?? 'Untitled',
      description:     json['description']?.toString(),
      categoryName:    (json['category']    as Map<String, dynamic>?)?['name']?.toString(),
      targetClassName: (json['targetClass'] as Map<String, dynamic>?)?['name']?.toString(),
      price:           price,
      currency:        json['currency']?.toString(),
      isPurchased:     purchased,
      fileUrl:         json['fileUrl']?.toString(),
    );
  }
}

// ─── Subject icons ────────────────────────────────────────────────────────────
const _subjectIcons = <String, IconData>{
  'Mathematics': Icons.calculate,
  'Biology':     Icons.biotech,
  'Chemistry':   Icons.science,
  'Physics':     Icons.electric_bolt,
  'English':     Icons.menu_book,
  'History':     Icons.history_edu,
  'Geography':   Icons.public,
};

IconData _iconFor(String? subject) => _subjectIcons[subject ?? ''] ?? Icons.menu_book;

// ─── Gradient palette for book thumbnails ─────────────────────────────────────
const _bookGradients = <List<Color>>[
  [Color(0xFF059669), Color(0xFF065F46)],
  [Color(0xFF10B981), Color(0xFF047857)],
  [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
  [Color(0xFFF97316), Color(0xFFC2410C)],
  [Color(0xFFF59E0B), Color(0xFFB45309)],
  [Color(0xFF14B8A6), Color(0xFF0F766E)],
  [Color(0xFFEF4444), Color(0xFF991B1B)],
  [Color(0xFF34D399), Color(0xFF059669)],
];

enum _BookType { free, premium }
enum _ViewMode { browse, offline }

// ─── Screen ───────────────────────────────────────────────────────────────────
class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});
  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  List<_Book> _books       = [];
  bool        _loading     = true;
  String?     _error;
  bool        _purchasing  = false;

  _BookType _bookType = _BookType.free;
  _ViewMode _viewMode = _ViewMode.browse;
  String    _search   = '';
  String    _level    = 'All Levels';
  String    _subject  = 'All Subjects';
  int       _page     = 1;

  List<Map<String, dynamic>> _savedMeta = [];
  static const _perPage = 12;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _fetchAll(); _loadOfflineMeta(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await authHeaders();
      final res = await http.get(Uri.parse('$kApiBase/resources'), headers: headers);
      if (res.statusCode != 200) throw Exception('Failed to load resources');
      final body    = jsonDecode(res.body);
      final rawList = body is Map ? (body['data'] as List?) ?? [] : body as List;
      final all     = (rawList as List<dynamic>)
          .where((e) => (e as Map<String, dynamic>)['form'] == 'DOCUMENT')
          .toList();

      Set<String> purchased = {};
      try {
        final prefs    = await SharedPreferences.getInstance();
        final localRaw = prefs.getString('purchased_resource_ids') ?? '[]';
        purchased      = Set<String>.from(jsonDecode(localRaw) as List);
        final pr = await http.get(
          Uri.parse('$kApiBase/payment/my-purchases'), headers: headers);
        if (pr.statusCode == 200) {
          final pd        = jsonDecode(pr.body) as Map<String, dynamic>;
          final serverIds = Set<String>.from(pd['purchased'] as List? ?? []);
          purchased       = {...purchased, ...serverIds};
          await prefs.setString('purchased_resource_ids', jsonEncode(purchased.toList()));
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _books = all.map((e) => _Book.fromJson(e as Map<String, dynamic>, purchased)).toList();
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOfflineMeta() async {
    final meta = await _OfflineService.savedBooks();
    if (mounted) setState(() => _savedMeta = meta);
  }

  Future<void> _logActivity(String action, String title) async {
    try {
      final headers = await authHeaders();
      await http.post(Uri.parse('$kApiBase/activity'), headers: headers,
          body: jsonEncode({'action': action, 'resourceTitle': title}));
    } catch (_) {}
  }

  Future<void> _purchase(_Book book) async {
    setState(() { _purchasing = true; _error = null; });
    String? txRef;
    try {
      final headers = await authHeaders();
      final res = await http.post(
        Uri.parse('$kApiBase/payment/create-checkout-session'),
        headers: headers,
        body: jsonEncode({'resourceId': book.id, 'amount': book.price}),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        Map<String, dynamic> d = {};
        try { d = jsonDecode(res.body) as Map<String, dynamic>; } catch (_) {}
        throw Exception(d['message']?.toString() ?? 'Payment initiation failed (${res.statusCode})');
      }
      final d   = jsonDecode(res.body) as Map<String, dynamic>;
      final url = d['checkoutUrl']?.toString() ?? d['url']?.toString();
      txRef     = d['transactionReference']?.toString();
      if (url == null || url.isEmpty) throw Exception('No checkout URL returned from server');
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        final refreshNeeded = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) =>
              PaymentResultScreen(txRef: txRef ?? '', resourceId: book.id)),
        );
        if (refreshNeeded == true && mounted) await _fetchAll();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _previewOnline(_Book book) async {
    if (book.fileUrl == null || book.fileUrl!.isEmpty) {
      _snack('No file available for "${book.title}"'); return;
    }
    await _logActivity('RESOURCE_VIEWED', book.title);
    try {
      await launchUrl(Uri.parse(book.fileUrl!), mode: LaunchMode.externalApplication);
    } catch (_) { _snack('Could not open file'); }
  }

  List<String> get _subjects {
    final s = _books.map((b) => b.categoryName).whereType<String>().toSet().toList()..sort();
    return ['All Subjects', ...s];
  }

  List<_Book> get _filtered => _books.where((b) {
    final matchType    = _bookType == _BookType.free ? !b.isPaid : b.isPaid;
    final matchSearch  = _search.isEmpty ||
        b.title.toLowerCase().contains(_search.toLowerCase()) ||
        (b.description?.toLowerCase().contains(_search.toLowerCase()) ?? false);
    final matchLevel   = _level   == 'All Levels'   || b.targetClassName == _level;
    final matchSubject = _subject == 'All Subjects'  || b.categoryName   == _subject;
    return matchType && matchSearch && matchLevel && matchSubject;
  }).toList();

  List<_Book> get _paginated {
    final start = (_page - 1) * _perPage;
    return _filtered.skip(start).take(_perPage).toList();
  }

  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 9999);
  void _resetPage() => setState(() => _page = 1);
  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: RefreshIndicator(
        color: t.primary,
        onRefresh: _fetchAll,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: t.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Hero header ──────────────────────────────────────
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
                        child: const Icon(Icons.local_library_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Books Library',
                            style: TextStyle(
                                color: t.text, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Browse, read and save books offline',
                            style: TextStyle(
                                color: t.primary.withValues(alpha: 0.8),
                                fontSize: 13)),
                      ]),
                    ]),
                  ),

                  _buildViewToggle(t),
                  const SizedBox(height: 12),

                  if (_viewMode == _ViewMode.offline)
                    _buildOfflineView(t)
                  else ...[
                    _buildTypeToggle(t),
                    const SizedBox(height: 12),
                    if (_error != null) _ErrorBox(message: _error!, theme: t),
                    _buildSearchBar(t),
                    const SizedBox(height: 10),
                    _buildFilters(t),
                    const SizedBox(height: 14),
                    Text(
                      '${_bookType == _BookType.free ? "Free" : "Premium"} Books • ${_filtered.length} results',
                      style: TextStyle(color: t.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    if (_paginated.isEmpty)
                      _buildEmpty(t)
                    else
                      ...(_paginated.asMap().entries.map((e) => _buildBookCard(e.value, e.key, t))),
                    if (_totalPages > 1) _buildPagination(t),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildEmpty(AppThemeData t) => Container(
        margin: const EdgeInsets.symmetric(vertical: 40),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          Icon(Icons.menu_book_rounded, size: 44, color: t.subtle),
          const SizedBox(height: 14),
          Text('No books found.', style: TextStyle(color: t.subtle, fontSize: 15)),
        ]),
      );

  Widget _buildViewToggle(AppThemeData t) => Row(children: [
        Expanded(child: _ToggleBtn(
          label: '📚 Browse',
          icon: Icons.local_library_outlined,
          selected: _viewMode == _ViewMode.browse,
          theme: t,
          onTap: () => setState(() => _viewMode = _ViewMode.browse),
        )),
        const SizedBox(width: 10),
        Expanded(child: _ToggleBtn(
          label: '📥 Offline (${_savedMeta.length})',
          icon: Icons.download_done_rounded,
          selected: _viewMode == _ViewMode.offline,
          theme: t,
          onTap: () { setState(() => _viewMode = _ViewMode.offline); _loadOfflineMeta(); },
        )),
      ]);

  Widget _buildTypeToggle(AppThemeData t) => Row(children: [
        Expanded(child: _ToggleBtn(
          label: 'Free Books',
          icon: Icons.book_outlined,
          selected: _bookType == _BookType.free,
          theme: t,
          onTap: () => setState(() { _bookType = _BookType.free; _page = 1; }),
        )),
        const SizedBox(width: 10),
        Expanded(child: _ToggleBtn(
          label: 'Premium',
          icon: Icons.star,
          selected: _bookType == _BookType.premium,
          isPremium: true,
          theme: t,
          onTap: () => setState(() { _bookType = _BookType.premium; _page = 1; }),
        )),
      ]);

  Widget _buildSearchBar(AppThemeData t) => TextField(
        controller: _searchCtrl,
        style: TextStyle(color: t.text, fontSize: 15),
        decoration: InputDecoration(
          hintText:  'Search books...',
          hintStyle: TextStyle(color: t.subtle),
          prefixIcon: Icon(Icons.search, color: t.muted),
          filled:    true,
          fillColor: t.inputFill,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border:        OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: t.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: t.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: t.primary)),
        ),
        onChanged: (v) { _search = v; _resetPage(); },
      );

  Widget _buildFilters(AppThemeData t) => Row(children: [
        Expanded(child: _buildDropdown(
          value: _level,
          items: const ['All Levels', 'Form 1', 'Form 2', 'Form 3', 'Form 4'],
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
      ]);

  Widget _buildDropdown({
    required String value, required List<String> items,
    required String label, required ValueChanged<String?> onChanged,
    required AppThemeData theme,
  }) =>
      DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        isExpanded: true,
        dropdownColor: theme.surface,
        style: TextStyle(color: theme.text, fontSize: 14),
        decoration: InputDecoration(
          labelText:  label,
          labelStyle: TextStyle(color: theme.muted, fontSize: 13),
          filled:     true, fillColor: theme.dropdownFill,
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

  Widget _buildBookCard(_Book book, int index, AppThemeData t) {
    final gradient = _bookGradients[index % _bookGradients.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 56, height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_iconFor(book.categoryName), color: Colors.white54, size: 28),
        ),
        const SizedBox(width: 14),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(book.title,
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.w700, fontSize: 16)),

          if (book.description != null)
            Text(book.description!,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.subtle, fontSize: 13)),

          const SizedBox(height: 8),

          Wrap(spacing: 8, runSpacing: 6, children: [
            if (book.categoryName != null)
              _Tag(label: book.categoryName!, color: t.primary, theme: t),
            if (book.targetClassName != null)
              _Tag(label: book.targetClassName!, outlined: true, theme: t),
            _Tag(
              label: book.isPaid ? 'Paid • ${book.formattedPrice}' : 'Free',
              color: book.isPaid ? t.amber : t.primary,
              theme: t,
            ),
            if (book.isPurchased && book.isPaid)
              _Tag(label: '✓ Purchased', color: t.primary, theme: t),
          ]),

          const SizedBox(height: 12),

          if (book.canAccess)
            _BookActions(
              book: book,
              theme: t,
              onPreview: () => _previewOnline(book),
              onOfflineSaved: _loadOfflineMeta,
            )
          else
            _Btn(
              label: _purchasing ? 'Processing...' : '💳 Buy ${book.formattedPrice}',
              color: t.primary,
              onTap: _purchasing ? () {} : () => _purchase(book),
            ),
        ])),
      ]),
    );
  }

  Widget _buildOfflineView(AppThemeData t) {
    if (_savedMeta.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: t.surface, border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          const Text('📥', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          Text('No books saved for offline reading.',
              style: TextStyle(color: t.subtle, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Browse books and tap "Save Offline" to read without internet.',
              style: TextStyle(color: t.subtle, fontSize: 13), textAlign: TextAlign.center),
        ]),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_savedMeta.length} book${_savedMeta.length != 1 ? "s" : ""} saved',
            style: TextStyle(color: t.muted, fontSize: 14)),
        const SizedBox(height: 10),
        ..._savedMeta.map((meta) => _OfflineBookTile(
              meta: meta, theme: t, onRemoved: _loadOfflineMeta)),
      ],
    );
  }

  Widget _buildPagination(AppThemeData t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _PagBtn(icon: Icons.chevron_left, enabled: _page > 1, theme: t,
              onTap: () => setState(() => _page--)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$_page / $_totalPages',
                style: TextStyle(color: t.text, fontSize: 15)),
          ),
          _PagBtn(icon: Icons.chevron_right, enabled: _page < _totalPages, theme: t,
              onTap: () => setState(() => _page++)),
        ]),
      );
}

// ─── Book Actions ─────────────────────────────────────────────────────────────
class _BookActions extends StatefulWidget {
  final _Book        book;
  final AppThemeData theme;
  final VoidCallback onPreview;
  final VoidCallback onOfflineSaved;
  const _BookActions({required this.book, required this.theme, required this.onPreview, required this.onOfflineSaved});
  @override
  State<_BookActions> createState() => _BookActionsState();
}

class _BookActionsState extends State<_BookActions> {
  bool   _saved    = false;
  bool   _saving   = false;
  double _progress = 0;

  @override
  void initState() { super.initState(); _checkSaved(); }

  Future<void> _checkSaved() async {
    final s = await _OfflineService.isSaved(widget.book.id);
    if (mounted) setState(() => _saved = s);
  }

  Future<void> _saveOffline() async {
    if (widget.book.fileUrl == null || widget.book.fileUrl!.isEmpty) {
      _snack('No file available to save.'); return;
    }
    setState(() { _saving = true; _progress = 0; });
    try {
      await _OfflineService.save(
        bookId:  widget.book.id, title: widget.book.title,
        fileUrl: widget.book.fileUrl!,
        onProgress: (p) { if (mounted) setState(() => _progress = p); },
      );
      if (mounted) {
        setState(() { _saved = true; _saving = false; });
        widget.onOfflineSaved();
        _snack('"${widget.book.title}" saved for offline reading.');
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      _snack('Failed to save. Check your connection.');
    }
  }

  Future<void> _openOffline() async {
    final path = await _OfflineService.localPath(widget.book.id);
    if (path == null || !mounted) { _snack('File not found. Please save it again.'); return; }
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => _PdfViewerScreen(localPath: path, title: widget.book.title, theme: widget.theme)));
  }

  Future<void> _removeOffline() async {
    await _OfflineService.remove(widget.book.id);
    if (mounted) {
      setState(() => _saved = false);
      widget.onOfflineSaved();
      _snack('Book removed from offline storage.');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    if (_saving) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: t.primary)),
          const SizedBox(width: 8),
          Text('Saving... ${(_progress * 100).toInt()}%',
              style: TextStyle(color: t.muted, fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: t.border,
            valueColor: AlwaysStoppedAnimation(t.primary),
            minHeight: 6,
          ),
        ),
      ]);
    }
    if (_saved) {
      return Wrap(spacing: 8, runSpacing: 8, children: [
        _Btn(label: '📖 Read',    color: t.primary, onTap: _openOffline),
        _Btn(label: '👁️ Preview', color: t.teal,   onTap: widget.onPreview),
        _IconBtn(icon: Icons.delete_outline, color: t.danger, onTap: _removeOffline),
      ]);
    }
    return Wrap(spacing: 8, runSpacing: 8, children: [
      _Btn(label: '👁️ Preview',    color: t.teal,   onTap: widget.onPreview),
      _Btn(label: '💾 Save Offline', color: t.primary, onTap: _saveOffline),
    ]);
  }
}

// ─── Offline tile ─────────────────────────────────────────────────────────────
class _OfflineBookTile extends StatefulWidget {
  final Map<String, dynamic> meta;
  final AppThemeData          theme;
  final VoidCallback          onRemoved;
  const _OfflineBookTile({required this.meta, required this.theme, required this.onRemoved});
  @override
  State<_OfflineBookTile> createState() => _OfflineBookTileState();
}

class _OfflineBookTileState extends State<_OfflineBookTile> {
  Future<void> _open() async {
    final path = await _OfflineService.localPath(widget.meta['id']);
    if (path == null || !mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) =>
        _PdfViewerScreen(localPath: path, title: widget.meta['title'] ?? 'Book', theme: widget.theme)));
  }

  Future<void> _remove() async {
    await _OfflineService.remove(widget.meta['id']);
    widget.onRemoved();
  }

  String _savedDate() {
    final raw = widget.meta['savedAt'];
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return 'Saved ${dt.day} ${m[dt.month]} ${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface, border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.primary, const Color(0xFF065F46)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Colors.white54, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.meta['title'] ?? 'Book',
                style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 15)),
            if (_savedDate().isNotEmpty)
              Text(_savedDate(), style: TextStyle(color: t.subtle, fontSize: 12)),
          ])),
          const SizedBox(width: 8),
          _Btn(label: '📖 Read', color: t.primary, onTap: _open),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.delete_outline, color: t.danger, onTap: _remove),
        ]),
      );
  }
}

// ─── PDF Viewer ───────────────────────────────────────────────────────────────
class _PdfViewerScreen extends StatefulWidget {
  final String localPath, title;
  final AppThemeData theme;
  const _PdfViewerScreen({required this.localPath, required this.title, required this.theme});
  @override
  State<_PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<_PdfViewerScreen> {
  int  _pages   = 0;
  int  _current = 1;
  bool _ready   = false;
  PDFViewController? _ctrl;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        title: Text(widget.title,
            style: TextStyle(color: t.text, fontSize: 16),
            overflow: TextOverflow.ellipsis),
        backgroundColor: t.surface,
        foregroundColor: t.text,
        elevation: 0,
        actions: [
          if (_ready)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('$_current / $_pages',
                  style: TextStyle(color: t.muted, fontSize: 14))),
            ),
        ],
      ),
      body: Stack(children: [
        PDFView(
          filePath: widget.localPath,
          enableSwipe: true, swipeHorizontal: true,
          autoSpacing: true, pageFling: true, pageSnap: true,
          fitPolicy: FitPolicy.BOTH,
          onRender: (pages) {
            if (mounted) setState(() { _pages = pages ?? 0; _ready = true; });
          },
          onViewCreated: (ctrl) => _ctrl = ctrl,
          onPageChanged: (page, _) {
            if (mounted) setState(() => _current = (page ?? 0) + 1);
          },
          onError: (e) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'))),
        ),
        if (!_ready) Center(child: CircularProgressIndicator(color: t.primary)),
      ]),
      bottomNavigationBar: _ready && _pages > 1
          ? Container(
              height: 56,
              color: t.surface,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: _current == 1 ? t.subtle : t.text,
                  onPressed: _current == 1 ? null : () => _ctrl?.setPage(_current - 2),
                ),
                Text('Page $_current of $_pages',
                    style: TextStyle(color: t.muted, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: _current == _pages ? t.subtle : t.text,
                  onPressed: _current == _pages ? null : () => _ctrl?.setPage(_current),
                ),
              ]),
            )
          : null,
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  final AppThemeData theme;
  const _ErrorBox({required this.message, required this.theme});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.errorBg,
          border: Border.all(color: theme.errorBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(Icons.error_outline_rounded, color: theme.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: TextStyle(color: theme.danger, fontSize: 14))),
        ]),
      );
}

class _ToggleBtn extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final bool       selected;
  final bool       isPremium;
  final AppThemeData theme;
  final VoidCallback onTap;
  const _ToggleBtn({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
    required this.theme, this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isPremium ? theme.amber : theme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.15) : theme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? activeColor : theme.border, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? activeColor : theme.muted, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize:   14,
            color: selected ? activeColor : theme.muted,
          )),
        ]),
      ),
    );
  }
}

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
  final String     label;
  final Color      color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.85)]),
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

class _IconBtn extends StatelessWidget {
  final IconData   icon;
  final Color      color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );
}

class _PagBtn extends StatelessWidget {
  final IconData   icon;
  final bool       enabled;
  final AppThemeData theme;
  final VoidCallback onTap;
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