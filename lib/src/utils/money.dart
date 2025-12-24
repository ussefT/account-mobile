import 'package:flutter/services.dart';

String formatMoneyCents(int cents, {String currencySymbol = '\$'}) {
  final isNegative = cents < 0;
  final abs = cents.abs();
  final major = abs ~/ 100;
  final minor = abs % 100;
  
  // Format major with thousand separators
  final formattedMajor = _formatWholeWithCommas(major.toString());
  
  String formatted;
  if (minor == 0) {
    formatted = '$currencySymbol$formattedMajor';
  } else {
    formatted = '$currencySymbol$formattedMajor.${minor.toString().padLeft(2, '0')}';
  }

  return isNegative ? '-$formatted' : formatted;
}

int parseMoneyToCents(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Amount is empty');
  }
  // Convert Persian digits to English digits for processing
  final normalized = _convertPersianToEnglishDigits(trimmed).replaceAll(',', '');
  final parts = normalized.split('.');
  if (parts.length > 2) throw const FormatException('Invalid amount');

  final wholePart = parts[0].isEmpty ? '0' : parts[0];
  final whole = int.parse(wholePart);

  var fraction = 0;
  if (parts.length == 2) {
    final fracRaw = parts[1];
    if (fracRaw.length > 2) throw const FormatException('Too many decimals');
    fraction = int.parse(fracRaw.padRight(2, '0'));
  }

  return whole * 100 + fraction;
}

/// Helper to convert Persian digits to English
String _convertPersianToEnglishDigits(String text) {
  const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  
  String result = text;
  for (int i = 0; i < englishDigits.length; i++) {
    result = result.replaceAll(persianDigits[i], englishDigits[i]);
  }
  return result;
}

class MoneyTextInputFormatter extends TextInputFormatter {
  const MoneyTextInputFormatter({this.maxDecimalDigits = 2});

  final int maxDecimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final input = newValue.text;
    final baseOffset = newValue.selection.baseOffset.clamp(0, input.length);

    final sanitized = StringBuffer();
    var sanitizedCursor = 0;
    var seenDot = false;

    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      final isDigit = c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
      final isDot = c == '.';

      var keep = false;
      if (isDigit) {
        keep = true;
      } else if (isDot && !seenDot) {
        keep = true;
        seenDot = true;
      }

      if (keep) {
        sanitized.write(c);
        if (i < baseOffset) sanitizedCursor++;
      }
    }

    final sanitizedText = sanitized.toString();
    final dotIndex = sanitizedText.indexOf('.');
    final hasDot = dotIndex != -1;
    final whole = hasDot ? sanitizedText.substring(0, dotIndex) : sanitizedText;
    var fraction = hasDot ? sanitizedText.substring(dotIndex + 1) : '';

    var cursor = sanitizedCursor;
    final wholeCursorIndex = cursor.clamp(0, whole.length);
    var fractionCursorIndex = 0;
    var cursorInDot = false;

    if (hasDot) {
      if (cursor == whole.length + 1) {
        cursorInDot = true;
      } else if (cursor > whole.length + 1) {
        fractionCursorIndex = (cursor - whole.length - 1).clamp(
          0,
          fraction.length,
        );
      }
    }

    if (fraction.length > maxDecimalDigits) {
      fraction = fraction.substring(0, maxDecimalDigits);
      fractionCursorIndex = fractionCursorIndex.clamp(0, fraction.length);
    }

    final formattedWhole = _formatWholeWithCommas(whole);
    final formattedWholeCursor = _mapWholeCursor(
      whole: whole,
      formattedWhole: formattedWhole,
      wholeCursorIndex: wholeCursorIndex,
    );

    final formattedText = StringBuffer()..write(formattedWhole);
    var formattedCursor = formattedWholeCursor;

    if (hasDot) {
      formattedText.write('.');
      if (fraction.isNotEmpty) formattedText.write(fraction);

      if (cursorInDot) {
        formattedCursor = formattedWhole.length;
      } else if (cursor > whole.length + 1) {
        formattedCursor = formattedWhole.length + 1 + fractionCursorIndex;
      } else if (cursor == whole.length + 1) {
        formattedCursor = formattedWhole.length;
      }
    }

    return TextEditingValue(
      text: formattedText.toString(),
      selection: TextSelection.collapsed(
        offset: formattedCursor.clamp(0, formattedText.length),
      ),
    );
  }
}

String _formatWholeWithCommas(String whole) {
  if (whole.isEmpty) return '';
  final digits = whole.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length <= 3) return digits;

  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final indexFromEnd = digits.length - i;
    b.write(digits[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      b.write(',');
    }
  }
  return b.toString();
}

int _mapWholeCursor({
  required String whole,
  required String formattedWhole,
  required int wholeCursorIndex,
}) {
  final digitsRight = (whole.length - wholeCursorIndex).clamp(0, whole.length);
  if (digitsRight == 0) return formattedWhole.length;
  if (whole.isEmpty) return 0;

  var digitsCounted = 0;
  for (var i = formattedWhole.length; i >= 0; i--) {
    if (digitsCounted == digitsRight) return i;
    if (i == 0) break;
    final c = formattedWhole[i - 1];
    final isDigit = c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
    if (isDigit) digitsCounted++;
  }
  return 0;
}
