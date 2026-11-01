import 'package:flutter/services.dart';

String formatPhoneNumber(String? phone) {
  if (phone == null || phone.trim().isEmpty) {
    return "Telefon yok";
  }

  String digits = phone.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('90')) {
    digits = digits.substring(2);
  }
  if (digits.startsWith('0')) {
    digits = digits.substring(1);
  }

  if (digits.length > 10) {
    digits = digits.substring(0, 10);
  }

  if (digits.length == 10) {
    String part1 = digits.substring(0, 3);
    String part2 = digits.substring(3, 6);
    String part3 = digits.substring(6, 8);
    String part4 = digits.substring(8, 10);
    return "+90 $part1 $part2 $part3 $part4";
  }

  if (digits.isNotEmpty) {
    return "+90 $digits";
  }

  return phone;
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    String digits = text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('90')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    String formatted = '+90 ';
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6 || i == 8) {
        formatted += ' ';
      }
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
