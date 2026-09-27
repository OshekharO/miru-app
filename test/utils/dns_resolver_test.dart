import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:miru_app/utils/dns_resolver.dart';
import 'package:miru_app/utils/miru_storage.dart';

void main() {
  late Directory tempDir;
  bool isInitialized = false;

  setUp(() async {
    if (!isInitialized) {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      MiruStorage.settings = await Hive.openBox('settings');
      isInitialized = true;
    }
    DnsResolver.clearCache();
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('DnsResolver resolves host correctly for IP address', () async {
    await MiruStorage.setSetting(SettingKey.dns, 'cloudflare');

    final ip = await DnsResolver.resolve('127.0.0.1');
    expect(ip, '127.0.0.1');
  });

  test('DnsResolver returns null when DNS is off', () async {
    await MiruStorage.setSetting(SettingKey.dns, 'off');

    final ip = await DnsResolver.resolve('example.com');
    expect(ip, isNull);
  });

  test('DohInterceptor modifies request options when host is resolved', () async {
    await MiruStorage.setSetting(SettingKey.dns, 'cloudflare');

    final interceptor = DohInterceptor();

    // 1. IP host: path and Host header should remain unchanged
    final optionsIp = RequestOptions(
      path: 'https://1.1.1.1/dns-query',
    );
    final handlerIp = RequestInterceptorHandler();
    interceptor.onRequest(optionsIp, handlerIp);

    expect(optionsIp.path, 'https://1.1.1.1/dns-query');
    expect(optionsIp.headers['Host'], isNull);

    // 2. Domain host when DNS setting is off
    await MiruStorage.setSetting(SettingKey.dns, 'off');
    final optionsDomainOff = RequestOptions(
      path: 'https://example.com/test',
    );
    final handlerDomainOff = RequestInterceptorHandler();
    interceptor.onRequest(optionsDomainOff, handlerDomainOff);

    expect(optionsDomainOff.path, 'https://example.com/test');
    expect(optionsDomainOff.headers['Host'], isNull);
  });
}
