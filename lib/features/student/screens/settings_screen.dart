import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const _bg      = Color(0xFF0D1117);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);
  static const _primary = Color(0xFF2EA043);
  static const _danger  = Color(0xFFF85149);
  static const _text    = Color(0xFFE6EDF3);
  static const _muted   = Color(0xFF8B949E);
  static const _subtle  = Color(0xFF6E7681);

  // ── Profile state ─────────────────────────────────────────────────────────
  bool    _profileLoading = true;
  String  _firstName    = '';
  String  _lastName     = '';
  String  _email        = '';
  String  _schoolName   = '';
  String  _classLevel   = 'Form 4';

  // ── Preference state ──────────────────────────────────────────────────────
  bool _darkMode          = true;
  bool _largeText         = false;
  bool _downloadMobileData = false;
  bool _appLock           = false;
  bool _activityHistory   = true;
  bool _newResourceAlerts = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _profileLoading = true);
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
          // Try to get class level from profile
          final cl = data['classLevel']?.toString() ?? data['form']?.toString();
          if (cl != null && cl.isNotEmpty) _classLevel = cl;
        });
      }
    } catch (_) {
      // Fall back to cached user in SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw   = prefs.getString('user');
        if (raw != null && mounted) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          setState(() {
            _firstName  = data['firstName']?.toString() ?? '';
            _lastName   = data['lastName']?.toString()  ?? '';
            _email      = data['email']?.toString()     ?? '';
          });
        }
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Logout?', style: TextStyle(color: _text)),
        content: const Text(
          'You will be returned to the login screen.',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout', style: TextStyle(color: _danger)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    // Pop all routes back to root (login screen)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String get _displayName {
    final n = '$_firstName $_lastName'.trim();
    return n.isEmpty ? 'Student' : n;
  }

  // ── Build ───────────────────────────────────────────────────────────────────
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
                // ── Profile section ─────────────────────────────────────────
                _Section(
                  title: 'Profile',
                  icon: Icons.person_rounded,
                  children: [
                    // Profile header
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
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName,
                              style: const TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 17),
                            ),
                            if (_schoolName.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(_schoolName, style: const TextStyle(color: _muted, fontSize: 13)),
                            ],
                            if (_email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(_email, style: const TextStyle(color: _subtle, fontSize: 12)),
                            ],
                          ],
                        )),
                      ]),
                    ),

                    // Class level picker
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
                          onChanged: (v) { if (v != null) setState(() => _classLevel = v); },
                        ),
                      ),
                    ),

                    _ActionTile(
                      icon: Icons.edit_rounded,
                      title: 'Edit profile',
                      subtitle: 'Update your personal details',
                      onTap: () => _snack('Edit profile coming soon.'),
                    ),
                  ],
                ),

                // ── Account section ─────────────────────────────────────────
                _Section(
                  title: 'Account',
                  icon: Icons.manage_accounts_rounded,
                  children: [
                    _ActionTile(
                      icon: Icons.lock_reset_rounded,
                      title: 'Change password',
                      subtitle: 'Keep your account secure',
                      onTap: () => _snack('Password change coming soon.'),
                    ),
                    _ActionTile(
                      icon: Icons.devices_rounded,
                      title: 'Manage login session',
                      subtitle: 'Review signed-in devices',
                      onTap: () => _snack('Session management coming soon.'),
                    ),
                    _ActionTile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out of this account',
                      color: _danger,
                      onTap: _logout,
                    ),
                  ],
                ),

                // ── Appearance section ─────────────────────────────────────
                _Section(
                  title: 'Appearance',
                  icon: Icons.palette_rounded,
                  children: [
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
                  ],
                ),

                // ── Privacy & Security ─────────────────────────────────────
                _Section(
                  title: 'Privacy & Security',
                  icon: Icons.shield_rounded,
                  children: [
                    _SwitchTile(
                      icon: Icons.pin_rounded,
                      title: 'App lock',
                      subtitle: 'Require a PIN to open the app',
                      value: _appLock,
                      onChanged: (v) => setState(() => _appLock = v),
                    ),
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
                      subtitle: 'Allow downloads without Wi-Fi',
                      value: _downloadMobileData,
                      onChanged: (v) => setState(() => _downloadMobileData = v),
                    ),
                    _ActionTile(
                      icon: Icons.delete_sweep_rounded,
                      title: 'Clear activity history',
                      subtitle: 'Remove local activity records',
                      color: _danger,
                      onTap: () => _snack('Activity history cleared.'),
                    ),
                  ],
                ),

                // ── Help & Support ─────────────────────────────────────────
                _Section(
                  title: 'Help & Support',
                  icon: Icons.help_rounded,
                  children: [
                    _ActionTile(
                      icon: Icons.question_answer_rounded,
                      title: 'FAQ',
                      subtitle: 'Answers about books, papers, and quizzes',
                      onTap: () => _snack('FAQ coming soon.'),
                    ),
                    _ActionTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Contact support',
                      subtitle: 'Ask an admin or teacher for help',
                      onTap: () => _snack('Support contact coming soon.'),
                    ),
                    _ActionTile(
                      icon: Icons.report_problem_rounded,
                      title: 'Report a problem',
                      subtitle: 'Tell us when something is broken',
                      onTap: () => _snack('Problem report coming soon.'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_rounded, color: _text),
                      title: const Text('About app', style: TextStyle(color: _text, fontWeight: FontWeight.w700)),
                      subtitle: const Text('EduLib Malawi v1.0.0', style: TextStyle(color: _subtle)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ─── Section container ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String       title;
  final IconData     icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  static const _text    = Color(0xFFE6EDF3);
  static const _surface = Color(0xFF161B22);
  static const _border  = Color(0xFF21262D);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _text, size: 21),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: _text, fontSize: 19, fontWeight: FontWeight.w800,
              ),
            ),
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
        ],
      ),
    );
  }
}

// ─── Tiles ────────────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData     icon;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;
  final Color?       color;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

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
  final IconData           icon;
  final String             title;
  final String             subtitle;
  final bool               value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  static const _text    = Color(0xFFE6EDF3);
  static const _subtle  = Color(0xFF6E7681);
  static const _primary = Color(0xFF2EA043);

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: _text),
      title:     Text(title,    style: const TextStyle(color: _text, fontWeight: FontWeight.w700)),
      subtitle:  Text(subtitle, style: const TextStyle(color: _subtle)),
      value: value,
      activeThumbColor: _primary,
      onChanged: onChanged,
    );
  }
}