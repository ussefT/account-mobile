import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

import '../transactions/account_transaction.dart';
import '../transactions/transaction_type.dart';
import '../utils/money.dart';
import '../utils/persian_formatting.dart';
import '../localization/app_localizations.dart';

class InvoiceService {
  static Future<Uint8List> generatePdf({
    required List<AccountTransaction> transactions,
    required String userName,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isPersian,
    required AppLocalizations l10n,
  }) async {
    final pdf = pw.Document();

    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.vazirmatnRegular();
      boldFont = await PdfGoogleFonts.vazirmatnBold();
    } catch (e) {
      font = pw.Font.courier();
      boldFont = pw.Font.courierBold();
    }

    final dateFormat = isPersian
        ? DateFormat('yyyy/MM/dd', 'fa')
        : DateFormat('yyyy/MM/dd', 'en');

    pdf.addPage(
      pw.MultiPage(
        textDirection: isPersian ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          _buildHeader(
            context,
            userName,
            startDate,
            endDate,
            dateFormat,
            isPersian,
            l10n,
          ),
          pw.SizedBox(height: 20),
          _buildTable(context, transactions, dateFormat, isPersian, l10n),
          pw.SizedBox(height: 20),
          _buildSummary(context, transactions, isPersian, l10n),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<void> generateAndPrint({
    required List<AccountTransaction> transactions,
    required String userName,
    required DateTime? startDate,
    required DateTime? endDate,
    required bool isPersian,
    required AppLocalizations l10n,
  }) async {
    final pdfBytes = await generatePdf(
      transactions: transactions,
      userName: userName,
      startDate: startDate,
      endDate: endDate,
      isPersian: isPersian,
      l10n: l10n,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _buildHeader(
    pw.Context context,
    String userName,
    DateTime? startDate,
    DateTime? endDate,
    DateFormat dateFormat,
    bool isPersian,
    AppLocalizations l10n,
  ) {
    final title = isPersian ? 'صورت‌حساب' : 'Invoice';
    final userLabel = isPersian ? 'کاربر:' : 'User:';
    final dateLabel = isPersian ? 'تاریخ گزارش:' : 'Report Date:';
    final periodLabel = isPersian ? 'دوره:' : 'Period:';

    String periodText;
    if (startDate != null && endDate != null) {
      periodText =
          '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
    } else if (startDate != null) {
      periodText =
          '${isPersian ? "از" : "From"} ${dateFormat.format(startDate)}';
    } else if (endDate != null) {
      periodText = '${isPersian ? "تا" : "To"} ${dateFormat.format(endDate)}';
    } else {
      periodText = isPersian ? 'همه تراکنش‌ها' : 'All Transactions';
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('$userLabel $userName'),
                pw.Text('$dateLabel ${dateFormat.format(DateTime.now())}'),
                pw.Text('$periodLabel $periodText'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTable(
    pw.Context context,
    List<AccountTransaction> transactions,
    DateFormat dateFormat,
    bool isPersian,
    AppLocalizations l10n,
  ) {
    final headers = isPersian
        ? ['تاریخ', 'عنوان', 'دسته‌بندی', 'مبلغ', 'نوع']
        : ['Date', 'Title', 'Category', 'Amount', 'Type'];

    final data = transactions.map((t) {
      final amount = isPersian
          ? formatMoneyPersian(t.amountCents)
          : formatMoneyCents(t.amountCents);
      final type = t.type == TransactionType.income
          ? (isPersian ? 'درآمد' : 'Income')
          : (isPersian ? 'هزینه' : 'Expense');

      return [dateFormat.format(t.date), t.title, t.category, amount, type];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.center,
      },
    );
  }

  static pw.Widget _buildSummary(
    pw.Context context,
    List<AccountTransaction> transactions,
    bool isPersian,
    AppLocalizations l10n,
  ) {
    int totalIncome = 0;
    int totalExpense = 0;

    for (var t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amountCents;
      } else {
        totalExpense += t.amountCents;
      }
    }

    final balance = totalIncome - totalExpense;

    final incomeLabel = isPersian ? 'مجموع درآمد:' : 'Total Income:';
    final expenseLabel = isPersian ? 'مجموع هزینه:' : 'Total Expense:';
    final balanceLabel = isPersian ? 'تراز:' : 'Balance:';

    final incomeText = isPersian
        ? formatMoneyPersian(totalIncome)
        : formatMoneyCents(totalIncome);
    final expenseText = isPersian
        ? formatMoneyPersian(totalExpense)
        : formatMoneyCents(totalExpense);
    final balanceText = isPersian
        ? formatMoneyPersian(balance)
        : formatMoneyCents(balance);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          '$incomeLabel $incomeText',
          style: const pw.TextStyle(color: PdfColors.green),
        ),
        pw.Text(
          '$expenseLabel $expenseText',
          style: const pw.TextStyle(color: PdfColors.red),
        ),
        pw.Divider(),
        pw.Text(
          '$balanceLabel $balanceText',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
