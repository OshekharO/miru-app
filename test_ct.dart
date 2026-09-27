
import 'dart:io';

void main() async {
  final client = HttpClient();
  client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
    final Future<ConnectionTask<SecureSocket>> res = SecureSocket.startConnect('1.1.1.1', 443);
    return res;
  };
}
