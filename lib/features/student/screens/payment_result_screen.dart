import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';

enum _PayStatus { loading, success, pending, failed, error }

class PaymentResultScreen extends StatefulWidget {
  final String  txRef;
  final String? resourceId;
  final String? initialStatus;

  const PaymentResultScreen({
    super.key,
    required this.txRef,
    this.resourceId,
    this.initialStatus,
  });

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  _PayStatus _status    = _PayStatus.loading;
  String?    _message;
  int        _countdown = 5;
  Timer?     _timer;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus == 'failed') {
      _transitionTo(_PayStatus.failed);
    } else {
      _verify();
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _verify() async {
    setState(() { _status = _PayStatus.loading; _message = null; });
    try {
      final headers = await authHeaders();
      if (widget.resourceId != null) {
        final res = await http.get(
          Uri.parse('$kApiBase/payment/has-access?resourceId=${widget.resourceId}'),
          headers: headers,
        );
        if (res.statusCode == 200) {
          final d = jsonDecode(res.body) as Map<String, dynamic>;
          if (d['hasAccess'] == true) {
            await _grantLocalAccess();
            _transitionTo(_PayStatus.success);
            return;
          }
        }
      }
      await Future.delayed(const Duration(seconds: 2));
      if (widget.resourceId != null) {
        final res2 = await http.get(
          Uri.parse('$kApiBase/payment/has-access?resourceId=${widget.resourceId}'),
          headers: headers,
        );
        if (res2.statusCode == 200) {
          final d = jsonDecode(res2.body) as Map<String, dynamic>;
          if (d['hasAccess'] == true) {
            await _grantLocalAccess();
            _transitionTo(_PayStatus.success);
            return;
          }
        }
      }
      _transitionTo(_PayStatus.pending,
          message: 'Your payment is being processed. '
              'Your book will unlock automatically once confirmed — '
              'please check back in a moment.');
    } catch (e) {
      _transitionTo(_PayStatus.error, message: e.toString());
    }
  }

  Future<void> _grantLocalAccess() async {
    if (widget.resourceId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('purchased_resource_ids') ?? '[]';
    final ids   = List<String>.from(jsonDecode(raw) as List);
    if (!ids.contains(widget.resourceId!)) {
      ids.add(widget.resourceId!);
      await prefs.setString('purchased_resource_ids', jsonEncode(ids));
    }
  }

  void _transitionTo(_PayStatus status, {String? message}) {
    if (!mounted) return;
    setState(() { _status = status; _message = message; _countdown = 5; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) { t.cancel(); _goToBooks(); }
    });
  }

  void _goToBooks() {
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    final configs = {
      _PayStatus.success: _Cfg(
        icon: Icons.check_circle_rounded,
        title: 'Payment Successful!',
        body: 'Your book has been unlocked. You can now read and download it.',
        accent: theme.primary,
        gradColors: [const Color(0xFF059669), theme.primary],
        heroBg: const Color(0xFF064E3B).withValues(alpha: 0.5),
        borderColor: theme.primary.withValues(alpha: 0.3),
      ),
      _PayStatus.pending: _Cfg(
        icon: Icons.access_time_rounded,
        title: 'Payment Pending',
        body: _message ?? 'Your payment is still being processed. Your book will unlock automatically once confirmed.',
        accent: theme.amber,
        gradColors: [const Color(0xFFD97706), theme.amber],
        heroBg: const Color(0xFF78350F).withValues(alpha: 0.4),
        borderColor: theme.amber.withValues(alpha: 0.3),
      ),
      _PayStatus.failed: _Cfg(
        icon: Icons.cancel_rounded,
        title: 'Payment Failed or Cancelled',
        body: 'Your payment was not completed. No charges were made. You can try again anytime.',
        accent: theme.danger,
        gradColors: [const Color(0xFFDC2626), theme.danger],
        heroBg: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
        borderColor: theme.danger.withValues(alpha: 0.3),
      ),
      _PayStatus.error: _Cfg(
        icon: Icons.warning_amber_rounded,
        title: 'Something Went Wrong',
        body: _message ?? 'We could not verify your payment result. Please contact support if you were charged.',
        accent: theme.danger,
        gradColors: [const Color(0xFFDC2626), theme.danger],
        heroBg: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
        borderColor: theme.danger.withValues(alpha: 0.3),
      ),
      _PayStatus.loading: _Cfg(
        icon: Icons.sync_rounded,
        title: 'Verifying Payment…',
        body: 'Please wait while we confirm your payment.',
        accent: theme.primary,
        gradColors: [theme.teal, theme.primary],
        heroBg: theme.primary.withValues(alpha: 0.15),
        borderColor: theme.primary.withValues(alpha: 0.3),
      ),
    };

    final cfg = configs[_status]!;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cfg.heroBg,
                border: Border.all(color: cfg.borderColor),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [

                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: cfg.gradColors,
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: cfg.accent.withValues(alpha: 0.35),
                      blurRadius: 20, offset: const Offset(0, 6),
                    )],
                  ),
                  child: _status == _PayStatus.loading
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Icon(cfg.icon, color: Colors.white, size: 36),
                ),

                const SizedBox(height: 22),

                Text(cfg.title,
                    style: TextStyle(
                        color: cfg.accent, fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),

                const SizedBox(height: 12),

                Text(cfg.body,
                    style: TextStyle(color: theme.muted, fontSize: 15, height: 1.6),
                    textAlign: TextAlign.center),

                const SizedBox(height: 22),

                if (widget.txRef.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.surface, border: Border.all(color: theme.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Transaction ref:',
                          style: TextStyle(color: theme.subtle, fontSize: 12)),
                      const SizedBox(height: 4),
                      SelectableText(widget.txRef,
                          style: TextStyle(
                              color: theme.text, fontSize: 13, fontFamily: 'monospace')),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],

                if (_status != _PayStatus.loading) ...[
                  Text('Returning to books in ${_countdown}s…',
                      style: TextStyle(color: cfg.accent.withValues(alpha: 0.8), fontSize: 13)),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: cfg.gradColors),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                            color: cfg.accent.withValues(alpha: 0.3),
                            blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _goToBooks,
                        child: const Text('Go to Books Now',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                  ),

                  if (_status == _PayStatus.pending) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.amber),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () { _timer?.cancel(); _verify(); },
                        child: Text('🔄 Check Again',
                            style: TextStyle(color: theme.amber, fontSize: 15)),
                      ),
                    ),
                  ],
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cfg {
  final IconData     icon;
  final String       title;
  final String       body;
  final Color        accent;
  final List<Color>  gradColors;
  final Color        heroBg;
  final Color        borderColor;

  const _Cfg({
    required this.icon, required this.title, required this.body,
    required this.accent, required this.gradColors,
    required this.heroBg, required this.borderColor,
  });
}