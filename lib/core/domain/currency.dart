import 'dart:math' as math;

class Currency {
  final String code;
  final int digits;

  const Currency(this.code, this.digits);

  static const supported = [
    Currency('KZT', 2),
    Currency('USD', 2),
    Currency('EUR', 2),
  ];

  static Currency get(String code) =>
      supported.firstWhere((c) => c.code == code);

  int parse(String input) {
    final value = input.trim();
    final pattern = digits == 0
        ? r'^\d+$'
        : r'^\d+(\.\d{1,'
              '$digits'
              r'})?$';
    if (!RegExp(pattern).hasMatch(value)) {
      throw FormatException(
        'Enter a positive amount with up to $digits decimals',
      );
    }
    final parts = value.split('.');
    final minor =
        int.parse(parts[0]) * math.pow(10, digits).toInt() +
        (digits == 0
            ? 0
            : int.parse(
                (parts.length == 2 ? parts[1] : '').padRight(digits, '0'),
              ));
    if (minor <= 0 || minor > 999999999999) {
      throw const FormatException(
        'Amount must be between 0.01 and 9,999,999,999.99',
      );
    }
    return minor;
  }

  double major(int minor) => minor / math.pow(10, digits);
}
