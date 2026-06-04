import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../student/screens/student_home_screen.dart';
import '../../teacher/screens/teacher_home_screen.dart';
import '../../../core/services/api_service.dart';

const String _kAccessTokenKey  = 'accessToken';
const String _kRefreshTokenKey = 'refreshToken';
const String _kUserKey         = 'user';

// ─── Palette (mirrors webapp) ─────────────────────────────────────────────────
const _bg      = Color(0xFF111827);
const _surface = Color(0xFF1F2937);
const _border  = Color(0xFF374151);
const _primary = Color(0xFF10B981);
const _text    = Color(0xFFE5E7EB);
const _muted   = Color(0xFF9CA3AF);
const _danger  = Color(0xFFF87171);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool    _obscurePassword = true;
  bool    _isLoading       = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Authenticates with the backend. Role is determined entirely by the
  /// server response — no client-side role selection required.
  Future<Map<String, dynamic>> _loginWithBackend({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$kApiBase/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final msg = body['message'];
      throw Exception(msg is String ? msg : msg is List ? msg.join(', ') : 'Login failed');
    }

    final accessToken  = body['accessToken']  as String;
    final refreshToken = body['refreshToken'] as String;
    final user         = body['user']         as Map<String, dynamic>;
    final serverRole   = (user['role'] as String).toUpperCase();

    if (serverRole == 'ADMIN') {
      throw Exception('Admins must use the admin portal.');
    }
    if (serverRole != 'STUDENT' && serverRole != 'TEACHER') {
      throw Exception('Unrecognised account type. Please contact support.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessTokenKey,  accessToken);
    await prefs.setString(_kRefreshTokenKey, refreshToken);
    await prefs.setString(_kUserKey, jsonEncode(user));
    return user;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final user = await _loginWithBackend(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final role = (user['role'] as String).toUpperCase();
      if (role == 'STUDENT') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
      } else if (role == 'TEACHER') {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const TeacherHomeScreen()));
      }
    } on Exception catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // ── Logo ──────────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF0D9488)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          blurRadius: 20, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'eLibrary',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _text, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sign in to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 15),
                ),

                const SizedBox(height: 32),

                // ── Card ──────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // ── Error ──────────────────────────────────────────
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
                            border: Border.all(
                                color: const Color(0xFFF87171)
                                    .withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                color: _danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_errorMessage!,
                                  style: const TextStyle(
                                      color: _danger, fontSize: 14)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Email ──────────────────────────────────────────
                      _WebLabel(text: 'Email'),
                      const SizedBox(height: 6),
                      _WebField(
                        controller: _emailController,
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter email' : null,
                      ),

                      const SizedBox(height: 16),

                      // ── Password ───────────────────────────────────────
                      _WebLabel(text: 'Password'),
                      const SizedBox(height: 6),
                      _WebField(
                        controller: _passwordController,
                        hint: '••••••••',
                        obscure: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _muted, size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Enter password' : null,
                      ),

                      const SizedBox(height: 24),

                      // ── Submit ─────────────────────────────────────────
                      SizedBox(
                        height: 50,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF10B981)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                                : const Text('Sign In',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Small shared widgets ──────────────────────────────────────────────────────

class _WebLabel extends StatelessWidget {
  final String text;
  const _WebLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: _muted, fontSize: 13, fontWeight: FontWeight.w500));
}

class _WebField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _WebField({
    required this.controller,
    required this.hint,
    this.obscure       = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   controller,
    obscureText:  obscure,
    keyboardType: keyboardType,
    style:        const TextStyle(color: _text, fontSize: 15),
    validator:    validator,
    decoration: InputDecoration(
      hintText:       hint,
      hintStyle:      const TextStyle(color: Color(0xFF6B7280)),
      suffixIcon:     suffix,
      filled:         true,
      fillColor:      const Color(0xFF111827),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _danger)),
    ),
  );
}