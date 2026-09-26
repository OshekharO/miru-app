import 'dart:convert';
import 'dart:io';
import 'package:miru_app/utils/miru_storage.dart';

enum DnsProvider {
  off,
  cloudflare,
  google,
  adguard,
  quad9;

  static DnsProvider fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'cloudflare':
        return DnsProvider.cloudflare;
      case 'google':
        return DnsProvider.google;
      case 'adguard':
        return DnsProvider.adguard;
      case 'quad9':
        return DnsProvider.quad9;
      case 'off':
      default:
        return DnsProvider.off;
    }
  }

  String toValue() {
    switch (this) {
      case DnsProvider.cloudflare:
        return 'cloudflare';
      case DnsProvider.google:
        return 'google';
      case DnsProvider.adguard:
        return 'adguard';
      case DnsProvider.quad9:
        return 'quad9';
      case DnsProvider.off:
        return 'off';
    }
  }
}

class DnsResolver {
  static final Map<String, String> _cache = {};
  static DnsProvider _lastProvider = DnsProvider.off;

  static final Map<DnsProvider, List<String>> _providerEndpoints = {
    DnsProvider.cloudflare: [
      'https://1.1.1.1/dns-query',
      'https://cloudflare-dns.com/dns-query',
    ],
    DnsProvider.google: [
      'https://dns.google/resolve',
    ],
    DnsProvider.adguard: [
      'https://dns.adguard-dns.com/resolve',
    ],
    DnsProvider.quad9: [
      'https://dns.quad9.net/dns-query',
      'https://9.9.9.9/dns-query',
    ],
  };

  static void clearCache() {
    _cache.clear();
  }

  static Future<String> resolve(String host) async {
    if (host.isEmpty || InternetAddress.tryParse(host) != null) {
      return host;
    }

    String? settingValue;
    try {
      settingValue = MiruStorage.getSetting(SettingKey.dns) as String?;
    } catch (_) {
      settingValue = 'off';
    }

    final provider = DnsProvider.fromString(settingValue);

    if (provider != _lastProvider) {
      _cache.clear();
      _lastProvider = provider;
    }

    if (provider == DnsProvider.off) {
      return host;
    }

    if (_cache.containsKey(host)) {
      return _cache[host]!;
    }

    final endpoints = _providerEndpoints[provider];
    if (endpoints == null || endpoints.isEmpty) {
      return host;
    }

    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.connectionTimeout = const Duration(seconds: 5);

    try {
      for (final endpointUrl in endpoints) {
        try {
          final uri = Uri.parse('$endpointUrl?name=$host&type=A');
          final req = await client.getUrl(uri);
          req.headers.set('accept', 'application/dns-json');
          req.headers.set('user-agent', 'Mozilla/5.0');
          final resp = await req.close();

          if (resp.statusCode == 200) {
            final body = await resp.transform(utf8.decoder).join();
            final json = jsonDecode(body);
            if (json is Map && json['Answer'] is List) {
              for (final item in json['Answer']) {
                if (item is Map && item['type'] == 1 && item['data'] != null) {
                  final ip = item['data'].toString().trim();
                  if (InternetAddress.tryParse(ip) != null) {
                    _cache[host] = ip;
                    return ip;
                  }
                }
              }
            }
          }
        } catch (_) {
          // Retry next endpoint
        }
      }
    } finally {
      client.close();
    }

    return host;
  }
}
