import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/screens/login_screen.dart';

// ─── Page (no Scaffold — used inside TeacherHomeScreen IndexedStack) ──────────
class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
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
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      radius: 50,
                      child: const Text(
                        'MP',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Mr. Phiri',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Biology Teacher',
                    style: TextStyle(color: Color(0xFF8b949e), fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Zomba Secondary School',
                    style: TextStyle(color: Color(0xFF8b949e), fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(child: _buildStatCard('28', 'Materials', Icons.book, AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('156', 'Students', Icons.people, AppColors.warning)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('12', 'Quizzes', Icons.quiz, AppColors.success)),
            ],
          ),
          const SizedBox(height: 24),

          // Personal Information
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
                const Text('Personal Information',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.email, 'Email', 'mr.phiri@zombaschool.edu.mw'),
                const Divider(color: Color(0xFF30363d), height: 24),
                _buildInfoRow(Icons.phone, 'Phone', '+265 888 123 456'),
                const Divider(color: Color(0xFF30363d), height: 24),
                _buildInfoRow(Icons.school, 'Department', 'Science'),
                const Divider(color: Color(0xFF30363d), height: 24),
                _buildInfoRow(Icons.calendar_today, 'Joined', 'January 2020'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Actions
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
                const Text('Quick Actions',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildActionButton(
                  Icons.settings, 
                  'Account Settings',
                  onTap: () => _navigateToScreen(context, const AccountSettingsScreen()),
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  Icons.notifications, 
                  'Notification Preferences',
                  onTap: () => _navigateToScreen(context, const NotificationPreferencesScreen()),
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  Icons.help, 
                  'Help & Support',
                  onTap: () => _navigateToScreen(context, const HelpSupportScreen()),
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  Icons.info, 
                  'About',
                  onTap: () => _navigateToScreen(context, const AboutScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout — clears the entire navigation stack and goes back to LoginScreen
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
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

  // FIXED: Navigation method that works with IndexedStack
  void _navigateToScreen(BuildContext context, Widget screen) {
    // Use rootNavigator: true to push above the IndexedStack
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
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
          Text(value,
              style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.text2, size: 20),
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

  Widget _buildActionButton(IconData icon, String title, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF21262d),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.text2, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(color: AppColors.text, fontSize: 14)),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8b949e)),
            ],
          ),
        ),
      ),
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
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        ],
      ),
      body: const TeacherProfilePage(),
    );
  }
}

// Account Settings Screen
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSettingsSection(
              title: 'Profile Information',
              children: [
                _buildSettingsTile(
                  icon: Icons.person,
                  title: 'Full Name',
                  subtitle: 'Mr. Phiri',
                  onTap: () => _showEditDialog(context, 'Full Name', 'Mr. Phiri'),
                ),
                _buildSettingsTile(
                  icon: Icons.email,
                  title: 'Email Address',
                  subtitle: 'mr.phiri@zombaschool.edu.mw',
                  onTap: () => _showEditDialog(context, 'Email Address', 'mr.phiri@zombaschool.edu.mw'),
                ),
                _buildSettingsTile(
                  icon: Icons.phone,
                  title: 'Phone Number',
                  subtitle: '+265 888 123 456',
                  onTap: () => _showEditDialog(context, 'Phone Number', '+265 888 123 456'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              title: 'Security',
              children: [
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () => _navigateToChangePassword(context),
                ),
                _buildSettingsTile(
                  icon: Icons.security,
                  title: 'Two-Factor Authentication',
                  subtitle: 'Add extra security to your account',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingsSection(
              title: 'Preferences',
              children: [
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () => _showLanguageSelector(context),
                ),
                _buildSettingsTile(
                  icon: Icons.dark_mode,
                  title: 'Theme',
                  subtitle: 'Dark Mode',
                  onTap: () => _showThemeSelector(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8b949e)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit $field', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: field,
            labelStyle: const TextStyle(color: Color(0xFF8b949e)),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF30363d)),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.primary),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8b949e))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$field updated to ${controller.text}')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _navigateToChangePassword(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Select Language', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 16),
          _buildLanguageOption(context, 'English'),
          _buildLanguageOption(context, 'Chichewa'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String language) {
    return ListTile(
      title: Text(language, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Language changed to $language')),
        );
      },
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text('Select Theme', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 16),
          _buildThemeOption(context, 'Dark Mode', Icons.dark_mode),
          _buildThemeOption(context, 'Light Mode', Icons.light_mode),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String theme, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(theme, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Theme changed to $theme')),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon!')),
    );
  }
}

// Change Password Screen
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPasswordField('Current Password', Icons.lock_outline),
            const SizedBox(height: 16),
            _buildPasswordField('New Password', Icons.lock_outline),
            const SizedBox(height: 16),
            _buildPasswordField('Confirm New Password', Icons.lock_outline),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully!')),
                  );
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text('Update Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, IconData icon) {
    return TextField(
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8b949e)),
        prefixIcon: Icon(icon, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF30363d)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Notification Preferences Screen
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool smsNotifications = false;
  bool assignmentReminders = true;
  bool quizReminders = true;
  bool classUpdates = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildNotificationSection(
              title: 'Notification Channels',
              children: [
                _buildSwitchTile(
                  icon: Icons.email,
                  title: 'Email Notifications',
                  subtitle: 'Receive notifications via email',
                  value: emailNotifications,
                  onChanged: (value) => setState(() => emailNotifications = value),
                ),
                _buildSwitchTile(
                  icon: Icons.notifications_active,
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications on your device',
                  value: pushNotifications,
                  onChanged: (value) => setState(() => pushNotifications = value),
                ),
                _buildSwitchTile(
                  icon: Icons.sms,
                  title: 'SMS Notifications',
                  subtitle: 'Receive notifications via SMS',
                  value: smsNotifications,
                  onChanged: (value) => setState(() => smsNotifications = value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNotificationSection(
              title: 'Notification Types',
              children: [
                _buildSwitchTile(
                  icon: Icons.assignment,
                  title: 'Assignment Reminders',
                  subtitle: 'Get reminders for upcoming assignments',
                  value: assignmentReminders,
                  onChanged: (value) => setState(() => assignmentReminders = value),
                ),
                _buildSwitchTile(
                  icon: Icons.quiz,
                  title: 'Quiz Reminders',
                  subtitle: 'Get reminders for upcoming quizzes',
                  value: quizReminders,
                  onChanged: (value) => setState(() => quizReminders = value),
                ),
                _buildSwitchTile(
                  icon: Icons.class_,
                  title: 'Class Updates',
                  subtitle: 'Get updates about class changes',
                  value: classUpdates,
                  onChanged: (value) => setState(() => classUpdates = value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preferences saved successfully!')),
                  );
                  Navigator.of(context, rootNavigator: true).pop();
                },
                child: const Text('Save Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF8b949e))),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }
}

// Help & Support Screen
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF30363d)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text(
                    'How can we help you?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search for help...',
                      hintStyle: const TextStyle(color: Color(0xFF8b949e)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF8b949e)),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF30363d)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildHelpTile(
              icon: Icons.help,
              title: 'FAQ',
              subtitle: 'Frequently asked questions',
              onTap: () => _showComingSoon(context),
            ),
            _buildHelpTile(
              icon: Icons.contact_support,
              title: 'Contact Support',
              subtitle: 'Get in touch with our support team',
              onTap: () => _showContactSupport(context),
            ),
            _buildHelpTile(
              icon: Icons.message,
              title: 'Live Chat',
              subtitle: 'Chat with support (24/7)',
              onTap: () => _showComingSoon(context),
            ),
            _buildHelpTile(
              icon: Icons.description,
              title: 'User Guide',
              subtitle: 'Read the documentation',
              onTap: () => _showComingSoon(context),
            ),
            _buildHelpTile(
              icon: Icons.bug_report,
              title: 'Report a Bug',
              subtitle: 'Help us improve the app',
              onTap: () => _showReportBug(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 28),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF8b949e))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF8b949e)),
        onTap: onTap,
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.support_agent, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text('Contact Support', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildContactOption(context, Icons.email, 'support@zombaschool.edu.mw'),
            const SizedBox(height: 12),
            _buildContactOption(context, Icons.phone, '+265 888 123 456'),
            const SizedBox(height: 12),
            _buildContactOption(context, Icons.message, 'Live Chat (Available 24/7)'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(BuildContext context, IconData icon, String text) {
    return InkWell(
      onTap: () {
        // Handle contact option tap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contacting: $text')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF21262d),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showReportBug(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Report a Bug', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please describe the issue you encountered:', style: TextStyle(color: Color(0xFF8b949e))),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe the bug...',
                hintStyle: const TextStyle(color: Color(0xFF8b949e)),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF30363d)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8b949e))),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug report submitted! Thank you for your feedback.')),
              );
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon!')),
    );
  }
}

// About Screen
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF30363d)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school, size: 64, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Zomba School App',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Color(0xFF8b949e), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'An educational platform connecting teachers and students for better learning outcomes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8b949e), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAboutTile(
              icon: Icons.info,
              title: 'Terms of Service',
              onTap: () => _showComingSoon(context),
            ),
            _buildAboutTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () => _showComingSoon(context),
            ),
            _buildAboutTile(
              icon: Icons.star,
              title: 'Rate this App',
              onTap: () => _showComingSoon(context),
            ),
            _buildAboutTile(
              icon: Icons.share,
              title: 'Share App',
              onTap: () => _showShareDialog(context),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF30363d)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Developed by',
                    style: TextStyle(color: Color(0xFF8b949e), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Zomba School Tech Team',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© ${DateTime.now().year} Zomba Secondary School. All rights reserved.',
                    style: const TextStyle(color: Color(0xFF8b949e), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF8b949e)),
        onTap: onTap,
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Share App', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Share Zomba School App with others',
          style: TextStyle(color: Color(0xFF8b949e)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8b949e))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is coming soon!')),
    );
  }
}