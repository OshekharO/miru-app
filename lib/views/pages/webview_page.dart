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
  bool _isSaving = false;

  Future<void> _setCookie() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final Map<String, String> mergedCookies = {};
      final urlsToQuery = <String>{
        url,
        loadUrl.toString(),
        widget.extensionRuntime.extension.webSite,
      };

      for (final queryUrl in urlsToQuery) {
        if (queryUrl.isEmpty) continue;

        // 1. Get cookies via webview_cookie_manager
        try {
          final cookies = await cookieManager.getCookies(queryUrl);
          for (final c in cookies) {
            mergedCookies[c.name] = c.value;
          }
        } catch (_) {}

        // 2. Get cookies via inappwebview native CookieManager
        try {
          final inappManager = inapp.CookieManager.instance();
          final webUri = inapp.WebUri(queryUrl);
          final nativeCookies = await inappManager.getCookies(url: webUri);
          for (final c in nativeCookies) {
            mergedCookies[c.name] = c.value.toString();
          }
        } catch (_) {}
      }

      if (mergedCookies.isNotEmpty) {
        final cookieString = mergedCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
        debugPrint('Synced cookies for $loadUrl: $cookieString');

        final extWebsite = widget.extensionRuntime.extension.webSite;
        await widget.extensionRuntime.setCookie(
          cookieString,
          extWebsite.isNotEmpty ? extWebsite : loadUrl.toString(),
        );
        await widget.extensionRuntime.setCookie(cookieString, loadUrl.toString());
        if (extWebsite.isNotEmpty) {
          await MiruRequest.setCookie(cookieString, extWebsite);
        }
        await MiruRequest.setCookie(cookieString, loadUrl.toString());
      }
    } catch (e) {
      debugPrint('Error syncing cookies: $e');
    } finally {
      _isSaving = false;
    }
  }

  Future<void> _handleBack() async {
    await _setCookie();
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
              tooltip: 'Save Cookies & Done',
              onPressed: _handleBack,
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
      ),
    );
  }
}
