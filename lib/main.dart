import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/student/screens/payment_result_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: const ELibraryApp(),
    ),
  );
}

class ELibraryApp extends StatefulWidget {
  const ELibraryApp({super.key});
  @override
  State<ELibraryApp> createState() => _ELibraryAppState();
}

class _ELibraryAppState extends State<ELibraryApp> {
  final _appLinks = AppLinks();
  final _navKey   = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
    _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host == 'payment' && uri.path == '/result') {
      final txRef         = uri.queryParameters['tx_ref']    ?? '';
      final resourceId    = uri.queryParameters['resourceId'];
      final initialStatus = uri.queryParameters['status'];
      _navKey.currentState?.push(MaterialPageRoute(
        builder: (_) => PaymentResultScreen(
          txRef:         txRef,
          resourceId:    resourceId,
          initialStatus: initialStatus,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) {
        return AppThemeController(
          forceDark: themeManager.isDarkMode,
          child: Builder(
            builder: (ctx) => MaterialApp(
              navigatorKey: _navKey,
              title: 'eLibrary Mobile',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeManager.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const LoginScreen(),
            ),
          ),
        );
      },
    );
  }
}