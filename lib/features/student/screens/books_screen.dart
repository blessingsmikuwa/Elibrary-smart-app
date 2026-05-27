import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

// ─── Offline service ──────────────────────────────────────────────────────────

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

  static Future<bool> isSaved(String bookId) async =>
      (await localPath(bookId)) != null;

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
      list.add({
        'id':      bookId,
        'title':   title,
        'savedAt': DateTime.now().toIso8601String(),
      });
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

// ─── Model ────────────────────────────────────────────────────────────────────

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
    required this.id,
    required this.title,
    this.description,
    this.categoryName,
    this.targetClassName,
    required this.price,
    this.currency,
    required this.isPurchased,
    this.fileUrl,
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
        json['purchased']  == true ||
        json['isPurchased'] == true ||
        json['hasAccess']   == true;

    return _Book(
      id:              json['id']?.toString()          ?? '',
      title:           json['title']?.toString()       ?? 'Untitled',
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
  'Mathematics':  Icons.calculate,
  'Biology':      Icons.biotech,
  'Chemistry':    Icons.science,
  'Physics':      Icons.electric_bolt,
  'English':      Icons.menu_book,
  'History':      Icons.history_edu,
  'Geography':    Icons.public,
};

IconData _iconFor(String? subject) =>
    _subjectIcons[subject ?? ''] ?? Icons.menu_book;

// ─── Colours ──────────────────────────────────────────────────────────────────

const _primary = Color(0xFF2EA043);
const _surface = Color(0xFF161B22);
const _bg      = Color(0xFF0D1117);
const _border  = Color(0xFF21262D);
const _text    = Color(0xFFE6EDF3);
const _muted   = Color(0xFF8B949E);
const _subtle  = Color(0xFF6E7681);
const _blue    = Color(0xFF1F6FEB);
const _danger  = Color(0xFFF85149);

// ─── Tab types ────────────────────────────────────────────────────────────────

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

  // Offline saved books metadata
  List<Map<String, dynamic>> _savedMeta = [];

  static const _perPage = 12;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _loadOfflineMeta();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

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
        final pr = await http.get(
          Uri.parse('$kApiBase/payment/my-purchases'),
          headers: headers,
        );
        if (pr.statusCode == 200) {
          final pd = jsonDecode(pr.body) as Map<String, dynamic>;
          purchased = Set<String>.from(pd['purchased'] as List? ?? []);
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _books = all
            .map((e) => _Book.fromJson(e as Map<String, dynamic>, purchased))
            .toList();
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

  // ── Activity log ───────────────────────────────────────────────────────────

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

  // ── Purchase ───────────────────────────────────────────────────────────────

  Future<void> _purchase(_Book book) async {
    setState(() { _purchasing = true; _error = null; });
    try {
      final headers = await authHeaders();
      final res = await http.post(
        Uri.parse('$kApiBase/payment/create-checkout-session'),
        headers: headers,
        body: jsonEncode({'resourceId': book.id, 'amount': book.price}),
      );
      if (res.statusCode != 200) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        throw Exception(d['message']?.toString() ?? 'Payment failed');
      }
      final d   = jsonDecode(res.body) as Map<String, dynamic>;
      final url = d['checkoutUrl']?.toString() ?? d['url']?.toString();
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No checkout URL returned');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  // ── Preview (online, opens in browser) ────────────────────────────────────

  Future<void> _previewOnline(_Book book) async {
    if (book.fileUrl == null || book.fileUrl!.isEmpty) {
      _snack('No file available for "${book.title}"');
      return;
    }
    await _logActivity('RESOURCE_VIEWED', book.title);
    try {
      await launchUrl(Uri.parse(book.fileUrl!), mode: LaunchMode.externalApplication);
    } catch (_) {
      _snack('Could not open file');
    }
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  List<String> get _subjects {
    final s = _books
        .map((b) => b.categoryName)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _fetchAll,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildViewToggle(),
                  const SizedBox(height: 12),

                  if (_viewMode == _ViewMode.offline)
                    _buildOfflineView()
                  else ...[
                    _buildTypeToggle(),
                    const SizedBox(height: 12),

                    if (_error != null)
                      _ErrorBox(message: _error!),

                    _buildSearchBar(),
                    const SizedBox(height: 10),
                    _buildFilters(),
                    const SizedBox(height: 16),

                    Text(
                      '${_bookType == _BookType.free ? "Free" : "Premium"} Books • ${_filtered.length} results',
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 10),

                    if (_paginated.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('No books found.', style: TextStyle(color: _subtle)),
                        ),
                      )
                    else
                      ...(_paginated.map(_buildBookCard)),

                    if (_totalPages > 1) _buildPagination(),
                  ],
                ],
              ),
      ),
    );
  }

  // ── View toggle (Browse / Offline) ────────────────────────────────────────

  Widget _buildViewToggle() {
    return Row(children: [
      Expanded(child: _TypeBtn(
        label: '📚 Browse',
        icon: Icons.local_library_outlined,
        selected: _viewMode == _ViewMode.browse,
        onTap: () => setState(() => _viewMode = _ViewMode.browse),
      )),
      const SizedBox(width: 10),
      Expanded(child: _TypeBtn(
        label: '📥 Offline (${_savedMeta.length})',
        icon: Icons.download_done_rounded,
        selected: _viewMode == _ViewMode.offline,
        onTap: () {
          setState(() => _viewMode = _ViewMode.offline);
          _loadOfflineMeta();
        },
      )),
    ]);
  }

  // ── Free / Premium toggle ──────────────────────────────────────────────────

  Widget _buildTypeToggle() {
    return Row(children: [
      Expanded(child: _TypeBtn(
        label: 'Free Books',
        icon: Icons.book_outlined,
        selected: _bookType == _BookType.free,
        onTap: () => setState(() { _bookType = _BookType.free; _page = 1; }),
      )),
      const SizedBox(width: 10),
      Expanded(child: _TypeBtn(
        label: 'Premium',
        icon: Icons.star,
        selected: _bookType == _BookType.premium,
        isPremium: true,
        onTap: () => setState(() { _bookType = _BookType.premium; _page = 1; }),
      )),
    ]);
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      style: const TextStyle(color: _text),
      decoration: InputDecoration(
        hintText: 'Search books...',
        hintStyle: const TextStyle(color: _subtle),
        prefixIcon: const Icon(Icons.search, color: _muted),
        filled: true, fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
      ),
      onChanged: (v) { _search = v; _resetPage(); },
    );
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  Widget _buildFilters() {
    return Row(children: [
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
    ]);
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      isExpanded: true,
      dropdownColor: _surface,
      style: const TextStyle(color: _text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted),
        filled: true, fillColor: _surface,
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
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ── Book card ─────────────────────────────────────────────────────────────

  Widget _buildBookCard(_Book book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Thumbnail
        Container(
          width: 52, height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(_iconFor(book.categoryName), color: _text, size: 28),
        ),
        const SizedBox(width: 14),

        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(book.title,
              style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 15)),

          if (book.description != null)
            Text(book.description!,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _subtle, fontSize: 12)),

          const SizedBox(height: 6),

          Wrap(spacing: 8, runSpacing: 6, children: [
            if (book.categoryName != null)
              _Tag(label: book.categoryName!, color: _primary),
            if (book.targetClassName != null)
              _Tag(label: book.targetClassName!, outlined: true),
            _Tag(
              label: book.isPaid ? 'Paid • ${book.formattedPrice}' : 'Free',
              color: book.isPaid ? _blue : _primary,
            ),
            if (book.isPurchased && book.isPaid)
              const _Tag(label: '✓ Purchased', color: Color(0xFF16A34A)),
          ]),

          const SizedBox(height: 10),

          // Actions
          if (book.canAccess)
            _BookActions(
              book: book,
              onPreview: () => _previewOnline(book),
              onOfflineSaved: _loadOfflineMeta,
            )
          else
            _Btn(
              label: _purchasing ? 'Processing...' : '💳 Buy ${book.formattedPrice}',
              color: _blue,
              onTap: _purchasing ? () {} : () => _purchase(book),
            ),
        ])),
      ]),
    );
  }

  // ── Offline view ──────────────────────────────────────────────────────────

  Widget _buildOfflineView() {
    if (_savedMeta.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(children: [
          Text('📥', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('No books saved for offline reading.',
              style: TextStyle(color: _subtle, fontSize: 14),
              textAlign: TextAlign.center),
          SizedBox(height: 6),
          Text('Browse books and tap "Save Offline" to read without internet.',
              style: TextStyle(color: _subtle, fontSize: 12),
              textAlign: TextAlign.center),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_savedMeta.length} book${_savedMeta.length != 1 ? "s" : ""} saved',
            style: const TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(height: 10),
        ..._savedMeta.map((meta) => _OfflineBookTile(
          meta: meta,
          onRemoved: _loadOfflineMeta,
        )),
      ],
    );
  }

  // ── Pagination ────────────────────────────────────────────────────────────

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

// ─── Book Actions widget ──────────────────────────────────────────────────────

class _BookActions extends StatefulWidget {
  final _Book        book;
  final VoidCallback onPreview;
  final VoidCallback onOfflineSaved;

  const _BookActions({
    required this.book,
    required this.onPreview,
    required this.onOfflineSaved,
  });

  @override
  State<_BookActions> createState() => _BookActionsState();
}

class _BookActionsState extends State<_BookActions> {
  bool   _saved    = false;
  bool   _saving   = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final s = await _OfflineService.isSaved(widget.book.id);
    if (mounted) setState(() => _saved = s);
  }

  Future<void> _saveOffline() async {
    if (widget.book.fileUrl == null || widget.book.fileUrl!.isEmpty) {
      _snack('No file available to save.');
      return;
    }
    setState(() { _saving = true; _progress = 0; });
    try {
      await _OfflineService.save(
        bookId:   widget.book.id,
        title:    widget.book.title,
        fileUrl:  widget.book.fileUrl!,
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
    if (path == null || !mounted) {
      _snack('File not found. Please save it again.');
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _PdfViewerScreen(localPath: path, title: widget.book.title),
    ));
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
    // Saving progress
    if (_saving) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          ),
          const SizedBox(width: 8),
          Text(
            'Saving... ${(_progress * 100).toInt()}%',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: const Color(0xFF21262D),
            valueColor: const AlwaysStoppedAnimation(_primary),
            minHeight: 5,
          ),
        ),
      ]);
    }

    // Already saved
    if (_saved) {
      return Row(children: [
        _Btn(label: '📖 Read', color: _primary, onTap: _openOffline),
        const SizedBox(width: 8),
        _Btn(label: '👁️ Preview', color: _blue, onTap: widget.onPreview),
        const SizedBox(width: 8),
        _IconBtn(icon: Icons.delete_outline, color: _danger, onTap: _removeOffline),
      ]);
    }

    // Not saved
    return Row(children: [
      _Btn(label: '👁️ Preview', color: _blue, onTap: widget.onPreview),
      const SizedBox(width: 8),
      _Btn(label: '💾 Save Offline', color: _primary, onTap: _saveOffline),
    ]);
  }
}

// ─── Offline book tile (used in offline view) ─────────────────────────────────

class _OfflineBookTile extends StatefulWidget {
  final Map<String, dynamic> meta;
  final VoidCallback          onRemoved;
  const _OfflineBookTile({required this.meta, required this.onRemoved});
  @override
  State<_OfflineBookTile> createState() => _OfflineBookTileState();
}

class _OfflineBookTileState extends State<_OfflineBookTile> {
  Future<void> _open() async {
    final path = await _OfflineService.localPath(widget.meta['id']);
    if (path == null || !mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _PdfViewerScreen(
        localPath: path,
        title:     widget.meta['title'] ?? 'Book',
      ),
    ));
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
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 52,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.picture_as_pdf, color: _primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.meta['title'] ?? 'Book',
              style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 14)),
          if (_savedDate().isNotEmpty)
            Text(_savedDate(), style: const TextStyle(color: _subtle, fontSize: 11)),
        ])),
        const SizedBox(width: 8),
        _Btn(label: '📖 Read', color: _primary, onTap: _open),
        const SizedBox(width: 6),
        _IconBtn(icon: Icons.delete_outline, color: _danger, onTap: _remove),
      ]),
    );
  }
}

// ─── PDF Viewer screen ────────────────────────────────────────────────────────

class _PdfViewerScreen extends StatefulWidget {
  final String localPath;
  final String title;
  const _PdfViewerScreen({required this.localPath, required this.title});
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
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(color: _text, fontSize: 15),
            overflow: TextOverflow.ellipsis),
        backgroundColor: _bg,
        foregroundColor: _text,
        actions: [
          if (_ready)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text(
                '$_current / $_pages',
                style: const TextStyle(color: _muted, fontSize: 13),
              )),
            ),
        ],
      ),
      body: Stack(children: [
        PDFView(
          filePath: widget.localPath,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
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
        if (!_ready)
          const Center(child: CircularProgressIndicator(color: _primary)),
      ]),
      bottomNavigationBar: _ready && _pages > 1
          ? Container(
              height: 52,
              color: _surface,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: _current == 1 ? _subtle : _text,
                  onPressed: _current == 1
                      ? null
                      : () => _ctrl?.setPage(_current - 2),
                ),
                Text('Page $_current of $_pages',
                    style: const TextStyle(color: _muted, fontSize: 13)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: _current == _pages ? _subtle : _text,
                  onPressed: _current == _pages
                      ? null
                      : () => _ctrl?.setPage(_current),
                ),
              ]),
            )
          : null,
    );
  }
}

// ─── Small shared widgets ─────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF3D1A1A),
      border: Border.all(color: _danger),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(message, style: const TextStyle(color: _danger)),
  );
}

class _TypeBtn extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final bool       selected;
  final bool       isPremium;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isPremium ? Colors.amber : _primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:  selected ? activeColor : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? activeColor : _border, width: 2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? Colors.white : _muted),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : _muted,
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
  const _Tag({required this.label, this.color, this.outlined = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: outlined ? Colors.transparent : color?.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(4),
      border: outlined ? Border.all(color: _border) : null,
    ),
    child: Text(label, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      color: outlined ? _subtle : (color ?? _primary),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(
        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
      )),
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
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}