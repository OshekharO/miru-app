import 'package:flutter/material.dart';
import 'package:miru_app/data/services/extension_service.dart';
import 'package:miru_app/utils/miru_storage.dart';
import 'package:miru_app/utils/request.dart';
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
  final cookieManager = WebViewCookieManager();
  late Uri loadUrl = Uri.parse(url);
  bool _isSaving = false;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final userAgent = widget.userAgent ?? MiruStorage.getUASetting();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (!mounted) return;
            final uri = Uri.tryParse(url);
            if (uri != null) {
              setState(() {
                loadUrl = uri;
              });
              _setCookie();
            }
          },
          onPageFinished: (url) async {
            if (!mounted) return;
            final uri = Uri.tryParse(url);
            if (uri != null) {
              setState(() {
                loadUrl = uri;
              });
              await _setCookie();
            }
          },
          onUrlChange: (change) async {
            if (!mounted) return;
            final changeUrl = change.url;
            if (changeUrl != null) {
              final uri = Uri.tryParse(changeUrl);
              if (uri != null) {
                if (!mounted) return;
                setState(() {
                  loadUrl = uri;
                });
                await _setCookie();
              }
            }
          },
        ),
      )
      ..loadRequest(loadUrl);
  }

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
        final uri = Uri.tryParse(queryUrl);
        if (uri == null) continue;

        try {
          final cookies = await cookieManager.getCookies(domain: uri);
          for (final c in cookies) {
            mergedCookies[c.name] = c.value;
          }
        } catch (_) {}
      }

      try {
        final rawUa = await _controller.runJavaScriptReturningResult('navigator.userAgent');
        final ua = rawUa.toString().replaceAll('"', '').trim();
        if (ua.isNotEmpty) {
          widget.extensionRuntime.setUserAgent(ua);
          debugPrint('Synced User-Agent for WebView: $ua');
        }
      } catch (_) {}

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
        body: WebViewWidget(
          controller: _controller,
        ),
      ),
    );
  }
}
