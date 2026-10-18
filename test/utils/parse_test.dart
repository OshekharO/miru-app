import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Safe Parsing Fallbacks', () {
    test('int.tryParse handles valid and invalid inputs gracefully', () {
      expect(int.tryParse('123') ?? 0, equals(123));
      expect(int.tryParse('invalid') ?? 0, equals(0));
      expect(int.tryParse('') ?? 0, equals(0));
    });

    test('double.tryParse handles valid and invalid inputs gracefully', () {
      expect(double.tryParse('12.34') ?? 0.0, equals(12.34));
      expect(double.tryParse('abc') ?? 0.0, equals(0.0));
      expect(double.tryParse('') ?? 0.0, equals(0.0));
    });
  });
}
