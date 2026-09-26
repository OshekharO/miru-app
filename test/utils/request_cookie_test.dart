import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cookie path and domain scoping test for setCookie logic', () async {
    final cookieJar = CookieJar();
    const detailUrl = "https://example.com/detail/12345";
    const apiUrl = "https://example.com/api/get_source";
    const rootUrl = "https://example.com/";

    const cookies = "cf_clearance=test_clearance_123; __cf_bm=test_bm_456";

    final uri = Uri.parse(detailUrl);
    final cookieList = cookies.split(';');
    for (final cookieStr in cookieList) {
      final trimmed = cookieStr.trim();
      if (trimmed.isEmpty) continue;
      final cookie = Cookie.fromSetCookieValue(trimmed);
      if (cookie.domain == null || cookie.domain!.isEmpty) {
        cookie.domain = uri.host;
      }
      if (cookie.path == null || cookie.path!.isEmpty) {
        cookie.path = "/";
      }
      await cookieJar.saveFromResponse(
        uri,
        [cookie],
      );
    }

    final apiCookies = await cookieJar.loadForRequest(Uri.parse(apiUrl));
    final apiCookieString = apiCookies.map((e) => e.toString()).join(';');
    expect(apiCookieString, contains("cf_clearance=test_clearance_123"));
    expect(apiCookieString, contains("__cf_bm=test_bm_456"));

    final rootCookies = await cookieJar.loadForRequest(Uri.parse(rootUrl));
    final rootCookieString = rootCookies.map((e) => e.toString()).join(';');
    expect(rootCookieString, contains("cf_clearance=test_clearance_123"));
    expect(rootCookieString, contains("__cf_bm=test_bm_456"));
  });
}
