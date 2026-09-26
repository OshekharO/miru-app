import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cookie path and domain scoping test for setCookie logic', () async {
    final cookieJar = CookieJar();
    const detailUrl = "https://sub.example.com/detail/12345";
    const apiUrl = "https://sub.example.com/api/get_source";
    const rootUrl = "https://example.com/";
    const otherSubUrl = "https://api.example.com/data";

    const cookies = "cf_clearance=test_clearance_123; __cf_bm=test_bm_456";

    final uri = Uri.parse(detailUrl);
    final cookieList = cookies.split(';');
    final hostParts = uri.host.split('.');
    final rootDomain = hostParts.length >= 2
        ? hostParts.sublist(hostParts.length - 2).join('.')
        : uri.host;
    final rootDomainUri = Uri.parse('${uri.scheme}://$rootDomain');

    for (final cookieStr in cookieList) {
      final trimmed = cookieStr.trim();
      if (trimmed.isEmpty) continue;
      final cookie = Cookie.fromSetCookieValue(trimmed);
      cookie.domain = rootDomain;
      cookie.path = "/";
      await cookieJar.saveFromResponse(
        rootDomainUri,
        [cookie],
      );
    }

    final apiCookies = await cookieJar.loadForRequest(Uri.parse(apiUrl));
    expect(apiCookies.map((e) => e.toString()).join(';'), contains("cf_clearance=test_clearance_123"));

    final rootCookies = await cookieJar.loadForRequest(Uri.parse(rootUrl));
    expect(rootCookies.map((e) => e.toString()).join(';'), contains("cf_clearance=test_clearance_123"));

    final otherSubCookies = await cookieJar.loadForRequest(Uri.parse(otherSubUrl));
    expect(otherSubCookies.map((e) => e.toString()).join(';'), contains("cf_clearance=test_clearance_123"));
  });
}
