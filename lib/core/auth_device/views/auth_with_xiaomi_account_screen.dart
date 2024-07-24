import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

@RoutePage()
class AuthWithXiaomiAccountScreen extends StatefulWidget {
  const AuthWithXiaomiAccountScreen({
    required this.uri,
    required this.onAuthenticated,
    super.key,
  });

  final Uri uri;
  final void Function(String accessToken) onAuthenticated;

  @override
  State<AuthWithXiaomiAccountScreen> createState() =>
      _AuthWithXiaomiAccountScreenState();
}

class _AuthWithXiaomiAccountScreenState
    extends State<AuthWithXiaomiAccountScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    _controller = WebViewController(
      onPermissionRequest: (request) async {
        final currentUrl = await _controller.currentUrl();
        log(currentUrl ?? 'Not');
      },
    );
    _controller
      ..loadRequest(widget.uri)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            final uri = Uri.parse(request.url);
            if (uri.host == 'hm.xiaomi.com' &&
                uri.queryParameters.containsKey('code')) {
              await context.router.maybePop();
              widget.onAuthenticated(uri.queryParameters['code']!);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: WebViewWidget(controller: _controller),
    );
  }
}
