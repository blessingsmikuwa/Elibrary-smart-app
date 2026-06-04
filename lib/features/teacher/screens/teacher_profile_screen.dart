import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_manager.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/services/api_service.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  bool   _loading       = true;
  String _firstName     = '';
  String _lastName      = '';
  String _email         = '';
  String _schoolName    = '';
  String _role          = '';
  int    _totalMaterials = 0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchStats();
  }

  Future<void> _fetchProfile() async {
    try {
      final headers = await authHeaders();
      final res = await http.get(
        Uri.parse('$kApiBase/profiles/me'),
        headers: headers,
      );
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _firstName  = data['firstName']?.toString() ?? '';
          _lastName   = data['lastName']?.toString()  ?? '';
          _email      = data['email']?.toString()     ?? '';
          _schoolName = (data['school'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
          _role       = data['role']?.toString() ?? 'TEACHER';
        });
      }
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw   = prefs.getString('user');
        if (raw != null && mounted) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          setState(() {
            _firstName = data['firstName']?.toString() ?? '';
            _lastName  = data['lastName']?.toString()  ?? '';
            _email     = data['email']?.toString()     ?? '';
          });
        }
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchStats() async {
    try {
      final headers = await authHeaders();
      final res = await http.get(Uri.parse('$kApiBase/resources'), headers: headers);
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        final list = body is Map ? (body['data'] as List? ?? []) : body as List;
        setState(() => _totalMaterials = list.length);
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    final t = AppTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout?', style: TextStyle(color: t.text)),
        content: Text(
          'You will be returned to the login screen.',
          style: TextStyle(color: t.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: t.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Logout', style: TextStyle(color: t.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final headers = await authHeaders();
      await http.post(Uri.parse('$kApiBase/auth/logout'), headers: headers);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String get _displayName => '$_firstName $_lastName'.trim().isEmpty
      ? 'Teacher'
      : '$_firstName $_lastName'.trim();

  String get _initials {
    final f = _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '';
    final l = _lastName.isNotEmpty  ? _lastName[0].toUpperCase()  : '';
    return '$f$l'.isEmpty ? 'T' : '$f$l';
  }

  @override
  Widget build(BuildContext context) {
    final t  = AppTheme.of(context);
    final tm = context.watch<ThemeManager>();

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: t.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Profile Header ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: t.primary.withValues(alpha: 0.15),
                  radius: 50,
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: t.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _displayName,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_role, style: TextStyle(color: t.muted, fontSize: 16)),
                if (_schoolName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_schoolName, style: TextStyle(color: t.muted, fontSize: 14)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _statCard(t, '$_totalMaterials', 'Materials', Icons.book, t.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Theme Toggle ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: t.blueBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    tm.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: t.blueText,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                          color: t.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tm.isDarkMode ? 'Using dark theme' : 'Using light theme',
                        style: TextStyle(color: t.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: tm.isDarkMode,
                  activeColor: t.primary,
                  onChanged: (val) => tm.setDarkMode(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Personal Information ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal Information',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow(t, Icons.email,  'Email',  _email.isNotEmpty      ? _email      : '—'),
                Divider(color: t.border, height: 24),
                _infoRow(t, Icons.school, 'School', _schoolName.isNotEmpty ? _schoolName : '—'),
                Divider(color: t.border, height: 24),
                _infoRow(t, Icons.badge,  'Role',   _role.isNotEmpty       ? _role       : '—'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Logout ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.danger,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(AppThemeData t, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: t.muted, fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _infoRow(AppThemeData t, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: t.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: t.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: t.muted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: t.text, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: t.surface,
        foregroundColor: t.text,
        elevation: 0,
      ),
      body: const TeacherProfilePage(),
    );
  }
}