import 'package:flutter/material.dart';
import 'package:miru_app/data/services/extension_service.dart';
import 'package:webview_all/webview_all.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({
    super.key,
    required this.extensionRuntime,
    required this.url,
    this.userAgent,
  });
  final ExtensionService extensionRuntime;
  final String url;
  final String? userAgent;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late String url = widget.url.startsWith('http://') || widget.url.startsWith('https://')
      ? widget.url
      : widget.extensionRuntime.extension.webSite + widget.url;
  late Uri loadUrl = Uri.parse(url);

  Future<void> _handleBack() async {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            loadUrl.toString(),
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Done',
              onPressed: _handleBack,
            ),
          ],
        ),
        body: Webview(
          url: url,
        ),
      ),
    );
  }
}
