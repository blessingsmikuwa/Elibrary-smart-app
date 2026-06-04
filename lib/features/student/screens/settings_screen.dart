import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/api_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool   _profileLoading   = true;
  String _firstName  = '';
  String _lastName   = '';
  String _email      = '';
  String _schoolName = '';
  String _classLevel = 'Form 4';

  bool _largeText          = false;
  bool _downloadMobileData = false;
  bool _activityHistory    = true;
  bool _newResourceAlerts  = true;

  @override
  void initState() { super.initState(); _fetchProfile(); }

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
          final cl    = data['classLevel']?.toString() ?? data['form']?.toString();
          if (cl != null && cl.isNotEmpty) _classLevel = cl;
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
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  Future<void> _logout() async {
    final t = AppTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout?', style: TextStyle(color: t.text, fontSize: 18)),
        content: Text('You will be returned to the login screen.',
            style: TextStyle(color: t.muted, fontSize: 15)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: t.muted))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Logout', style: TextStyle(color: t.danger))),
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
      MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  Future<void> _editProfile() async {
    final t = AppTheme.of(context);
    final firstCtrl = TextEditingController(text: _firstName);
    final lastCtrl  = TextEditingController(text: _lastName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Profile', style: TextStyle(color: t.text, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(firstCtrl, 'First Name', t),
          const SizedBox(height: 12),
          _dialogField(lastCtrl, 'Last Name', t),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: t.muted))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Save', style: TextStyle(color: t.primary))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final headers = await authHeaders();
      final res = await http.patch(Uri.parse('$kApiBase/profiles/me'), headers: headers,
          body: jsonEncode({'firstName': firstCtrl.text.trim(), 'lastName': lastCtrl.text.trim()}));
      if (res.statusCode < 300 && mounted) {
        setState(() { _firstName = firstCtrl.text.trim(); _lastName = lastCtrl.text.trim(); });
        _snack('Profile updated.');
      } else { _snack('Failed to update profile.'); }
    } catch (_) { _snack('Network error.'); }
  }

  Future<void> _changePassword() async {
    final t = AppTheme.of(context);
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Password', style: TextStyle(color: t.text, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(currentCtrl, 'Current Password', t, obscure: true),
          const SizedBox(height: 12),
          _dialogField(newCtrl, 'New Password', t, obscure: true),
          const SizedBox(height: 12),
          _dialogField(confirmCtrl, 'Confirm New Password', t, obscure: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: t.muted))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Update', style: TextStyle(color: t.primary))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (newCtrl.text != confirmCtrl.text) { _snack('Passwords do not match.'); return; }
    if (newCtrl.text.length < 6)          { _snack('Password must be at least 6 characters.'); return; }
    try {
      final headers = await authHeaders();
      final res = await http.post(Uri.parse('$kApiBase/auth/change-password'), headers: headers,
          body: jsonEncode({'currentPassword': currentCtrl.text, 'newPassword': newCtrl.text}));
      if (res.statusCode < 300) { _snack('Password changed successfully.'); }
      else {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        _snack(d['message']?.toString() ?? 'Failed to change password.');
      }
    } catch (_) { _snack('Network error.'); }
  }

  Future<void> _contactSupport() async {
    final t = AppTheme.of(context);
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Contact Support', style: TextStyle(color: t.text, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogField(subjectCtrl, 'Subject', t),
          const SizedBox(height: 12),
          _dialogField(messageCtrl, 'Message', t, maxLines: 4),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: t.muted))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Send', style: TextStyle(color: t.primary))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (subjectCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
      _snack('Please fill in all fields.'); return;
    }
    try {
      final headers = await authHeaders();
      final res = await http.post(Uri.parse('$kApiBase/support/message'), headers: headers,
          body: jsonEncode({'subject': subjectCtrl.text.trim(), 'message': messageCtrl.text.trim()}));
      if (res.statusCode < 300) { _snack('Message sent! We will get back to you soon.'); }
      else { _snack('Failed to send message.'); }
    } catch (_) { _snack('Network error.'); }
  }

  Future<void> _reportProblem() async {
    final t = AppTheme.of(context);
    final descCtrl = TextEditingController();
    String category = 'General';
    final categories = ['General', 'Bug', 'Content', 'Payment', 'Account', 'Other'];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: t.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Report a Problem', style: TextStyle(color: t.text, fontSize: 18)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: category,
              dropdownColor: t.surface,
              style: TextStyle(color: t.text, fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: t.muted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: t.border),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setS(() => category = v ?? 'General'),
            ),
            const SizedBox(height: 12),
            _dialogField(descCtrl, 'Describe the problem...', t, maxLines: 4),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancel', style: TextStyle(color: t.muted))),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Submit', style: TextStyle(color: t.primary))),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    if (descCtrl.text.trim().isEmpty) { _snack('Please describe the problem.'); return; }
    try {
      final headers = await authHeaders();
      final res = await http.post(Uri.parse('$kApiBase/support/report'), headers: headers,
          body: jsonEncode({'description': descCtrl.text.trim(), 'category': category}));
      if (res.statusCode < 300) { _snack('Problem reported. Thank you for the feedback!'); }
      else { _snack('Failed to submit report.'); }
    } catch (_) { _snack('Network error.'); }
  }

  Future<void> _clearActivity() async {
    final t = AppTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear Activity?', style: TextStyle(color: t.text, fontSize: 18)),
        content: Text('This will remove all local activity records.',
            style: TextStyle(color: t.muted, fontSize: 15)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel', style: TextStyle(color: t.muted))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Clear', style: TextStyle(color: t.danger))),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activity');
    _snack('Activity history cleared.');
  }

  Future<void> _saveClassLevel(String level) async {
    setState(() => _classLevel = level);
    try {
      final headers = await authHeaders();
      await http.patch(Uri.parse('$kApiBase/profiles/me'), headers: headers,
          body: jsonEncode({'classLevel': level}));
    } catch (_) {}
  }

  void _showFaq() {
    final t = AppTheme.of(context);
    const faqs = [
      ('How do I download a book?',
          'Go to the Books section, find a free book, and tap "Save Offline". The book will be available without internet.'),
      ('How do I take a quiz?',
          'Go to the Quizzes section. Choose AI Quiz to generate one instantly, or pick a Teacher quiz from your class.'),
      ("Why can't I access a paid book?",
          'Paid books require purchase. Tap "Buy" on the book and complete checkout to unlock access.'),
      ('How do I reset my password?',
          "Go to Settings → Change Password. You'll need your current password to set a new one."),
      ('How do I contact a teacher?',
          'Use Settings → Contact Support to send a message to the admin team.'),
      ('What subjects are covered?',
          'Biology, Mathematics, Chemistry, Physics, English, Geography, History, Civic Education, and Computer Studies.'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: t.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75, minChildSize: 0.4, maxChildSize: 0.95, expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: t.border, borderRadius: BorderRadius.circular(2)),
            )),
            Text('Frequently Asked Questions',
                style: TextStyle(color: t.text, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ...faqs.map((faq) => _FaqTile(question: faq.$1, answer: faq.$2, theme: t)),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, AppThemeData t,
      {bool obscure = false, int maxLines = 1}) =>
      TextField(
        controller: ctrl, obscureText: obscure, maxLines: maxLines,
        style: TextStyle(color: t.text, fontSize: 15),
        decoration: InputDecoration(
          labelText: hint, labelStyle: TextStyle(color: t.muted),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: t.border),
              borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: t.primary),
              borderRadius: BorderRadius.circular(12)),
        ),
      );

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String get _displayName {
    final n = '$_firstName $_lastName'.trim();
    return n.isEmpty ? 'Student' : n;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: _profileLoading
            ? Center(child: CircularProgressIndicator(color: t.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // ── Page header ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        t.primary.withValues(alpha: 0.2),
                        const Color(0xFF0D9488).withValues(alpha: 0.2),
                      ]),
                      border: Border.all(color: t.primary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [t.primary, const Color(0xFF0D9488)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.settings_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Settings',
                            style: TextStyle(
                                color: t.text, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Manage your account and preferences',
                            style: TextStyle(
                                color: t.primary.withValues(alpha: 0.8),
                                fontSize: 13)),
                      ]),
                    ]),
                  ),

                  // ── Profile section ──────────────────────────────────
                  _Section(title: 'Profile', icon: Icons.person_rounded, theme: t, children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [t.primary, const Color(0xFF059669)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(child: Text(
                            _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '👤',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          )),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_displayName,
                              style: TextStyle(
                                  color: t.text, fontWeight: FontWeight.w800, fontSize: 18)),
                          if (_schoolName.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(_schoolName, style: TextStyle(color: t.muted, fontSize: 14)),
                          ],
                          if (_email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(_email, style: TextStyle(color: t.subtle, fontSize: 13)),
                          ],
                        ])),
                      ]),
                    ),
                    Divider(color: t.border, height: 1),
                    ListTile(
                      leading: Icon(Icons.badge_rounded, color: t.text),
                      title: Text('Class level',
                          style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 15)),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _classLevel,
                          dropdownColor: t.surface,
                          style: TextStyle(color: t.text, fontSize: 14),
                          iconEnabledColor: t.muted,
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
                      theme: t,
                      onTap: _editProfile,
                    ),
                  ]),

                  _Section(title: 'Account', icon: Icons.manage_accounts_rounded, theme: t, children: [
                    _ActionTile(
                      icon: Icons.lock_reset_rounded,
                      title: 'Change password',
                      subtitle: 'Keep your account secure',
                      theme: t,
                      onTap: _changePassword,
                    ),
                    _ActionTile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out of this account',
                      color: t.danger,
                      theme: t,
                      onTap: _logout,
                    ),
                  ]),

                  _Section(title: 'Appearance', icon: Icons.palette_rounded, theme: t, children: [
                    _SwitchTile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark mode',
                      subtitle: 'Use the dark e-library theme',
                      value: AppTheme.isDark(context),
                      theme: t,
                      onChanged: (v) async {
                        await AppThemeController.of(context).setDark(v);
                      },
                    ),
                    _SwitchTile(
                      icon: Icons.format_size_rounded,
                      title: 'Large reading text',
                      subtitle: 'Make book text easier to read',
                      value: _largeText,
                      theme: t,
                      onChanged: (v) => setState(() => _largeText = v),
                    ),
                  ]),

                  _Section(title: 'Notifications', icon: Icons.notifications_rounded, theme: t, children: [
                    _SwitchTile(
                      icon: Icons.notifications_active_rounded,
                      title: 'New resource alerts',
                      subtitle: 'Notify when new books or papers are added',
                      value: _newResourceAlerts,
                      theme: t,
                      onChanged: (v) => setState(() => _newResourceAlerts = v),
                    ),
                  ]),

                  _Section(title: 'Privacy & Security', icon: Icons.shield_rounded, theme: t, children: [
                    _SwitchTile(
                      icon: Icons.history_rounded,
                      title: 'Save activity history',
                      subtitle: 'Keep recent downloads and quiz activity',
                      value: _activityHistory,
                      theme: t,
                      onChanged: (v) => setState(() => _activityHistory = v),
                    ),
                    _SwitchTile(
                      icon: Icons.cloud_download_rounded,
                      title: 'Downloads on mobile data',
                      subtitle: 'Allow saving books without Wi-Fi',
                      value: _downloadMobileData,
                      theme: t,
                      onChanged: (v) => setState(() => _downloadMobileData = v),
                    ),
                    _ActionTile(
                      icon: Icons.delete_sweep_rounded,
                      title: 'Clear activity history',
                      subtitle: 'Remove local activity records',
                      color: t.danger,
                      theme: t,
                      onTap: _clearActivity,
                    ),
                  ]),

                  _Section(title: 'Help & Support', icon: Icons.help_rounded, theme: t, children: [
                    _ActionTile(
                      icon: Icons.question_answer_rounded,
                      title: 'FAQ',
                      subtitle: 'Answers about books, papers, and quizzes',
                      theme: t,
                      onTap: _showFaq,
                    ),
                    _ActionTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Contact support',
                      subtitle: 'Send a message to the admin team',
                      theme: t,
                      onTap: _contactSupport,
                    ),
                    _ActionTile(
                      icon: Icons.report_problem_rounded,
                      title: 'Report a problem',
                      subtitle: 'Tell us when something is broken',
                      theme: t,
                      onTap: _reportProblem,
                    ),
                    ListTile(
                      leading: Icon(Icons.info_rounded, color: t.text),
                      title: Text('About app',
                          style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 15)),
                      subtitle: Text('EduLib Malawi v1.0.0',
                          style: TextStyle(color: t.subtle, fontSize: 13)),
                    ),
                  ]),
                ],
              ),
      ),
    );
  }
}

// ─── Section ──────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title; final IconData icon; final List<Widget> children;
  final AppThemeData theme;
  const _Section({required this.title, required this.icon, required this.children, required this.theme});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: theme.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(color: theme.text, fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.surface, border: Border.all(color: theme.border),
              borderRadius: BorderRadius.circular(16),
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
  final AppThemeData theme;
  const _ActionTile({required this.icon, required this.title,
      required this.subtitle, required this.onTap, required this.theme, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? theme.text;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 18),
      ),
      title:    Text(title,    style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: theme.subtle, fontSize: 13)),
      trailing: Icon(Icons.chevron_right_rounded, color: theme.subtle),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  final bool value; final ValueChanged<bool> onChanged;
  final AppThemeData theme;
  const _SwitchTile({required this.icon, required this.title,
      required this.subtitle, required this.value, required this.onChanged, required this.theme});

  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: theme.text, size: 18),
        ),
        title:    Text(title,    style: TextStyle(color: theme.text, fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: theme.subtle, fontSize: 13)),
        value:    value,
        activeColor: theme.primary,
        onChanged: onChanged,
      );
}

// ─── FAQ Tile ─────────────────────────────────────────────────────────────────
class _FaqTile extends StatefulWidget {
  final String question, answer;
  final AppThemeData theme;
  const _FaqTile({required this.question, required this.answer, required this.theme});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: widget.theme.surface,
          border: Border.all(color: _open ? widget.theme.primary : widget.theme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          ListTile(
            title: Text(widget.question,
                style: TextStyle(
                    color: widget.theme.text, fontWeight: FontWeight.w600, fontSize: 15)),
            trailing: Icon(_open ? Icons.expand_less : Icons.expand_more, color: widget.theme.muted),
            onTap: () => setState(() => _open = !_open),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.answer,
                  style: TextStyle(color: widget.theme.muted, fontSize: 14, height: 1.6)),
            ),
        ]),
      );
}