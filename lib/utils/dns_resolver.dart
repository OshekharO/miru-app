import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:miru_app/utils/miru_storage.dart';

class DnsCacheEntry {
  final String ip;
  final DateTime expiresAt;

  DnsCacheEntry(this.ip, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class DnsResolver {
  static final Map<String, DnsCacheEntry> _cache = {};
  static final Dio _client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  static final Map<String, String> providers = {
    'cloudflare': 'https://1.1.1.1/dns-query',
    'google': 'https://8.8.8.8/resolve',
    'adguard': 'https://94.140.14.14/dns-query',
    'quad9': 'https://9.9.9.9/dns-query',
  };

  static void clearCache() {
    _cache.clear();
  }

  static Future<String?> resolve(String host, {String? providerKey}) async {
    if (InternetAddress.tryParse(host) != null) {
      return host;
    }

    final key = providerKey ?? MiruStorage.getSetting(SettingKey.dns);
    if (key == null || key == 'off' || key.toString().isEmpty) {
      return null;
    }

    final provider = key.toString().toLowerCase();
    final endpoint = providers[provider];
    if (endpoint == null) {
      return null;
    }

    final cacheKey = '$provider:$host';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.ip;
    }

    try {
      final response = await _client.get(
        endpoint,
        queryParameters: {
          'name': host,
          'type': 'A',
        },
        options: Options(
          headers: {
            'accept': 'application/dns-json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data;
        Map<String, dynamic>? jsonMap;
        if (data is Map) {
          jsonMap = Map<String, dynamic>.from(data);
        } else if (data is String) {
          try {
            final decoded = jsonDecode(data);
            if (decoded is Map) {
              jsonMap = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {}
        }

        if (jsonMap != null) {
          final answers = jsonMap['Answer'] as List<dynamic>?;
          if (answers != null && answers.isNotEmpty) {
            for (final answer in answers) {
              final type = answer['type'];
              final ip = answer['data']?.toString();
              // Type 1 corresponds to DNS A record (IPv4)
              if ((type == 1 || type == '1') &&
                  ip != null &&
                  InternetAddress.tryParse(ip) != null) {
                int ttl = 300;
                if (answer['TTL'] is int) {
                  ttl = answer['TTL'];
                } else if (answer['TTL'] != null) {
                  ttl = int.tryParse(answer['TTL'].toString()) ?? 300;
                }
                if (ttl < 60) ttl = 60;

                _cache[cacheKey] = DnsCacheEntry(
                  ip,
                  DateTime.now().add(Duration(seconds: ttl)),
                );
                return ip;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("DoH resolution error for $host ($provider): $e");
    }

    return null;
  }
}

class DohInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final dnsSetting = MiruStorage.getSetting(SettingKey.dns);
    if (dnsSetting != null &&
        dnsSetting != 'off' &&
        dnsSetting.toString().isNotEmpty) {
      final host = options.uri.host;
      if (host.isNotEmpty && InternetAddress.tryParse(host) == null) {
        final resolvedIp = await DnsResolver.resolve(
          host,
          providerKey: dnsSetting.toString(),
        );
        if (resolvedIp != null && resolvedIp.isNotEmpty) {
          final existingHost = options.headers['Host'] ?? options.headers['host'];
          if (existingHost == null) {
            final portStr = (options.uri.hasPort &&
                    options.uri.port != (options.uri.scheme == 'https' ? 443 : 80))
                ? ':${options.uri.port}'
                : '';
            options.headers['Host'] = '$host$portStr';
          }
          if (options.path.startsWith('http://') ||
              options.path.startsWith('https://')) {
            final uri = Uri.parse(options.path);
            options.path = uri.replace(host: resolvedIp).toString();
          } else if (options.baseUrl.startsWith('http://') ||
              options.baseUrl.startsWith('https://')) {
            final uri = Uri.parse(options.baseUrl);
            options.baseUrl = uri.replace(host: resolvedIp).toString();
          } else {
            final uri = options.uri;
            if (uri.hasAuthority) {
              options.path = uri.replace(host: resolvedIp).toString();
            }
          }
        }
      }
    }
    handler.next(options);
  }
}
