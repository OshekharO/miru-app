import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
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
    dio = Dio();
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );
    final cookieManager = CookieManager(_cookieJar);
    dio.interceptors.add(cookieManager);
    refreshProxy();
    _isInitialized = true;
  }

  static refreshProxy() {
    String proxy = "";
    final type = MiruStorage.getSetting(SettingKey.proxyType);
    if (type == "DIRECT") {
      proxy = type;
    } else {
      proxy = '$type ${MiruStorage.getSetting(SettingKey.proxy)}';
    }

    if (!_isInitialized) {
      SocksProxy.initProxy(proxy: proxy);
      return;
    }
    SocksProxy.setProxy(proxy);
  }

  static Future<void> cleanCookie(String url) async {
    await _cookieJar.delete(Uri.parse(url));
  }

  /// Saves cookies (such as Cloudflare `cf_clearance` or `__cf_bm` tokens) obtained
  /// from WebView or manual challenge resolution into the persistent cookie jar.
  ///
  /// Cookies are saved for both the specific request domain and the root domain to
  /// ensure subdomains inherit anti-bot clearance across extension network calls.
  static Future<void> setCookie(String cookies, String url) async {
    final uri = Uri.parse(url);
    final hostParts = uri.host.split('.');
    final rootDomain = hostParts.length >= 2
        ? hostParts.sublist(hostParts.length - 2).join('.')
        : uri.host;
    final rootDomainUri = Uri.parse('${uri.scheme}://$rootDomain');

    final cookieList = cookies.split(';');
    for (final cookieStr in cookieList) {
      final trimmed = cookieStr.trim();
      if (trimmed.isEmpty) continue;
      final cookie = Cookie.fromSetCookieValue(trimmed);
      cookie.domain = rootDomain;
      cookie.path = "/";
      await _cookieJar.saveFromResponse(
        rootDomainUri,
        [cookie],
      );
      if (uri != rootDomainUri) {
        await _cookieJar.saveFromResponse(
          uri,
          [cookie],
        );
      }
    }
  }

  static Future<String> getCookie(String url) async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(url));
    return cookies.map((e) => e.toString()).join(';');
  }
}
