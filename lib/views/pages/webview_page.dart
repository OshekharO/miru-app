import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:miru_app/data/services/extension_service.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({
    super.key,
    required this.extensionRuntime,
    required this.url,
  });
  final ExtensionService extensionRuntime;
  final String url;

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late String url = widget.url.startsWith('http://') || widget.url.startsWith('https://')
      ? widget.url
      : widget.extensionRuntime.extension.webSite + widget.url;
  final cookieManager = WebviewCookieManager();
  late Uri loadUrl = Uri.parse(url);

  _setCookie() async {
    final targetHost = Uri.parse(url).host;
    if (loadUrl.host.isEmpty || (loadUrl.host != targetHost && !loadUrl.host.endsWith('.$targetHost'))) {
      return;
    }
    try {
      final cookies = await cookieManager.getCookies(loadUrl.toString());
      if (cookies.isNotEmpty) {
        final cookieString =
            cookies.map((e) => '${e.name}=${e.value}').toList().join(';');
        debugPrint('$url $cookieString');
        await widget.extensionRuntime.setCookie(cookieString);
      }
    } catch (e) {
      debugPrint('Error syncing cookies: $e');
    }
  }

  @override
  void dispose() {
    _setCookie();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loadUrl.toString()),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(url),
        ),
        initialSettings: InAppWebViewSettings(
          userAgent: MiruStorage.getUASetting(),
          javaScriptEnabled: true,
          domStorageEnabled: true,
        ),
        onLoadStart: (controller, url) {
          if (url != null) {
            setState(() {
              loadUrl = url;
            });
            _setCookie();
          }
        },
        onLoadStop: (controller, url) async {
          if (url != null) {
            setState(() {
              loadUrl = url;
            });
            await _setCookie();
          }
        },
      ),
    );
  }
}
