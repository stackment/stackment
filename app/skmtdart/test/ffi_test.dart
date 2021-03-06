import 'package:flutter_test/flutter_test.dart';

import 'package:skmtdart/skmtdart.dart';

void main() {
  test('adds one to input values', () {
    final calculator = Calculator();
    expect(calculator.addfunc(1, 1), 2);
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
  });
}
