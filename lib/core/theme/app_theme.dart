import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeData {
  final bool isDark;
  const AppThemeData({required this.isDark});

  static const _darkBg      = Color(0xFF111827);
  static const _darkSurface = Color(0xFF1F2937);
  static const _darkBorder  = Color(0xFF374151);
  static const _darkText    = Color(0xFFE5E7EB);
  static const _darkMuted   = Color(0xFF9CA3AF);
  static const _darkSubtle  = Color(0xFF6B7280);

  static const _lightBg      = Color(0xFFF9FAFB);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightBorder  = Color(0xFFE5E7EB);
  static const _lightText    = Color(0xFF111827);
  static const _lightMuted   = Color(0xFF6B7280);
  static const _lightSubtle  = Color(0xFF9CA3AF);

  static const _primary = Color(0xFF10B981);
  static const _teal    = Color(0xFF0D9488);
  static const _amber   = Color(0xFFF59E0B);
  static const _danger  = Color(0xFFEF4444);

  Color get bg      => isDark ? _darkBg      : _lightBg;
  Color get surface => isDark ? _darkSurface : _lightSurface;
  Color get border  => isDark ? _darkBorder  : _lightBorder;
  Color get text    => isDark ? _darkText    : _lightText;
  Color get muted   => isDark ? _darkMuted   : _lightMuted;
  Color get subtle  => isDark ? _darkSubtle  : _lightSubtle;
  Color get primary => _primary;
  Color get teal    => _teal;
  Color get amber   => _amber;
  Color get danger  => _danger;

  Color get background => bg;
  Color get surface2   => isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

  Color get heroBg => isDark
      ? const Color(0xFF064E3B).withValues(alpha: 0.35)
      : const Color(0xFFECFDF5);
  Color get heroBorder => isDark
      ? _primary.withValues(alpha: 0.3)
      : const Color(0xFF6EE7B7);

  Color get inputFill   => isDark ? const Color(0xFF111827) : Colors.white;
  Color get inputBorder => isDark ? _darkBorder : const Color(0xFFD1D5DB);

  Color get dropdownFill => isDark ? _darkSurface : Colors.white;

  Color get errorBg => isDark
      ? const Color(0xFF7F1D1D).withValues(alpha: 0.4)
      : const Color(0xFFFEF2F2);
  Color get errorBorder => isDark
      ? _danger.withValues(alpha: 0.5)
      : const Color(0xFFFCA5A5);

  Color get cardHoverBorder => isDark
      ? const Color(0xFF4B5563)
      : const Color(0xFF6EE7B7);

  // Accent shades used across screens
  Color get greenAccent  => isDark ? const Color(0xFF2EA043) : const Color(0xFF059669);
  Color get greenBg      => isDark
      ? const Color(0xFF1A3A2A)
      : const Color(0xFFECFDF5);
  Color get greenBgBorder => isDark
      ? const Color(0xFF2EA043)
      : const Color(0xFF6EE7B7);

  Color get blueBg  => isDark ? const Color(0xFF0D2A3D) : const Color(0xFFEFF6FF);
  Color get blueText => isDark ? const Color(0xFF58A6FF) : const Color(0xFF2563EB);

  Color get redBg   => isDark ? const Color(0xFF3D1A1A) : const Color(0xFFFEF2F2);
  Color get redText => isDark ? const Color(0xFFF85149) : const Color(0xFFDC2626);

  Color get amberBg   => isDark ? const Color(0xFF3A2A1A) : const Color(0xFFFFFBEB);
  Color get amberText => isDark ? const Color(0xFFE3B341) : const Color(0xFFD97706);

  Color get chipActiveBg   => greenAccent;
  Color get chipInactiveBg => isDark ? const Color(0xFF161B22) : const Color(0xFFF3F4F6);
  Color get chipInactiveBorder => isDark ? const Color(0xFF21262D) : const Color(0xFFD1D5DB);
  Color get chipInactiveText   => isDark ? const Color(0xFF6E7681) : const Color(0xFF6B7280);

  Color get cardBg     => isDark ? const Color(0xFF161B22) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF21262D) : const Color(0xFFE5E7EB);

  Color get statBg => isDark ? const Color(0xFF161B22) : const Color(0xFFF9FAFB);

  Color get inputBg => isDark ? const Color(0xFF161B22) : Colors.white;

  Color get textFieldBorder => isDark ? const Color(0xFF21262D) : const Color(0xFFD1D5DB);
}

class AppThemeController extends StatefulWidget {
  final Widget child;
  final bool?  forceDark; // driven by ThemeManager when provided
  const AppThemeController({super.key, required this.child, this.forceDark});

  static _AppThemeControllerState of(BuildContext context) =>
      context.findAncestorStateOfType<_AppThemeControllerState>()!;

  @override
  State<AppThemeController> createState() => _AppThemeControllerState();
}

class _AppThemeControllerState extends State<AppThemeController> {
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    if (widget.forceDark != null) {
      _isDark = widget.forceDark!;
    } else {
      _load();
    }
  }

  @override
  void didUpdateWidget(AppThemeController old) {
    super.didUpdateWidget(old);
    if (widget.forceDark != null && widget.forceDark != _isDark) {
      setState(() => _isDark = widget.forceDark!);
    }
  }

  Future<void> _load() async {
    final prefs  = await SharedPreferences.getInstance();
    final stored = prefs.getBool('app_dark_mode');
    if (mounted) setState(() => _isDark = stored ?? true);
  }

  Future<void> setDark(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('app_dark_mode', value);
    if (mounted) setState(() => _isDark = value);
  }

  bool get isDark => _isDark;

  @override
  Widget build(BuildContext context) => _AppThemeInherited(
        isDark: _isDark,
        child: widget.child,
      );
}

class _AppThemeInherited extends InheritedWidget {
  final bool isDark;
  const _AppThemeInherited({required this.isDark, required super.child});

  @override
  bool updateShouldNotify(_AppThemeInherited old) => old.isDark != isDark;
}

class AppTheme {
  static AppThemeData of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<_AppThemeInherited>();
    return AppThemeData(isDark: w?.isDark ?? true);
  }

  static bool isDark(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppThemeInherited>()?.isDark ??
      true;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF9FAFB),
          foregroundColor: Color(0xFF111827),
          elevation: 0,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111827),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
          surface: const Color(0xFF1F2937),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111827),
          foregroundColor: Color(0xFFE5E7EB),
          elevation: 0,
        ),
        dividerColor: const Color(0xFF374151),
      );
}

class AppColors {
  AppColors._();
  static const primary    = Color(0xFF10B981);
  static const success    = Color(0xFF10B981);
  static const teal       = Color(0xFF0D9488);
  static const amber      = Color(0xFFF59E0B);
  static const danger     = Color(0xFFEF4444);
  static const error      = Color(0xFFEF4444);
  static const background = Color(0xFF111827);
  static const surface    = Color(0xFF1F2937);
  static const surface2   = Color(0xFF374151);
  static const border     = Color(0xFF374151);
  static const text       = Color(0xFFE5E7EB);
  static const text2      = Color(0xFF9CA3AF);
  static const muted      = Color(0xFF9CA3AF);
  static const subtle     = Color(0xFF6B7280);
  static const accent4    = Color(0xFFEF4444);
}