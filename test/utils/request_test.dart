import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dio configured options have proper timeouts set', () {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    final options = dio.options;
    expect(options.connectTimeout, equals(const Duration(seconds: 15)));
    expect(options.receiveTimeout, equals(const Duration(seconds: 15)));
    expect(options.sendTimeout, equals(const Duration(seconds: 15)));
  });
}
