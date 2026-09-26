import 'package:flutter_test/flutter_test.dart';
import 'package:miru_app/utils/dns_resolver.dart';
import 'package:miru_app/utils/miru_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DnsProvider Enum', () {
    test('fromString parses providers correctly', () {
      expect(DnsProvider.fromString('cloudflare'), DnsProvider.cloudflare);
      expect(DnsProvider.fromString('Google'), DnsProvider.google);
      expect(DnsProvider.fromString('ADGUARD'), DnsProvider.adguard);
      expect(DnsProvider.fromString('quad9'), DnsProvider.quad9);
      expect(DnsProvider.fromString('off'), DnsProvider.off);
      expect(DnsProvider.fromString(null), DnsProvider.off);
      expect(DnsProvider.fromString('invalid'), DnsProvider.off);
    });

    test('toValue returns correct string representation', () {
      expect(DnsProvider.cloudflare.toValue(), 'cloudflare');
      expect(DnsProvider.google.toValue(), 'google');
      expect(DnsProvider.adguard.toValue(), 'adguard');
      expect(DnsProvider.quad9.toValue(), 'quad9');
      expect(DnsProvider.off.toValue(), 'off');
    });
  });

  group('DnsResolver', () {
    setUp(() {
      DnsResolver.clearCache();
    });

    test('resolve returns host directly when host is empty or IP address', () async {
      expect(await DnsResolver.resolve(''), '');
      expect(await DnsResolver.resolve('127.0.0.1'), '127.0.0.1');
      expect(await DnsResolver.resolve('::1'), '::1');
    });

    test('resolve returns original host when provider is off or disabled', () async {
      expect(await DnsResolver.resolve('example.com'), 'example.com');
    });

    test('SettingKey.dns is defined', () {
      expect(SettingKey.dns, 'DNS');
    });
  });
}
