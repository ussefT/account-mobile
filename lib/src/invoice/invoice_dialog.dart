import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../accounts/account_scope.dart';
import '../transactions/transaction_scope.dart';
import '../transactions/transaction_type.dart';
import '../auth/auth_scope.dart';
import '../settings/settings_scope.dart';
import '../localization/app_localizations.dart';
import 'invoice_service.dart';

class InvoiceDialog extends StatefulWidget {
  const InvoiceDialog({super.key});

  @override
  State<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<InvoiceDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedAccountId; // null means all
  TransactionType? _selectedType; // null means all

  @override
  Widget build(BuildContext context) {
    final accounts = AccountScope.of(context).accounts;
    final settings = SettingsScope.of(context);
    final isPersian = settings.locale?.languageCode == 'fa';
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.generateInvoice),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Selection
            DropdownButtonFormField<String?>(
              value: _selectedAccountId,
              decoration: InputDecoration(labelText: l10n.account),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.allAccounts)),
                ...accounts.map(
                  (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                ),
              ],
              onChanged: (v) => setState(() => _selectedAccountId = v),
            ),
            const SizedBox(height: 16),

            // Type Selection
            DropdownButtonFormField<TransactionType?>(
              value: _selectedType,
              decoration: InputDecoration(labelText: l10n.transactionType),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.all)),
                DropdownMenuItem(
                  value: TransactionType.income,
                  child: Text(l10n.income),
                ),
                DropdownMenuItem(
                  value: TransactionType.expense,
                  child: Text(l10n.expense),
                ),
              ],
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 16),

            // Date Range
            Text(l10n.dateRange, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                    child: Text(
                      _startDate == null
                          ? l10n.startDate
                          : DateFormat('yyyy/MM/dd').format(_startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                    child: Text(
                      _endDate == null
                          ? l10n.endDate
                          : DateFormat('yyyy/MM/dd').format(_endDate!),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () async {
            // Filter transactions
            final transactionsController = TransactionScope.of(context);
            final auth = AuthScope.of(context);

            var filtered = transactionsController.transactions;

            if (_selectedAccountId != null) {
              filtered = filtered
                  .where((t) => t.accountId == _selectedAccountId)
                  .toList();
            }

            if (_selectedType != null) {
              filtered = filtered
                  .where((t) => t.type == _selectedType)
                  .toList();
            }

            if (_startDate != null) {
              final start = DateTime(
                _startDate!.year,
                _startDate!.month,
                _startDate!.day,
              );
              filtered = filtered
                  .where((t) => !t.date.isBefore(start))
                  .toList();
            }

            if (_endDate != null) {
              final end = DateTime(
                _endDate!.year,
                _endDate!.month,
                _endDate!.day,
                23,
                59,
                59,
              );
              filtered = filtered.where((t) => !t.date.isAfter(end)).toList();
            }

            if (!context.mounted) return;
            Navigator.of(context).pop();

            // Save to file
            final fileName = 'invoice_${DateTime.now().toString().split(' ')[0]}.pdf';
            final result = await FilePicker.platform.saveFile(
              fileName: fileName,
              type: FileType.custom,
              allowedExtensions: const ['pdf'],
            );

            if (result != null && context.mounted) {
              try {
                final pdfBytes = await InvoiceService.generatePdf(
                  transactions: filtered,
                  userName: auth.username ?? 'User',
                  startDate: _startDate,
                  endDate: _endDate,
                  isPersian: isPersian,
                  l10n: l10n,
                );
                
                final file = File(result);
                await file.writeAsBytes(pdfBytes);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.save}: $result')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.couldNotSave}$e')),
                  );
                }
              }
            }
          },
          child: Text(l10n.save),
        ),
        FilledButton(
          onPressed: () async {
            // Filter transactions
            final transactionsController = TransactionScope.of(context);
            final auth = AuthScope.of(context);

            var filtered = transactionsController.transactions;

            if (_selectedAccountId != null) {
              filtered = filtered
                  .where((t) => t.accountId == _selectedAccountId)
                  .toList();
            }

            if (_selectedType != null) {
              filtered = filtered
                  .where((t) => t.type == _selectedType)
                  .toList();
            }

            if (_startDate != null) {
              final start = DateTime(
                _startDate!.year,
                _startDate!.month,
                _startDate!.day,
              );
              filtered = filtered
                  .where((t) => !t.date.isBefore(start))
                  .toList();
            }

            if (_endDate != null) {
              final end = DateTime(
                _endDate!.year,
                _endDate!.month,
                _endDate!.day,
                23,
                59,
                59,
              );
              filtered = filtered.where((t) => !t.date.isAfter(end)).toList();
            }

            if (!context.mounted) return;
            Navigator.of(context).pop();

            await InvoiceService.generateAndPrint(
              transactions: filtered,
              userName: auth.username ?? 'User',
              startDate: _startDate,
              endDate: _endDate,
              isPersian: isPersian,
              l10n: l10n,
            );
          },
          child: Text(l10n.generatePdf),
        ),
      ],
    );
  }
}
