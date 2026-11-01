import 'package:intl/intl.dart';

String formatCurrency(dynamic amount) {
  if (amount == null) return "0,00 ₺";
  final double numValue = double.tryParse(amount.toString()) ?? 0.0;
  final formatter = NumberFormat("#,##0.00", "tr_TR");
  return "${formatter.format(numValue)} ₺";
}
