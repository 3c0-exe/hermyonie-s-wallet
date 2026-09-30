/// Preserve the legacy Hive fields while doing every calculation in centavos.
class Money {
  static int cents(double value) {
    if (!value.isFinite || value.abs() > 1000000000) {
      throw const FormatException('Enter a valid amount below ₱1 billion.');
    }
    return (value * 100).round();
  }

  static double normalize(double value) => cents(value) / 100;
  static double add(double a, double b) => (cents(a) + cents(b)) / 100;
  static double sum(Iterable<double> values) =>
      values.fold<int>(0, (sum, value) => sum + cents(value)) / 100;
  static double positive(double value) {
    final amount = normalize(value);
    if (amount <= 0) {
      throw const FormatException('Amount must be greater than zero.');
    }
    return amount;
  }

  static double? parse(String text) {
    final value = double.tryParse(
      text.replaceAll(',', '').replaceAll('₱', '').trim(),
    );
    if (value == null || !value.isFinite || value.abs() > 1000000000) {
      return null;
    }
    return normalize(value);
  }
}
