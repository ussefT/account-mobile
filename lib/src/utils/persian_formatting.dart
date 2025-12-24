import 'package:shamsi_date/shamsi_date.dart';

/// Format currency amount with Persian currency symbol (ریال)
String formatMoneyPersian(int cents) {
  final isNegative = cents < 0;
  final abs = cents.abs();
  final major = abs ~/ 100;
  
  // Format with thousand separators
  final formattedMajor = _formatNumberWithCommas(major.toString());
  final formatted = '$formattedMajor ریال';
  
  return isNegative ? '-$formatted' : formatted;
}

/// Format balance with thousand separators (e.g., 1,234,567)
String formatBalanceWithSeparators(int cents) {
  final isNegative = cents < 0;
  final abs = cents.abs();
  final major = abs ~/ 100;
  
  final formatted = _formatNumberWithCommas(major.toString());
  
  return isNegative ? '-$formatted' : formatted;
}

/// Format card number in groups of 4 (e.g., 1234 5678 9012 3456)
String formatCardNumber(String? number) {
  if (number == null || number.isEmpty) return '';
  
  // Remove any existing spaces
  final cleaned = number.replaceAll(RegExp(r'\s+'), '');
  
  // Add spaces every 4 digits
  final buffer = StringBuffer();
  for (int i = 0; i < cleaned.length; i++) {
    if (i > 0 && i % 4 == 0) {
      buffer.write(' ');
    }
    buffer.write(cleaned[i]);
  }
  
  return buffer.toString();
}

/// Helper function to add thousand separators
String _formatNumberWithCommas(String number) {
  final buffer = StringBuffer();
  final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
  
  for (int i = 0; i < digits.length; i++) {
    final indexFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  
  return buffer.toString();
}

/// Convert Gregorian date to Shamsi (Persian/Jalali) date
/// Returns formatted string like: 1403/05/15
String formatDatePersian(DateTime date) {
  try {
    final shamsi = Jalali.fromDateTime(date);
    final year = shamsi.year.toString().padLeft(4, '0');
    final month = shamsi.month.toString().padLeft(2, '0');
    final day = shamsi.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  } catch (e) {
    // Fallback to gregorian if conversion fails
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }
}

/// Convert Gregorian date to Shamsi with Persian month name
/// Returns formatted string like: 15 اردیبهشت 1403
String formatDatePersianVerbose(DateTime date) {
  try {
    final shamsi = Jalali.fromDateTime(date);
    final monthName = _getPersianMonthName(shamsi.month);
    return '${shamsi.day} $monthName ${shamsi.year}';
  } catch (e) {
    return formatDatePersian(date);
  }
}

/// Format time in Persian format (HH:MM)
String formatTimePersian(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Format date and time in Persian
String formatDateTimePersian(DateTime dateTime) {
  return '${formatDatePersian(dateTime)} ${formatTimePersian(dateTime)}';
}

/// Get Persian month name
String _getPersianMonthName(int month) {
  const monthNames = [
    'فروردین',   // 1
    'اردیبهشت',  // 2
    'خرداد',     // 3
    'تیر',       // 4
    'مرداد',     // 5
    'شهریور',    // 6
    'مهر',       // 7
    'آبان',      // 8
    'آذر',       // 9
    'دی',        // 10
    'بهمن',      // 11
    'اسفند',     // 12
  ];
  
  if (month < 1 || month > 12) return '';
  return monthNames[month - 1];
}

/// Convert English numbers to Persian digits
String convertToPersianNumbers(String text) {
  const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  
  String result = text;
  for (int i = 0; i < englishDigits.length; i++) {
    result = result.replaceAll(englishDigits[i], persianDigits[i]);
  }
  return result;
}

/// Convert Persian digits to English digits for processing
String convertFromPersianNumbers(String text) {
  const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  
  String result = text;
  for (int i = 0; i < englishDigits.length; i++) {
    result = result.replaceAll(persianDigits[i], englishDigits[i]);
  }
  return result;
}

/// Convert number to Persian words
/// Examples: 20 -> بیست, 123 -> یکصد و بیست و سه
String numberToPersianWords(int number) {
  if (number == 0) return 'صفر';
  
  const ones = [
    '',
    'یک',
    'دو',
    'سه',
    'چهار',
    'پنج',
    'شش',
    'هفت',
    'هشت',
    'نه'
  ];
  const tens = [
    '',
    '',
    'بیست',
    'سی',
    'چهل',
    'پنجاه',
    'شصت',
    'هفتاد',
    'هشتاد',
    'نود'
  ];
  const teens = [
    'ده',
    'یازده',
    'دوازده',
    'سیزده',
    'چهارده',
    'پانزده',
    'شانزده',
    'هفده',
    'هجده',
    'نوزده'
  ];

  if (number < 0) {
    return 'منفی ${numberToPersianWords(-number)}';
  }

  if (number < 10) {
    return ones[number];
  }

  if (number < 20) {
    return teens[number - 10];
  }

  if (number < 100) {
    final ten = number ~/ 10;
    final one = number % 10;
    if (one == 0) return tens[ten];
    return '${tens[ten]} و ${ones[one]}';
  }

  if (number < 1000) {
    final hundred = number ~/ 100;
    final remainder = number % 100;
    final result = remainder == 0
        ? '${ones[hundred]}صد'
        : '${ones[hundred]}صد و ${numberToPersianWords(remainder)}';
    return result;
  }

  if (number < 1000000) {
    final thousand = number ~/ 1000;
    final remainder = number % 1000;
    final result = remainder == 0
        ? '${numberToPersianWords(thousand)} هزار'
        : '${numberToPersianWords(thousand)} هزار و ${numberToPersianWords(remainder)}';
    return result;
  }

  if (number < 1000000000) {
    final million = number ~/ 1000000;
    final remainder = number % 1000000;
    final result = remainder == 0
        ? '${numberToPersianWords(million)} میلیون'
        : '${numberToPersianWords(million)} میلیون و ${numberToPersianWords(remainder)}';
    return result;
  }

  return number.toString();
}
