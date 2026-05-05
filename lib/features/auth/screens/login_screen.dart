import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../student/screens/student_home_screen.dart';
import '../../teacher/screens/teacher_home_screen.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const String _kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://127.0.0.1:3000', // Android emulator → localhost 10.0.2.2
);

const String _kAccessTokenKey  = 'accessToken';
const String _kRefreshTokenKey = 'refreshToken';
const String _kUserKey         = 'user';

// ─── Enums ───────────────────────────────────────────────────────────────────
enum UserRole { student, teacher }

// ─── Screen ──────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey           = GlobalKey<FormState>();
  final _emailController   = TextEditingController();
  final _passwordController = TextEditingController();

  bool     _obscurePassword = true;
  bool     _isLoading       = false;
  String?  _errorMessage;
  UserRole _selectedRole    = UserRole.student;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── API call ────────────────────────────────────────────────────────────────
  /// Calls POST /auth/login, validates the returned role,
  /// persists tokens + user, then returns the user map.
  Future<Map<String, dynamic>> _loginWithBackend({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final uri = Uri.parse('$_kApiBase/auth/login');

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final body = (jsonDecode(response.body) as Map).cast<String, dynamic>();

    if (response.statusCode != 200) {
      // Surface the backend's message when available
      final msg = body['message'];
      throw Exception(
        msg is String
            ? msg
            : msg is List
                ? (msg as List).join(', ')
                : 'Login failed. Please try again.',
      );
    }

    final accessToken  = body['accessToken']  as String;
    final refreshToken = body['refreshToken'] as String;
    final user         = body['user']         as Map<String, dynamic>;
    final serverRole   = (user['role'] as String).toUpperCase();

    // ── Role guards (mirrors React login) ──────────────────────────────────
    if (serverRole == 'ADMIN') {
      throw Exception('Admins must use the admin portal to sign in.');
    }

    final expectedRole = role == UserRole.student ? 'STUDENT' : 'TEACHER';
    if (serverRole != expectedRole) {
      final label = role == UserRole.student ? 'student' : 'teacher';
      throw Exception(
        'This account is not a $label. Please select the correct role.',
      );
    }

    // ── Persist tokens ─────────────────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessTokenKey,  accessToken);
    await prefs.setString(_kRefreshTokenKey, refreshToken);
    await prefs.setString(_kUserKey,         jsonEncode(user));

    return user;
  }

  // ── Submit handler ──────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      final user = await _loginWithBackend(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
        role:     _selectedRole,
      );

      if (!mounted) return;

    if (!result["success"]) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login failed")));
      return;
    }

    final role = result["role"];
      final role = (user['role'] as String).toUpperCase();

      if (role == 'STUDENT') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
        );
      } else if (role == 'TEACHER') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
        );
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // ── Logo ──────────────────────────────────────────────────
                Icon(Icons.menu_book_rounded, size: 80, color: primaryColor),
                const SizedBox(height: 16),

                Text(
                  'eLibrary',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Role selector ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Login as',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Student'),
                            selected: _selectedRole == UserRole.student,
                            onSelected: (_) => setState(() {
                              _selectedRole = UserRole.student;
                              _errorMessage = null;
                            }),
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: const Text('Teacher'),
                            selected: _selectedRole == UserRole.teacher,
                            onSelected: (_) => setState(() {
                              _selectedRole = UserRole.teacher;
                              _errorMessage = null;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Error banner ──────────────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Email field ───────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() => _errorMessage = null),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password field ────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onChanged: (_) => setState(() => _errorMessage = null),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── Login button ──────────────────────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Login"),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Need an account? '),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SignupScreen(),
                                ),
                              );
                            },
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}