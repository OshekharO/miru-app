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

class _CustomConnectionTask<S> implements ConnectionTask<S> {
  @override
  final Future<S> socket;
  final void Function() _onCancel;

  _CustomConnectionTask(this.socket, this._onCancel);

  @override
  void cancel() {
    _onCancel();
  }
}

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

        client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
          if (proxyHost != null) {
            return Socket.startConnect(proxyHost, proxyPort!);
          }

          final host = uri.host;
          String targetHost = host;
          if (host.isNotEmpty && InternetAddress.tryParse(host) == null) {
            targetHost = await DnsResolver.resolve(host);
          }

          final socket = await Socket.connect(
            targetHost,
            uri.port,
            timeout: const Duration(seconds: 10),
          );

          if (uri.scheme == 'https') {
            final secureSocket = await SecureSocket.secure(
              socket,
              host: host,
              onBadCertificate: (cert) => true,
            );
            return _CustomConnectionTask<Socket>(
              Future.value(secureSocket),
              () => secureSocket.destroy(),
            );
          }

          return _CustomConnectionTask<Socket>(
            Future.value(socket),
            () => socket.destroy(),
          );
        };

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
