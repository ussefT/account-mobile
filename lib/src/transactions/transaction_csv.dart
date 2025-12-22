import 'account_transaction.dart';
import 'transaction_type.dart';

String exportTransactionsCsv(List<AccountTransaction> items) {
  final b = StringBuffer();
  b.writeln(
    'id,account_id,title,amount_cents,type,category,date_iso,created_by,note,related_person',
  );
  for (final t in items) {
    b.writeln(
      [
        t.id,
        t.accountId,
        t.title,
        t.amountCents.toString(),
        t.type.name,
        t.category,
        t.date.toIso8601String(),
        t.createdBy ?? '',
        t.note ?? '',
        t.relatedPerson ?? '',
      ].map(_csvField).join(','),
    );
  }
  return b.toString();
}

List<AccountTransaction> importTransactionsCsv(String csvText) {
  final rows = _parseCsv(csvText);
  if (rows.isEmpty) return const [];

  final hasHeader = rows.first.isNotEmpty && rows.first.first == 'id';
  final headerIndex = <String, int>{};
  if (hasHeader) {
    for (var i = 0; i < rows.first.length; i++) {
      headerIndex[rows.first[i]] = i;
    }
  }
  final startIndex = hasHeader ? 1 : 0;

  final items = <AccountTransaction>[];
  for (var i = startIndex; i < rows.length; i++) {
    final row = rows[i];
    if (row.where((e) => e.trim().isNotEmpty).isEmpty) continue;
    if (row.length < 6) {
      throw FormatException('Invalid CSV row at line ${i + 1}');
    }
    final id = _csvValue(row, headerIndex, 'id', fallbackIndex: 0).trim();

    final hasAccountIdColumn = hasHeader
        ? headerIndex.containsKey('account_id')
        : rows.first.isNotEmpty &&
              rows.first.length > 1 &&
              rows.first[1] == 'account_id';

    final accountId = hasAccountIdColumn
        ? _csvValue(row, headerIndex, 'account_id', fallbackIndex: 1).trim()
        : 'default';
    final title = _csvValue(
      row,
      headerIndex,
      'title',
      fallbackIndex: hasAccountIdColumn ? 2 : 1,
    ).trim();
    final amountCents = int.parse(
      _csvValue(
        row,
        headerIndex,
        'amount_cents',
        fallbackIndex: hasAccountIdColumn ? 3 : 2,
      ).trim(),
    );
    final type = TransactionType.values.byName(
      _csvValue(
        row,
        headerIndex,
        'type',
        fallbackIndex: hasAccountIdColumn ? 4 : 3,
      ).trim(),
    );
    final category = _csvValue(
      row,
      headerIndex,
      'category',
      fallbackIndex: hasAccountIdColumn ? 5 : 4,
    ).trim();
    final date = DateTime.parse(
      _csvValue(
        row,
        headerIndex,
        'date_iso',
        fallbackIndex: hasAccountIdColumn ? 6 : 5,
      ).trim(),
    );

    final createdByRaw = hasHeader
        ? _csvValue(row, headerIndex, 'created_by').trim()
        : '';
    final createdBy = createdByRaw.isEmpty ? null : createdByRaw;

    final noteRaw = hasHeader
        ? _csvValue(row, headerIndex, 'note').trim()
        : _csvValue(
            row,
            headerIndex,
            'note',
            fallbackIndex: hasAccountIdColumn ? 7 : 6,
          ).trim();
    final note = noteRaw.isEmpty ? null : noteRaw;

    final relatedRaw = hasHeader
        ? _csvValue(row, headerIndex, 'related_person').trim()
        : _csvValue(
            row,
            headerIndex,
            'related_person',
            fallbackIndex: hasAccountIdColumn ? 8 : 7,
          ).trim();
    final relatedPerson = relatedRaw.isEmpty ? null : relatedRaw;

    items.add(
      AccountTransaction(
        id: id,
        accountId: accountId.isEmpty ? 'default' : accountId,
        title: title,
        amountCents: amountCents,
        type: type,
        category: category,
        date: DateTime(date.year, date.month, date.day),
        createdBy: createdBy,
        note: note,
        relatedPerson: relatedPerson,
      ),
    );
  }
  return items;
}

String _csvValue(
  List<String> row,
  Map<String, int> headerIndex,
  String name, {
  int? fallbackIndex,
}) {
  final idx = headerIndex[name] ?? fallbackIndex;
  if (idx == null || idx < 0 || idx >= row.length) return '';
  return row[idx];
}

String _csvField(String value) {
  final needsQuotes =
      value.contains(',') || value.contains('"') || value.contains('\n');
  if (!needsQuotes) return value;
  final escaped = value.replaceAll('"', '""');
  return '"$escaped"';
}

List<List<String>> _parseCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    if (inQuotes) {
      if (c == '"') {
        final nextIsQuote = i + 1 < input.length && input[i + 1] == '"';
        if (nextIsQuote) {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
      continue;
    }

    if (c == '"') {
      inQuotes = true;
      continue;
    }
    if (c == ',') {
      endField();
      continue;
    }
    if (c == '\n') {
      endRow();
      continue;
    }
    if (c == '\r') {
      continue;
    }
    field.write(c);
  }

  if (inQuotes) {
    throw const FormatException('Unterminated quoted CSV field');
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    endRow();
  }
  return rows;
}
