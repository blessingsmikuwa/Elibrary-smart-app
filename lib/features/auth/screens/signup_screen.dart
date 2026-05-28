import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../student/screens/student_home_screen.dart';
import '../../teacher/screens/teacher_home_screen.dart';

const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE', 
  defaultValue: 'https://online-library-api-muuz.onrender.com/', 
);

enum SignupRole { student, teacher }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _libraryCardNumberController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _bioController = TextEditingController();

  SignupRole _role = SignupRole.student;
  String _level = 'Form 1';
  String? _schoolId;
  List<Map<String, dynamic>> _schools = [];
  String? _schoolsError;
  String? _error;
  bool _schoolsLoading = true;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _fetchSchools();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _libraryCardNumberController.dispose();
    _dateOfBirthController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<dynamic> _requestJson(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_apiBaseUrl$path');
      final request = await client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final decoded = responseBody.isEmpty ? null : jsonDecode(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Request failed. Please try again.';
        if (decoded is Map<String, dynamic>) {
          final rawMessage = decoded['message'];
          if (rawMessage is List) {
            message = rawMessage.join(', ');
          } else if (rawMessage is String && rawMessage.isNotEmpty) {
            message = rawMessage;
          }
        }
        throw HttpException(message, uri: uri);
      }

      return decoded;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _fetchSchools() async {
    setState(() {
      _schoolsLoading = true;
      _schoolsError = null;
    });

    try {
      final data = await _requestJson('/school');
      if (!mounted) return;

      setState(() {
        _schools = data is List
            ? data
                  .whereType<Map>()
                  .map((school) => Map<String, dynamic>.from(school))
                  .toList()
            : [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _schoolsError = 'Could not load schools. Please refresh the page.';
      });
    } finally {
      if (mounted) {
        setState(() => _schoolsLoading = false);
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 15, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate == null) return;

    final month = selectedDate.month.toString().padLeft(2, '0');
    final day = selectedDate.day.toString().padLeft(2, '0');
    _dateOfBirthController.text = '${selectedDate.year}-$month-$day';
  }

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() => _loading = true);

    final role = _role == SignupRole.student ? 'STUDENT' : 'TEACHER';
    final bio = _role == SignupRole.student
        ? '${_bioController.text.trim()} | Level: $_level'
        : _bioController.text.trim();

    final payload = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'role': role,
      'schoolId': _schoolId,
      'libraryCardNumber': _libraryCardNumberController.text.trim(),
      'bio': bio,
      'dateOfBirth': _dateOfBirthController.text.trim(),
    };

    try {
      final data = await _requestJson(
        '/auth/register',
        method: 'POST',
        body: payload,
      );

      if (!mounted) return;

      final registeredRole = data is Map<String, dynamic>
          ? (data['user'] is Map<String, dynamic>
                ? data['user']['role']?.toString().toUpperCase()
                : role)
          : role;

      if (registeredRole == 'TEACHER') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
        );
      }
    } on HttpException catch (err) {
      if (mounted) {
        setState(() => _error = err.message);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Network error. Please check your connection and try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _goToLogin() {
    Navigator.maybePop(context);
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  border: Border.all(color: const Color(0xFF21262D)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Color(0xFFE6EDF3),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign up as Student or Teacher',
                        style: TextStyle(
                          color: Color(0xFF6E7681),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_error != null) _buildError(_error!),
                      _buildRoleSelector(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _firstNameController,
                              hintText: 'First Name',
                              validator: (value) =>
                                  _required(value, 'First name'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _lastNameController,
                              hintText: 'Last Name',
                              validator: (value) =>
                                  _required(value, 'Last name'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Email is required';
                          if (!text.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        obscureText: _obscurePassword,
                        validator: (value) => _required(value, 'Password'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        obscureText: _obscureConfirmPassword,
                        validator: (value) =>
                            _required(value, 'Confirm password'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _libraryCardNumberController,
                        hintText: 'Library Card Number',
                        validator: (value) =>
                            _required(value, 'Library card number'),
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _dateOfBirthController,
                        hintText: 'Date of Birth',
                        readOnly: true,
                        validator: (value) => _required(value, 'Date of birth'),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today_outlined),
                          onPressed: _pickDateOfBirth,
                        ),
                        onTap: _pickDateOfBirth,
                      ),
                      if (_role == SignupRole.student) ...[
                        const SizedBox(height: 14),
                        _buildLevelDropdown(),
                      ],
                      const SizedBox(height: 14),
                      if (_schoolsError != null)
                        Text(
                          _schoolsError!,
                          style: const TextStyle(
                            color: Color(0xFFF85149),
                            fontSize: 13,
                          ),
                        )
                      else
                        _buildSchoolDropdown(),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _bioController,
                        hintText: 'Bio',
                        maxLines: 4,
                        validator: (value) => _required(value, 'Bio'),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              _loading ||
                                  _schoolsLoading ||
                                  _schoolsError != null
                              ? null
                              : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2EA043),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(
                              0xFF2EA043,
                            ).withValues(alpha: 0.45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Sign up as ${_role == SignupRole.student ? 'Student' : 'Teacher'}',
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: Color(0xFF6E7681),
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: _goToLogin,
                            child: const Text(
                              'Login',
                              style: TextStyle(color: Color(0xFF2EA043)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3D1F1F),
        border: Border.all(color: const Color(0xFFF85149)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFF85149), fontSize: 13),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildRoleButton(
            label: 'Student',
            selected: _role == SignupRole.student,
            onTap: () => setState(() => _role = SignupRole.student),
          ),
          _buildRoleButton(
            label: 'Teacher',
            selected: _role == SignupRole.teacher,
            onTap: () => setState(() => _role = SignupRole.teacher),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2EA043) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF8B949E),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    int maxLines = 1,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 14),
      decoration: _fieldDecoration(hintText: hintText, suffixIcon: suffixIcon),
    );
  }

  Widget _buildLevelDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _level,
      dropdownColor: const Color(0xFF0D1117),
      style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 14),
      decoration: _fieldDecoration(hintText: 'Level'),
      items: const ['Form 1', 'Form 2', 'Form 3', 'Form 4']
          .map((level) => DropdownMenuItem(value: level, child: Text(level)))
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _level = value);
      },
    );
  }

  Widget _buildSchoolDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _schoolId,
      dropdownColor: const Color(0xFF0D1117),
      style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 14),
      decoration: _fieldDecoration(
        hintText: _schoolsLoading ? 'Loading schools...' : 'Select School',
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'School is required' : null,
      items: _schools
          .map(
            (school) => DropdownMenuItem<String>(
              value: school['id']?.toString(),
              child: Text(
                school['name']?.toString() ?? 'Unnamed school',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _schoolsLoading
          ? null
          : (value) {
              setState(() => _schoolId = value);
            },
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF0D1117),
      hintStyle: const TextStyle(color: Color(0xFF8B949E)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF21262D)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF21262D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2EA043), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent4),
      ),
    );
  }
}