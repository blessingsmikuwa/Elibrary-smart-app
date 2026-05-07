import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class _Book {
  final String id;
  final String title;
  final String? description;
  final String? categoryName;
  final String? targetClassName;
  final double price;
  final String? currency;
  final bool isPurchased;
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

  bool get isPaid => price > 0;
  bool get canAccess => !isPaid || isPurchased;

  String get formattedPrice {
    if (price <= 0) return 'Free';
    final cur = currency ?? 'MWK';
    return '$cur ${price.toStringAsFixed(2)}';
  }

  factory _Book.fromJson(Map<String, dynamic> json, Set<String> purchasedIds) {
    double price = 0;
    final raw = json['price'] ?? json['amount'] ?? json['cost'];
    if (raw is num) price = raw.toDouble();
    if (raw is String) price = double.tryParse(raw) ?? 0;

    final purchased = purchasedIds.contains(json['id'] as String? ?? '') ||
        json['purchased'] == true ||
        json['isPurchased'] == true ||
        json['hasAccess'] == true;

    return _Book(
      id:              json['id']?.toString() ?? '',
      title:           json['title']?.toString() ?? 'Untitled',
      description:     json['description']?.toString(),
      categoryName:    (json['category'] as Map<String, dynamic>?)?['name']?.toString(),
      targetClassName: (json['targetClass'] as Map<String, dynamic>?)?['name']?.toString(),
      price:           price,
      currency:        json['currency']?.toString(),
      isPurchased:     purchased,
      fileUrl:         json['fileUrl']?.toString(),
    );
  }
}

// ─── Icons by subject ─────────────────────────────────────────────────────────

const _subjectIcons = <String, IconData>{
  'Mathematics': Icons.calculate,
  'Biology':     Icons.biotech,
  'Chemistry':   Icons.science,
  'Physics':     Icons.electric_bolt,
  'English':     Icons.menu_book,
  'History':     Icons.history_edu,
  'Geography':   Icons.public,
};

IconData _iconFor(String? subject) =>
    _subjectIcons[subject ?? ''] ?? Icons.menu_book;

// ─── Screen ───────────────────────────────────────────────────────────────────

enum _BookType { free, premium }

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  static const _primary = Color(0xFF2EA043);
  static const _surface = Color(0xFF161B22);
  static const _bg      = Color(0xFF0D1117);
  static const _border  = Color(0xFF21262D);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);
  static const _subtle  = Color(0xFF6E7681);

  List<_Book> _books        = [];
  bool        _loading      = true;
  String?     _error;
  bool        _purchasing   = false;

  _BookType   _bookType     = _BookType.free;
  String      _search       = '';
  String      _level        = 'All Levels';
  String      _subject      = 'All Subjects';
  int         _page         = 1;
  static const _perPage = 12;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await authHeaders();

      // Fetch resources
      final res = await http.get(
        Uri.parse('$kApiBase/resources'),
        headers: headers,
      );
      if (res.statusCode != 200) throw Exception('Failed to load resources');

      final body = jsonDecode(res.body);
      final rawList = body is Map ? (body['data'] as List?) ?? [] : body as List;

      // Only DOCUMENT type
      final all = (rawList as List<dynamic>)
          .where((e) => (e as Map<String, dynamic>)['form'] == 'DOCUMENT')
          .toList();

      // Fetch purchases
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
      _error = e.toString();
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

  Future<void> _openUrl(String? url, String action, String title) async {
    if (url == null || url.isEmpty) {
      _snack('No file available for "$title"');
      return;
    }
    await _logActivity(action, title);
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      _snack('Could not open file');
    }
  }

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
      final d = jsonDecode(res.body) as Map<String, dynamic>;
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

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Filtering ──────────────────────────────────────────────────────────────

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
                  // Book type toggle
                  _buildTypeToggle(),
                  const SizedBox(height: 12),

                  // Error
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      hintText: 'Search books...',
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
                    onChanged: (v) { _search = v; _resetPage(); },
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
                  const SizedBox(height: 16),

                  // Count
                  Text(
                    '${_bookType == _BookType.free ? "Free" : "Premium"} Books  •  ${_filtered.length} results',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  // Books list
                  if (_paginated.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text('No books found.', style: TextStyle(color: _subtle)),
                      ),
                    )
                  else
                    ...(_paginated.map(_buildBookCard)),

                  // Pagination
                  if (_totalPages > 1) _buildPagination(),
                ],
              ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Row(children: [
      Expanded(child: _TypeBtn(
        label: 'Free Books',
        icon: Icons.book_outlined,
        selected: _bookType == _BookType.free,
        onTap: () { setState(() { _bookType = _BookType.free; _page = 1; }); },
      )),
      const SizedBox(width: 10),
      Expanded(child: _TypeBtn(
        label: 'Premium',
        icon: Icons.star,
        selected: _bookType == _BookType.premium,
        isPremium: true,
        onTap: () { setState(() { _bookType = _BookType.premium; _page = 1; }); },
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

  Widget _buildBookCard(_Book book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        // Icon
        Container(
          width: 52, height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(_iconFor(book.categoryName), color: _text, size: 28),
        ),
        const SizedBox(width: 14),

        // Info
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title, style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 15)),
            if (book.description != null)
              Text(
                book.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _subtle, fontSize: 12),
              ),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              if (book.categoryName != null)
                _Tag(label: book.categoryName!, color: _primary),
              if (book.targetClassName != null)
                _Tag(label: book.targetClassName!, outlined: true),
              _Tag(
                label: book.isPaid ? 'Paid • ${book.formattedPrice}' : 'Free',
                color: book.isPaid ? const Color(0xFF2563EB) : _primary,
              ),
              if (book.isPurchased && book.isPaid)
                const _Tag(label: '✓ Purchased', color: Color(0xFF16A34A)),
            ]),
          ],
        )),

        const SizedBox(width: 10),

        // Actions
        Column(mainAxisSize: MainAxisSize.min, children: [
          if (book.canAccess) ...[
            _ActionBtn(
              label: '📖',
              color: _primary,
              onTap: () => _openUrl(book.fileUrl, 'RESOURCE_VIEWED', book.title),
            ),
            const SizedBox(height: 6),
            _ActionBtn(
              label: '⬇️',
              color: const Color(0xFF1F6FEB),
              onTap: () => _openUrl(book.fileUrl, 'DOWNLOAD', book.title),
            ),
          ] else
            _ActionBtn(
              label: _purchasing ? '...' : 'Buy',
              color: const Color(0xFF2563EB),
              onTap: _purchasing ? null : () => _purchase(book),
              wide: true,
            ),
        ]),
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

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isPremium;
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
    final activeColor = isPremium ? Colors.amber : const Color(0xFF2EA043);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFF21262D),
            width: 2,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: selected ? Colors.white : const Color(0xFF8B949E)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : const Color(0xFF8B949E),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final bool outlined;

  const _Tag({required this.label, this.color, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color?.withValues(alpha: 0.15),
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

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool wide;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: wide ? 68 : 40,
        height: 36,
        decoration: BoxDecoration(
          color: onTap == null ? color.withValues(alpha: 0.4) : color,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}