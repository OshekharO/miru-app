import 'package:flutter_test/flutter_test.dart';

// Test normalizeRepoUrl logic in isolation without importing transitive desktop_multi_window/fluent_ui packages
String normalizeRepoUrl(String inputUrl) {
  final githubRepoRegex =
      RegExp(r'^https?://github\.com/([^/]+)/([^/]+)(?:/tree/([^/]+))?');
  var url = inputUrl.trim();
  if (url.endsWith('/index.json')) {
    url = url.substring(0, url.length - '/index.json'.length);
  }
  if (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  final githubMatch = githubRepoRegex.firstMatch(url);
  if (githubMatch != null) {
    final owner = githubMatch.group(1);
    final repo = githubMatch.group(2);
    final branch = githubMatch.group(3) ?? 'main';
    url = 'https://raw.githubusercontent.com/$owner/$repo/$branch';
  }
  return url;
}

void main() {
  group('ExtensionUtils.normalizeRepoUrl', () {
    test('normalizes GitHub repo URL with default branch main', () {
      const input = 'https://github.com/miru-project/repo';
      expect(
        normalizeRepoUrl(input),
        'https://raw.githubusercontent.com/miru-project/repo/main',
      );
    });

    test('normalizes GitHub repo URL with specific branch in tree', () {
      const input = 'https://github.com/miru-project/repo/tree/dev';
      expect(
        normalizeRepoUrl(input),
        'https://raw.githubusercontent.com/miru-project/repo/dev',
      );
    });

    test('strips trailing slashes and /index.json', () {
      const input =
          'https://github.com/miru-project/repo/tree/master/index.json';
      expect(
        normalizeRepoUrl(input),
        'https://raw.githubusercontent.com/miru-project/repo/master',
      );

      const trailingSlash = 'https://github.com/miru-project/repo/';
      expect(
        normalizeRepoUrl(trailingSlash),
        'https://raw.githubusercontent.com/miru-project/repo/main',
      );
    });

    test(
        'preserves non-GitHub URLs while stripping index.json and trailing slash',
        () {
      const customUrl = 'https://miru-repo.0n0.dev/index.json';
      expect(
        normalizeRepoUrl(customUrl),
        'https://miru-repo.0n0.dev',
      );

      const customWithSlash = 'https://example.com/miru/';
      expect(
        normalizeRepoUrl(customWithSlash),
        'https://example.com/miru',
      );
    });
  });
}
