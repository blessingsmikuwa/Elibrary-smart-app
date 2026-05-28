import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/student/screens/payment_result_screen.dart';

void main() {
  runApp(const ELibraryApp());
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
    // App launched cold via deep link (e.g. user tapped myapp://… in browser)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    // App already running and a deep link arrives
    _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    // Expected: elibrary://payment/result?tx_ref=LIB-xxx&resourceId=yyy&status=success
    if (uri.host == 'payment' && uri.path == '/result') {
      final txRef         = uri.queryParameters['tx_ref']    ?? '';
      final resourceId    = uri.queryParameters['resourceId'];
      final initialStatus = uri.queryParameters['status'];   // success|failed|pending

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
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'eLibrary Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}