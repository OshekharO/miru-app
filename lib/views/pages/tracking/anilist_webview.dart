import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_all/webview_all.dart';

class AnilistWebViewPage extends StatefulWidget {
  const AnilistWebViewPage({
    super.key,
    required this.url,
  });
  final String url;

  @override
  State<AnilistWebViewPage> createState() => _AnilistWebViewPageState();
}

class _AnilistWebViewPageState extends State<AnilistWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (url.contains("access_token")) {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                debugPrint(uri.host);
              }
              Get.back(result: url);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    WebViewCookieManager().clearCookies();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anilist Login"),
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
