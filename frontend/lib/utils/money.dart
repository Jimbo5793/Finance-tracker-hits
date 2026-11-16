import 'package:intl/intl.dart';

final NumberFormat _amountFormat = NumberFormat('#,##0.00', 'en_US');
const String _minus = '−'; // the real minus sign, as in the design

/// 1250000.5 -> "1,250,000.50", -30 -> "−30.00"
String formatBalance(double value) {
  final v = value == 0 ? 0.0 : value; // avoids "-0.00"
  return v < 0 ? '$_minus${_amountFormat.format(-v)}' : _amountFormat.format(v);
}

/// "+200.00" or "−62.40". Zero has no sign.
String formatSigned(double value) {
  if (value > 0) return '+${_amountFormat.format(value)}';
  if (value < 0) return '$_minus${_amountFormat.format(-value)}';
  return _amountFormat.format(0);
}
