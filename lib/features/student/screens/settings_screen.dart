import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/api_service.dart';
import '../../auth/screens/login_screen.dart'; 

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _bg      = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);
  static const _primary = Color(0xFF2EA043);
  static const _danger  = Color(0xFFF85149);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);
  static const _subtle  = Color(0xFF6E7681);

  bool   _profileLoading = true;
  String _firstName  = '';
  String _lastName   = '';
  String _email      = '';
  String _schoolName = '';
  String _classLevel = 'Form 4';

  bool _darkMode           = true;
  bool _largeText          = false;
  bool _downloadMobileData = false;
  bool _activityHistory    = true;
  bool _newResourceAlerts  = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _profileLoading = true);
    try {
      final headers = await authHeaders();
      final res = await http.get(Uri.parse('$kApiBase/profiles/me'), headers: headers);
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _firstName  = data['firstName']?.toString() ?? '';
          _lastName   = data['lastName']?.toString()  ?? '';
          _email      = data['email']?.toString()     ?? '';
          _schoolName = (data['school'] as Map<String, dynamic>?)?['name']?.toString() ?? '';
          final cl = data['classLevel']?.toString() ?? data['form']?.toString();
          if (cl != null && cl.isNotEmpty) _classLevel = cl;
        });
      }
    } catch (_) {
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
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Logout?', style: TextStyle(color: _text)),
        content: const Text('You will be returned to the login screen.', style: TextStyle(color: _muted)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout', style: TextStyle(color: _danger)),
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

  // ── Edit Profile ──────────────────────────────────────────────────────────
  Future<void> _editProfile() async {
    final firstCtrl = TextEditingController(text: _firstName);
    final lastCtrl  = TextEditingController(text: _lastName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Edit Profile', style: TextStyle(color: _text)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(firstCtrl, 'First Name'),
          const SizedBox(height: 12),
          _dialogField(lastCtrl, 'Last Name'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save', style: TextStyle(color: _primary)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final headers = await authHeaders();
      final res = await http.patch(
        Uri.parse('$kApiBase/profiles/me'),
        headers: headers,
        body: jsonEncode({'firstName': firstCtrl.text.trim(), 'lastName': lastCtrl.text.trim()}),
      );
      if (res.statusCode < 300 && mounted) {
        setState(() {
          _firstName = firstCtrl.text.trim();
          _lastName  = lastCtrl.text.trim();
        });
        _snack('Profile updated.');
      } else {
        _snack('Failed to update profile.');
      }
    } catch (_) {
      _snack('Network error.');
    }
  }

  // ── Change Password ───────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Change Password', style: TextStyle(color: _text)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(currentCtrl, 'Current Password', obscure: true),
          const SizedBox(height: 12),
          _dialogField(newCtrl, 'New Password', obscure: true),
          const SizedBox(height: 12),
          _dialogField(confirmCtrl, 'Confirm New Password', obscure: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Update', style: TextStyle(color: _primary)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (newCtrl.text != confirmCtrl.text) { _snack('Passwords do not match.'); return; }
    if (newCtrl.text.length < 6)          { _snack('Password must be at least 6 characters.'); return; }
    try {
      final headers = await authHeaders();
      final res = await http.post(
        Uri.parse('$kApiBase/auth/change-password'),
        headers: headers,
        body: jsonEncode({'currentPassword': currentCtrl.text, 'newPassword': newCtrl.text}),
      );
      if (res.statusCode < 300) {
        _snack('Password changed successfully.');
      } else {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        _snack(d['message']?.toString() ?? 'Failed to change password.');
      }
    } catch (_) {
      _snack('Network error.');
    }
  }

  // ── Contact Support ───────────────────────────────────────────────────────
  Future<void> _contactSupport() async {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Contact Support', style: TextStyle(color: _text)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(subjectCtrl, 'Subject'),
          const SizedBox(height: 12),
          _dialogField(messageCtrl, 'Message', maxLines: 4),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send', style: TextStyle(color: _primary)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (subjectCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
      _snack('Please fill in all fields.');
      return;
    }
    try {
      final headers = await authHeaders();
      final res = await http.post(
        Uri.parse('$kApiBase/support/message'),
        headers: headers,
        body: jsonEncode({'subject': subjectCtrl.text.trim(), 'message': messageCtrl.text.trim()}),
      );
      if (res.statusCode < 300) {
        _snack('Message sent! We will get back to you soon.');
      } else {
        _snack('Failed to send message.');
      }
    } catch (_) {
      _snack('Network error.');
    }
  }

  // ── Report Problem ────────────────────────────────────────────────────────
  Future<void> _reportProblem() async {
    final descCtrl = TextEditingController();
    String category = 'General';
    final categories = ['General', 'Bug', 'Content', 'Payment', 'Account', 'Other'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: _surface,
          title: const Text('Report a Problem', style: TextStyle(color: _text)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: category,
              dropdownColor: _surface,
              style: const TextStyle(color: _text),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: const TextStyle(color: _muted),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: _border),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setS(() => category = v ?? 'General'),
            ),
            const SizedBox(height: 12),
            _dialogField(descCtrl, 'Describe the problem...', maxLines: 4),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Submit', style: TextStyle(color: _primary)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    if (descCtrl.text.trim().isEmpty) { _snack('Please describe the problem.'); return; }
    try {
      final headers = await authHeaders();
      final res = await http.post(
        Uri.parse('$kApiBase/support/report'),
        headers: headers,
        body: jsonEncode({'description': descCtrl.text.trim(), 'category': category}),
      );
      if (res.statusCode < 300) {
        _snack('Problem reported. Thank you for the feedback!');
      } else {
        _snack('Failed to submit report.');
      }
    } catch (_) {
      _snack('Network error.');
    }
  }

  // ── Clear Activity ────────────────────────────────────────────────────────
  Future<void> _clearActivity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Clear Activity?', style: TextStyle(color: _text)),
        content: const Text('This will remove all local activity records.', style: TextStyle(color: _muted)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear', style: TextStyle(color: _danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activity');
    _snack('Activity history cleared.');
  }

  // ── Save Class Level ──────────────────────────────────────────────────────
  Future<void> _saveClassLevel(String level) async {
    setState(() => _classLevel = level);
    try {
      final headers = await authHeaders();
      await http.patch(
        Uri.parse('$kApiBase/profiles/me'),
        headers: headers,
        body: jsonEncode({'classLevel': level}),
      );
    } catch (_) {}
  }

  // ── FAQ ───────────────────────────────────────────────────────────────────
  void _showFaq() {
    const faqs = [
      ('How do I download a book?',       'Go to the Books section, find a free book, and tap "Save Offline". The book will be available without internet.'),
      ('How do I take a quiz?',            'Go to the Quizzes section. Choose AI Quiz to generate one instantly, or pick a Teacher quiz from your class.'),
      ('Why can\'t I access a paid book?', 'Paid books require purchase. Tap "Buy" on the book and complete checkout to unlock access.'),
      ('How do I reset my password?',      'Go to Settings → Change Password. You\'ll need your current password to set a new one.'),
      ('How do I contact a teacher?',      'Use Settings → Contact Support to send a message to the admin team.'),
      ('What subjects are covered?',       'Biology, Mathematics, Chemistry, Physics, English, Geography, History, Civic Education, and Computer Studies.'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Frequently Asked Questions',
                style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ...faqs.map((faq) => _FaqTile(question: faq.$1, answer: faq.$2)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _dialogField(TextEditingController ctrl, String hint, {bool obscure = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: maxLines,
      style: const TextStyle(color: _text),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: _muted),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _border),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _primary),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String get _displayName {
    final n = '$_firstName $_lastName'.trim();
    return n.isEmpty ? 'Student' : n;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: _bg,
        foregroundColor: _text,
        elevation: 0,
      ),
      body: _profileLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(title: 'Profile', icon: Icons.person_rounded, children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _primary,
                        child: Text(
                          _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '👤',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_displayName,
                            style: const TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 17)),
                        if (_schoolName.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(_schoolName, style: const TextStyle(color: _muted, fontSize: 13)),
                        ],
                        if (_email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(_email, style: const TextStyle(color: _subtle, fontSize: 12)),
                        ],
                      ])),
                    ]),
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge_rounded, color: _text),
                    title: const Text('Class level', style: TextStyle(color: _text, fontWeight: FontWeight.w700)),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _classLevel,
                        dropdownColor: _surface,
                        style: const TextStyle(color: _text),
                        iconEnabledColor: _muted,
                        items: const ['Form 1', 'Form 2', 'Form 3', 'Form 4']
                            .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                            .toList(),
                        onChanged: (v) { if (v != null) _saveClassLevel(v); },
                      ),
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit profile',
                    subtitle: 'Update your personal details',
                    onTap: _editProfile,
                  ),
                ]),

                _Section(title: 'Account', icon: Icons.manage_accounts_rounded, children: [
                  _ActionTile(
                    icon: Icons.lock_reset_rounded,
                    title: 'Change password',
                    subtitle: 'Keep your account secure',
                    onTap: _changePassword,
                  ),
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    subtitle: 'Sign out of this account',
                    color: _danger,
                    onTap: _logout,
                  ),
                ]),

                _Section(title: 'Appearance', icon: Icons.palette_rounded, children: [
                  _SwitchTile(
                    icon: Icons.dark_mode_rounded,
                    title: 'Dark mode',
                    subtitle: 'Use the dark e-library theme',
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                  _SwitchTile(
                    icon: Icons.format_size_rounded,
                    title: 'Large reading text',
                    subtitle: 'Make book text easier to read',
                    value: _largeText,
                    onChanged: (v) => setState(() => _largeText = v),
                  ),
                  _SwitchTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'New resource alerts',
                    subtitle: 'Notify when new books or papers are added',
                    value: _newResourceAlerts,
                    onChanged: (v) => setState(() => _newResourceAlerts = v),
                  ),
                ]),

                _Section(title: 'Privacy & Security', icon: Icons.shield_rounded, children: [
                  _SwitchTile(
                    icon: Icons.history_rounded,
                    title: 'Save activity history',
                    subtitle: 'Keep recent downloads and quiz activity',
                    value: _activityHistory,
                    onChanged: (v) => setState(() => _activityHistory = v),
                  ),
                  _SwitchTile(
                    icon: Icons.cloud_download_rounded,
                    title: 'Downloads on mobile data',
                    subtitle: 'Allow saving books without Wi-Fi',
                    value: _downloadMobileData,
                    onChanged: (v) => setState(() => _downloadMobileData = v),
                  ),
                  _ActionTile(
                    icon: Icons.delete_sweep_rounded,
                    title: 'Clear activity history',
                    subtitle: 'Remove local activity records',
                    color: _danger,
                    onTap: _clearActivity,
                  ),
                ]),

                _Section(title: 'Help & Support', icon: Icons.help_rounded, children: [
                  _ActionTile(
                    icon: Icons.question_answer_rounded,
                    title: 'FAQ',
                    subtitle: 'Answers about books, papers, and quizzes',
                    onTap: _showFaq,
                  ),
                  _ActionTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Contact support',
                    subtitle: 'Send a message to the admin team',
                    onTap: _contactSupport,
                  ),
                  _ActionTile(
                    icon: Icons.report_problem_rounded,
                    title: 'Report a problem',
                    subtitle: 'Tell us when something is broken',
                    onTap: _reportProblem,
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_rounded, color: _text),
                    title: const Text('About app', style: TextStyle(color: _text, fontWeight: FontWeight.w700)),
                    subtitle: const Text('EduLib Malawi v1.0.0', style: TextStyle(color: _subtle)),
                  ),
                ]),
              ],
            ),
    );
  }
}

// ─── FAQ Tile ─────────────────────────────────────────────────────────────────

class _FaqTile extends StatefulWidget {
  final String question, answer;
  const _FaqTile({required this.question, required this.answer});
  @override State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);
  static const _primary = Color(0xFF2EA043);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _open ? _primary : _border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [
        ListTile(
          title: Text(widget.question,
              style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 14)),
          trailing: Icon(_open ? Icons.expand_less : Icons.expand_more, color: _muted),
          onTap: () => setState(() => _open = !_open),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(widget.answer,
                style: const TextStyle(color: _muted, fontSize: 13, height: 1.5)),
          ),
      ]),
    );
  }
}

// ─── Section ──────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title; final IconData icon; final List<Widget> children;
  const _Section({required this.title, required this.icon, required this.children});
  static const _text    = Color(0xFFE6EDF3);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: _text, size: 21),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(children: children),
      ),
    ]),
  );
}

// ─── Tiles ────────────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  final VoidCallback onTap; final Color? color;
  const _ActionTile({required this.icon, required this.title,
      required this.subtitle, required this.onTap, this.color});
  static const _text   = Color(0xFFE6EDF3);
  static const _subtle = Color(0xFF6E7681);

  @override
  Widget build(BuildContext context) {
    final c = color ?? _text;
    return ListTile(
      leading: Icon(icon, color: c),
      title:    Text(title,    style: TextStyle(color: c, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(color: _subtle)),
      trailing: const Icon(Icons.chevron_right_rounded, color: _subtle),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  final bool value; final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.icon, required this.title,
      required this.subtitle, required this.value, required this.onChanged});
  static const _text    = Color(0xFFE6EDF3);
  static const _subtle  = Color(0xFF6E7681);
  static const _primary = Color(0xFF2EA043);

  @override
  Widget build(BuildContext context) => SwitchListTile(
    secondary: Icon(icon, color: _text),
    title:     Text(title,    style: const TextStyle(color: _text, fontWeight: FontWeight.w700)),
    subtitle:  Text(subtitle, style: const TextStyle(color: _subtle)),
    value: value,
    activeThumbColor: _primary,
    onChanged: onChanged,
  );
}