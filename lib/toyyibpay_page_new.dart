import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ToyyibPayPage extends StatefulWidget {
  final String billUrl;
  final VoidCallback onSuccess;
  final VoidCallback onFailure;

  const ToyyibPayPage({
    super.key,
    required this.billUrl,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  State<ToyyibPayPage> createState() => _ToyyibPayPageState();
}

class _ToyyibPayPageState extends State<ToyyibPayPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _handledResult = false;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('🌐 PAGE STARTED: $url');
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              debugPrint('🌐 PAGE FINISHED: $url');
              if (mounted) setState(() => _isLoading = false);

              if (_handledResult) return;

              // Detect ToyyibPay success/return URLs
              if (url.contains('status_id=1') ||
                  url.contains('success') ||
                  url.contains('payment-success')) {
                debugPrint('✅ SUCCESS DETECTED');
                _handledResult = true;
                widget.onSuccess();
              } else if (url.contains('status_id=2') ||
                  url.contains('status_id=3') ||
                  url.contains('fail')) {
                debugPrint('❌ FAILURE DETECTED');
                _handledResult = true;
                widget.onFailure();
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.billUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ToyyibPay Checkout',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Manual success for demo — tap back after paying
            debugPrint('⬅️ BACK PRESSED — assuming success for demo');
            if (!_handledResult) {
              _handledResult = true;
              widget.onSuccess();
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: kIsWeb
          ? _buildWebPlaceholder()
          : Stack(
              children: [
                if (_controller != null)
                  WebViewWidget(controller: _controller!),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildWebPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.payment_rounded,
              size: 64,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(height: 16),
            Text(
              'ToyyibPay checkout',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Payment gateway is available on mobile app.\n'
              '(WebView not supported on Chrome)',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
