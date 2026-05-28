import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/services/api_service.dart'; // adjust path

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  bool   _loading    = true;
  String _firstName  = '';
  String _lastName   = '';
  String _email      = '';
  String _schoolName = '';
  String _role       = '';

  // Stats from resources
  int _totalMaterials = 0;

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
      // Fall back to cached user
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('user');
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
      final res = await http.get(
        Uri.parse('$kApiBase/resources'),
        headers: headers,
      );
      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        final list = body is Map ? (body['data'] as List? ?? []) : body as List;
        setState(() => _totalMaterials = list.length);
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Logout?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You will be returned to the login screen.',
          style: TextStyle(color: Color(0xFF8b949e)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout', style: TextStyle(color: Color(0xFFda3633))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Call backend logout
    try {
      final headers = await authHeaders();
      await http.post(Uri.parse('$kApiBase/auth/logout'), headers: headers);
    } catch (_) {}

    // Clear all stored data
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Profile Header ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF30363d)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  radius: 50,
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _role,
                  style: const TextStyle(color: Color(0xFF8b949e), fontSize: 16),
                ),
                if (_schoolName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _schoolName,
                    style: const TextStyle(color: Color(0xFF8b949e), fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Stats ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _statCard(
                '$_totalMaterials', 'Materials', Icons.book, AppColors.primary,
              )),
            ],
          ),
          const SizedBox(height: 24),

          // ── Personal Info ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF30363d)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _infoRow(Icons.email,  'Email',  _email.isNotEmpty  ? _email  : '—'),
                const Divider(color: Color(0xFF30363d), height: 24),
                _infoRow(Icons.school, 'School', _schoolName.isNotEmpty ? _schoolName : '—'),
                const Divider(color: Color(0xFF30363d), height: 24),
                _infoRow(Icons.badge,  'Role',   _role.isNotEmpty   ? _role   : '—'),
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
                backgroundColor: const Color(0xFFda3633),
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

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
            style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8b949e), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
      ),
      body: const TeacherProfilePage(),
    );
  }
}