import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../student/screens/student_home_screen.dart';
import '../../teacher/screens/teacher_home_screen.dart';
import '../screens/signup_screen.dart';

// ─── Constants ───────────────────────────────────────────────────────────────
const String _kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://127.0.0.1:3000', 
);

const String _kAccessTokenKey = 'accessToken';
const String _kRefreshTokenKey = 'refreshToken';
const String _kUserKey = 'user';

// ─── Enums ───────────────────────────────────────────────────────────────────
enum UserRole { student, teacher }

// ─── Screen ──────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.student;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── API call ────────────────────────────────────────────────────────────────
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

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final msg = body['message'];
      throw Exception(
        msg is String
            ? msg
            : msg is List
                ? msg.join(', ')
                : 'Login failed',
      );
    }

    final accessToken = body['accessToken'] as String;
    final refreshToken = body['refreshToken'] as String;
    final user = body['user'] as Map<String, dynamic>;
    final serverRole = (user['role'] as String).toUpperCase();

    // ── Role guards ────────────────────────────────────────────────────────
    if (serverRole == 'ADMIN') {
      throw Exception('Admins must use the admin portal.');
    }

    final expectedRole =
        role == UserRole.student ? 'STUDENT' : 'TEACHER';

    if (serverRole != expectedRole) {
      throw Exception(
        'Incorrect role selected. Please choose the correct account type.',
      );
    }

    // ── Persist tokens ─────────────────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessTokenKey, accessToken);
    await prefs.setString(_kRefreshTokenKey, refreshToken);
    await prefs.setString(_kUserKey, jsonEncode(user));

    return user;
  }

  // ── Login handler ──────────────────────────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _loginWithBackend(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (!mounted) return;

      final role = (user['role'] as String).toUpperCase();

      if (role == 'STUDENT') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const StudentHomeScreen(),
          ),
        );
      } else if (role == 'TEACHER') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TeacherHomeScreen(),
          ),
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

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                Icon(Icons.menu_book_rounded,
                    size: 80, color: primaryColor),

                const SizedBox(height: 16),

                Text(
                  'eLibrary',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                // ── Role selector ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Student'),
                      selected: _selectedRole == UserRole.student,
                      onSelected: (_) =>
                          setState(() => _selectedRole = UserRole.student),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Teacher'),
                      selected: _selectedRole == UserRole.teacher,
                      onSelected: (_) =>
                          setState(() => _selectedRole = UserRole.teacher),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Error ─────────────────────────
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),

                const SizedBox(height: 10),

                // ── Email ─────────────────────────
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter email' : null,
                ),

                const SizedBox(height: 10),

                // ── Password ──────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter password' : null,
                ),

                const SizedBox(height: 20),

                // ── Button ────────────────────────
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}