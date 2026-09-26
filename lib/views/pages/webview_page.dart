import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as inapp;
import 'package:miru_app/data/services/extension_service.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/utils/request.dart';
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

  bool _isSameDomain(String host1, String host2) {
    if (host1.isEmpty || host2.isEmpty) return false;
    if (host1 == host2) return true;
    if (host1.endsWith('.$host2') || host2.endsWith('.$host1')) return true;

    final parts1 = host1.split('.');
    final parts2 = host2.split('.');
    if (parts1.length >= 2 && parts2.length >= 2) {
      final sld1 = "${parts1[parts1.length - 2]}.${parts1[parts1.length - 1]}";
      final sld2 = "${parts2[parts2.length - 2]}.${parts2[parts2.length - 1]}";
      if (sld1 == sld2) return true;
    }
    return false;
  }

  _setCookie() async {
    final targetHost = Uri.parse(url).host;
    final extHost = Uri.parse(widget.extensionRuntime.extension.webSite).host;

    if (!_isSameDomain(loadUrl.host, targetHost) && !_isSameDomain(loadUrl.host, extHost)) {
      return;
    }
    try {
      final Map<String, String> mergedCookies = {};

      // 1. Get cookies via webview_cookie_manager
      try {
        final cookies = await cookieManager.getCookies(loadUrl.toString());
        for (final c in cookies) {
          mergedCookies[c.name] = c.value;
        }
      } catch (_) {}

      // 2. Get cookies via inappwebview native CookieManager
      try {
        final inappManager = inapp.CookieManager.instance();
        final webUri = inapp.WebUri(loadUrl.toString());
        final nativeCookies = await inappManager.getCookies(url: webUri);
        for (final c in nativeCookies) {
          mergedCookies[c.name] = c.value.toString();
        }
      } catch (_) {}

      if (mergedCookies.isNotEmpty) {
        final cookieString = mergedCookies.entries.map((e) => '${e.key}=${e.value}').join(';');
        debugPrint('Synced cookies for $loadUrl: $cookieString');
        await widget.extensionRuntime.setCookie(cookieString, loadUrl.toString());

        final extWebsite = widget.extensionRuntime.extension.webSite;
        if (extWebsite.isNotEmpty && extWebsite != loadUrl.toString()) {
          await MiruRequest.setCookie(cookieString, extWebsite);
        }
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
        title: Text(
          loadUrl.toString(),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Cookies & Done',
            onPressed: () async {
              await _setCookie();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: inapp.InAppWebView(
        initialUrlRequest: inapp.URLRequest(
          url: inapp.WebUri(url),
        ),
        initialSettings: inapp.InAppWebViewSettings(
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
        onUpdateVisitedHistory: (controller, url, isReload) async {
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
