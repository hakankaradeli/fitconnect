import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Sadece rakamları al
    text = text.replaceAll(RegExp(r'\D'), '');

    // Maksimum 10 hane (başındaki 0'ı temizle eğer varsa)
    if (text.startsWith('0')) {
      text = text.substring(1);
    }
    
    if (text.length > 10) {
      text = text.substring(0, 10);
    }

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      formatted += text[i];
      // Format: 123 456 78 90
      if ((i == 2 || i == 5 || i == 7) && i != text.length - 1) {
        formatted += ' ';
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
