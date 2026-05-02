import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _backgroundColor = Color(0xFF0D1117);
  static const Color _surfaceColor = Color(0xFF161B22);
  static const Color _borderColor = Color(0xFF21262D);
  static const Color _primaryColor = Color(0xFF2EA043);
  static const Color _dangerColor = Color(0xFFF85149);
  static const Color _textColor = Color(0xFFE6EDF3);
  static const Color _mutedTextColor = Color(0xFF8B949E);
  static const Color _subtleTextColor = Color(0xFF6E7681);

  bool _darkMode = true;
  bool _largeText = false;
  bool _downloadOnMobileData = false;
  bool _appLock = false;
  bool _activityHistory = true;
  bool _newResourceAlerts = true;

  String _classLevel = 'Form 4';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Profile',
            icon: Icons.person_rounded,
            children: [
              const _ProfileHeader(),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.badge_rounded,
                title: 'Class level',
                value: _classLevel,
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _classLevel,
                    dropdownColor: _surfaceColor,
                    style: const TextStyle(color: _textColor),
                    iconEnabledColor: _mutedTextColor,
                    items: const ['Form 1', 'Form 2', 'Form 3', 'Form 4']
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _classLevel = value);
                    },
                  ),
                ),
              ),
              _ActionTile(
                icon: Icons.edit_rounded,
                title: 'Edit profile',
                subtitle: 'Update student details later from backend data',
                onTap: () => _showMessage('Edit profile will be added soon.'),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Account',
            icon: Icons.manage_accounts_rounded,
            children: [
              _ActionTile(
                icon: Icons.lock_reset_rounded,
                title: 'Change password',
                subtitle: 'Keep your account secure',
                onTap: () => _showMessage('Password change will be added soon.'),
              ),
              _ActionTile(
                icon: Icons.devices_rounded,
                title: 'Manage login session',
                subtitle: 'Review signed-in devices later',
                onTap: () => _showMessage('Session management will be added soon.'),
              ),
              _ActionTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out of this student account',
                color: _dangerColor,
                onTap: _confirmLogout,
              ),
            ],
          ),
          _SettingsSection(
            title: 'Appearance',
            icon: Icons.palette_rounded,
            children: [
              _SwitchTile(
                icon: Icons.dark_mode_rounded,
                title: 'Dark mode',
                subtitle: 'Use the dark e-library theme',
                value: _darkMode,
                onChanged: (value) => setState(() => _darkMode = value),
              ),
              _SwitchTile(
                icon: Icons.format_size_rounded,
                title: 'Large reading text',
                subtitle: 'Make book and notes text easier to read',
                value: _largeText,
                onChanged: (value) => setState(() => _largeText = value),
              ),
              _SwitchTile(
                icon: Icons.notifications_active_rounded,
                title: 'New resource alerts',
                subtitle: 'Notify me when new books or papers are added',
                value: _newResourceAlerts,
                onChanged: (value) =>
                    setState(() => _newResourceAlerts = value),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Privacy & Security',
            icon: Icons.shield_rounded,
            children: [
              _SwitchTile(
                icon: Icons.pin_rounded,
                title: 'App lock',
                subtitle: 'Require a PIN before opening the app',
                value: _appLock,
                onChanged: (value) => setState(() => _appLock = value),
              ),
              _SwitchTile(
                icon: Icons.history_rounded,
                title: 'Save activity history',
                subtitle: 'Keep recent downloads, views, and quiz activity',
                value: _activityHistory,
                onChanged: (value) =>
                    setState(() => _activityHistory = value),
              ),
              _SwitchTile(
                icon: Icons.cloud_download_rounded,
                title: 'Downloads on mobile data',
                subtitle: 'Allow files to download when Wi-Fi is unavailable',
                value: _downloadOnMobileData,
                onChanged: (value) =>
                    setState(() => _downloadOnMobileData = value),
              ),
              _ActionTile(
                icon: Icons.delete_sweep_rounded,
                title: 'Clear activity history',
                subtitle: 'Remove local activity records from this device',
                color: _dangerColor,
                onTap: () => _showMessage('Activity history cleared locally.'),
              ),
            ],
          ),
          _SettingsSection(
            title: 'Help & Support',
            icon: Icons.help_rounded,
            children: [
              _ActionTile(
                icon: Icons.question_answer_rounded,
                title: 'FAQ',
                subtitle: 'Get answers about books, papers, and quizzes',
                onTap: () => _showMessage('FAQ content will be added soon.'),
              ),
              _ActionTile(
                icon: Icons.support_agent_rounded,
                title: 'Contact support',
                subtitle: 'Ask an admin or teacher for help',
                onTap: () => _showMessage('Support contact will be added soon.'),
              ),
              _ActionTile(
                icon: Icons.report_problem_rounded,
                title: 'Report a problem',
                subtitle: 'Tell us when something is missing or broken',
                onTap: () => _showMessage('Problem report will be added soon.'),
              ),
              const _InfoTile(
                icon: Icons.info_rounded,
                title: 'About app',
                value: 'EduLib Malawi v1.0.0',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surfaceColor,
        title: const Text(
          'Logout?',
          style: TextStyle(color: _textColor),
        ),
        content: const Text(
          'You will return to the login screen once authentication is connected.',
          style: TextStyle(color: _mutedTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: _dangerColor),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      _showMessage('Logout will be connected to authentication later.');
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _SettingsScreenState._textColor, size: 21),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _SettingsScreenState._textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _SettingsScreenState._surfaceColor,
              border: Border.all(color: _SettingsScreenState._borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _SettingsScreenState._primaryColor,
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student',
                  style: TextStyle(
                    color: _SettingsScreenState._textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Smart E-Library Secondary School',
                  style: TextStyle(
                    color: _SettingsScreenState._mutedTextColor,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'student@example.com',
                  style: TextStyle(
                    color: _SettingsScreenState._subtleTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? _SettingsScreenState._textColor;

    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(color: itemColor, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: _SettingsScreenState._subtleTextColor),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: _SettingsScreenState._subtleTextColor,
      ),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: _SettingsScreenState._textColor),
      title: Text(
        title,
        style: const TextStyle(
          color: _SettingsScreenState._textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: _SettingsScreenState._subtleTextColor),
      ),
      value: value,
      activeColor: _SettingsScreenState._primaryColor,
      onChanged: onChanged,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _SettingsScreenState._textColor),
      title: Text(
        title,
        style: const TextStyle(
          color: _SettingsScreenState._textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: _SettingsScreenState._subtleTextColor),
      ),
      trailing: trailing,
    );
  }
}
