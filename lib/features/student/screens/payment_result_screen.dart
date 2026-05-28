import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/api_service.dart';

enum _PayStatus { loading, success, pending, failed, error }

const _primary = Color(0xFF2EA043);
const _surface = Color(0xFF161B22);
const _bg      = Color(0xFF0D1117);
const _border  = Color(0xFF21262D);
const _text    = Color(0xFFE6EDF3);
const _muted   = Color(0xFF8B949E);
const _subtle  = Color(0xFF6E7681);
const _blue    = Color(0xFF1F6FEB);
const _danger  = Color(0xFFF85149);
const _amber   = Color(0xFFE3A525);

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

    // If PayChangu already told us the user cancelled, skip verification.
    if (widget.initialStatus == 'failed') {
      _transitionTo(_PayStatus.failed);
    } else {
      _verify();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }


  Future<void> _verify() async {
    setState(() { _status = _PayStatus.loading; _message = null; });

    try {
      final headers = await authHeaders();

      // First check: has the webhook already granted access?
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

      // Wait 2 s for the webhook to land, then check once more.
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

      // Still not confirmed — show pending.
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

  // ── Countdown then pop back ────────────────────────────────────────────────

  void _transitionTo(_PayStatus status, {String? message}) {
    if (!mounted) return;
    setState(() { _status = status; _message = message; _countdown = 5; });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _goToBooks();
      }
    });
  }

  void _goToBooks() {
    if (!mounted) return;
    // Pop with true so BooksScreen knows to call _fetchAll()
    Navigator.of(context).pop(true);
  }


  _StatusConfig get _config {
    switch (_status) {
      case _PayStatus.success:
        return _StatusConfig(
          icon: '✅',
          title: 'Payment Successful!',
          body: 'Your book has been unlocked. You can now read and download it.',
          accent: _primary,
          bg: const Color(0xFF1A3A2A),
          borderColor: _primary,
        );
      case _PayStatus.pending:
        return _StatusConfig(
          icon: '⏳',
          title: 'Payment Pending',
          body: _message ??
              'Your payment is still being processed. '
              'Your book will unlock automatically once confirmed.',
          accent: _amber,
          bg: const Color(0xFF3A2A1A),
          borderColor: _amber,
        );
      case _PayStatus.failed:
        return _StatusConfig(
          icon: '❌',
          title: 'Payment Failed or Cancelled',
          body: 'Your payment was not completed. No charges were made. '
              'You can try again anytime.',
          accent: _danger,
          bg: const Color(0xFF3D1A1A),
          borderColor: _danger,
        );
      case _PayStatus.error:
        return _StatusConfig(
          icon: '⚠️',
          title: 'Something Went Wrong',
          body: _message ??
              'We could not verify your payment result. '
              'Please contact support if you were charged.',
          accent: _danger,
          bg: const Color(0xFF3D1A1A),
          borderColor: _danger,
        );
      case _PayStatus.loading:
        return _StatusConfig(
          icon: '🔄',
          title: 'Verifying Payment…',
          body: 'Please wait while we confirm your payment.',
          accent: _blue,
          bg: const Color(0xFF1A1A3D),
          borderColor: _blue,
        );
    }
  }


  @override
  Widget build(BuildContext context) {
    final cfg = _config;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cfg.bg,
                border: Border.all(color: cfg.borderColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Icon / spinner
                  if (_status == _PayStatus.loading)
                    SizedBox(
                      width: 64, height: 64,
                      child: CircularProgressIndicator(
                          color: cfg.accent, strokeWidth: 3),
                    )
                  else
                    Text(cfg.icon, style: const TextStyle(fontSize: 64)),

                  const SizedBox(height: 20),

                  Text(cfg.title,
                      style: TextStyle(
                          color: cfg.accent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),

                  const SizedBox(height: 12),

                  Text(cfg.body,
                      style: const TextStyle(
                          color: _muted, fontSize: 14, height: 1.5),
                      textAlign: TextAlign.center),

                  const SizedBox(height: 20),

                  // Transaction ref
                  if (widget.txRef.isNotEmpty) ...[
                    const Text('Transaction ref:',
                        style: TextStyle(color: _subtle, fontSize: 11)),
                    const SizedBox(height: 2),
                    SelectableText(widget.txRef,
                        style: const TextStyle(
                            color: _text,
                            fontSize: 12,
                            fontFamily: 'monospace')),
                    const SizedBox(height: 20),
                  ],

                  if (_status != _PayStatus.loading) ...[
                    Text('Returning to books in ${_countdown}s…',
                        style:
                            const TextStyle(color: _subtle, fontSize: 12)),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cfg.accent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _goToBooks,
                        child: const Text('Go to Books Now',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ),
                    ),

                    if (_status == _PayStatus.pending) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _amber),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            _timer?.cancel();
                            _verify();
                          },
                          child: const Text('🔄 Check Again',
                              style: TextStyle(
                                  color: _amber, fontSize: 14)),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _StatusConfig {
  final String icon;
  final String title;
  final String body;
  final Color  accent;
  final Color  bg;
  final Color  borderColor;

  const _StatusConfig({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.bg,
    required this.borderColor,
  });
}