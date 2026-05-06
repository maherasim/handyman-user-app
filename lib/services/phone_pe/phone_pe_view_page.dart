import 'dart:convert';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
class PhonePeWebViewPage extends StatefulWidget {
  final String redirectUrl;
  final String transactionId;
  final Function(Map<String, dynamic>) onComplete;

  const PhonePeWebViewPage({
    super.key,
    required this.redirectUrl,
    required this.transactionId,
    required this.onComplete,
  });

  @override
  State<PhonePeWebViewPage> createState() => _PhonePeWebViewPageState();
}

class _PhonePeWebViewPageState extends State<PhonePeWebViewPage> {
  late final WebViewController _controller;
  bool hasCompleted = false; // prevent double-callbacks

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            log("Navigating to: ${request.url}");

            // Detect backend callback page
            if (request.url.contains("api/phonepe/callback")) {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageStarted: (url) async {
            if (url.contains("api/phonepe/callback")) {
              _handleCallbackPage();
              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
          },
          onPageFinished: (url) {
            if (url.contains("api/phonepe/callback")) {
              _handleCallbackPage();
            }
          },
          onWebResourceError: (error) {
            log("WebView Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  Future<void> _handleCallbackPage() async {
    if (hasCompleted) return;
    hasCompleted = true;

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final result = await _controller.runJavaScriptReturningResult("document.body.innerText");
      var jsonString = result.toString();
      if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
        jsonString = jsonString.substring(1, jsonString.length - 1);
      }
      jsonString = jsonString.replaceAll('\\n', '').replaceAll('\\"', '"').replaceAll('\\\\', '\\').trim();
      final data = jsonDecode(jsonString);
      // Extract details
      final code = data['data']?['code'] ?? 'UNKNOWN';
      final txnId = data['data']?['transactionId'] ?? widget.transactionId;
      final merchantId = data['data']?['merchantId'] ?? 'N/A';
      widget.onComplete({
        "transactionId": txnId,
        "merchantId": merchantId,
        "status": code,
      });
    } catch (e) {
      toast("Failed to verify payment");

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(
        "PhonePe Payment",
        showBack: true,
        elevation: 1,
        color: primaryColor
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}