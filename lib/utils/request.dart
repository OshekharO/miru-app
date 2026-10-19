import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:miru_app/utils/dns_resolver.dart';
import 'package:miru_app/utils/miru_directory.dart';
import 'package:miru_app/utils/miru_storage.dart';

late final Dio dio;

class MiruRequest {
  static final _cookieJar = PersistCookieJar(
    ignoreExpires: true,
    storage: FileStorage("${MiruDirectory.getDirectory}/.cookies/"),
  );

  static bool _isInitialized = false;

  static Future<void> ensureInitialized() async {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
    dio.interceptors.add(DohInterceptor());
    final cookieManager = CookieManager(_cookieJar);
    dio.interceptors.add(cookieManager);
    refreshProxy();
    _isInitialized = true;
  }

  static refreshProxy() {
    String proxy = "DIRECT";
    final type = MiruStorage.getSetting(SettingKey.proxyType);
    final rawProxy = MiruStorage.getSetting(SettingKey.proxy)?.toString().trim() ?? '';

    if (type == "DIRECT" || type == null || rawProxy.isEmpty) {
      proxy = "DIRECT";
    } else {
      proxy = '$type $rawProxy';
    }

    try {
      if (!_isInitialized) {
        SocksProxy.initProxy(proxy: proxy);
        return;
      }
      SocksProxy.setProxy(proxy);
    } catch (e) {
      // Fallback to DIRECT if proxy settings fail
      if (proxy != "DIRECT") {
        try {
          if (!_isInitialized) {
            SocksProxy.initProxy(proxy: "DIRECT");
          } else {
            SocksProxy.setProxy("DIRECT");
          }
        } catch (_) {}
      }
    }
  }

  static Future<void> cleanCookie(String url) async {
    await _cookieJar.delete(Uri.parse(url));
  }

  static Future<void> setCookie(String cookies, String url) async {
    if (url.isEmpty || cookies.trim().isEmpty) return;
    Uri? uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return;

    final host = uri.host;
    final hostParts = host.split('.');
    final rootDomain = hostParts.length >= 2
        ? hostParts.sublist(hostParts.length - 2).join('.')
        : host;
    final scheme = uri.scheme.isNotEmpty ? uri.scheme : 'https';
    final rootDomainUri = Uri.parse('$scheme://$rootDomain');
    final targetUri = Uri.parse('$scheme://$host');

    // Handle both "key=value; key2=value2" and Set-Cookie directives separated by newline or semicolon
    final items = cookies.split(RegExp(r'[\r\n;]+'));
    for (final item in items) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) continue;

      // Ignore attributes if splitting by semicolon resulted in standalone directives
      final lower = trimmed.toLowerCase();
      if (lower.startsWith('path=') ||
          lower.startsWith('domain=') ||
          lower.startsWith('expires=') ||
          lower.startsWith('max-age=') ||
          lower.startsWith('samesite=') ||
          lower == 'secure' ||
          lower == 'httponly') {
        continue;
      }

      try {
        final cookie = Cookie.fromSetCookieValue(trimmed);
        cookie.domain = rootDomain;
        cookie.path = "/";
        await _cookieJar.saveFromResponse(rootDomainUri, [cookie]);
        if (targetUri != rootDomainUri) {
          await _cookieJar.saveFromResponse(targetUri, [cookie]);
        }
      } catch (_) {}
    }
  }

  static bool isCloudflareResponse(Response? response) {
    if (response == null) return false;
    final statusCode = response.statusCode ?? 0;
    if (statusCode != 403 && statusCode != 503) return false;
    final serverHeader = response.headers.value('server')?.toLowerCase() ?? '';
    final cfRay = response.headers.value('cf-ray');
    final body = response.data?.toString().toLowerCase() ?? '';
    return serverHeader.contains('cloudflare') ||
        cfRay != null ||
        body.contains('just a moment') ||
        body.contains('cf-turnstile');
  }

  static Future<String> getCookie(String url) async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(url));
    return cookies.map((e) => e.toString()).join(';');
  }
}
