import 'package:flutter/material.dart';

import '../accounts/account_scope.dart';
import '../localization/app_localizations.dart';
import '../utils/money.dart';
import '../utils/persian_formatting.dart';
import 'transaction_form_screen.dart';
import 'transaction_scope.dart';
import 'transaction_type.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = TransactionScope.of(context);
    final accounts = AccountScope.of(context);
    final tx = controller.findById(transactionId);
    if (tx == null) {
      return const Scaffold(body: Center(child: Text('Transaction not found')));
    }

    final amount = l10n.locale.languageCode == 'fa'
        ? formatMoneyPersian(tx.amountCents)
        : formatMoneyCents(
            tx.amountCents,
            currencySymbol: l10n.currencySymbol,
          );
    final amountText = tx.type == TransactionType.expense
        ? '-$amount'
        : '+$amount';
    final amountColor = tx.type == TransactionType.expense
        ? Colors.red
        : Colors.green;
    String? accountName;
    for (final a in accounts.accounts) {
      if (a.id == tx.accountId) {
        accountName = a.name;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionDetails),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransactionFormScreen(initial: tx),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.edit,
          ),
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.delete),
                  content: Text(
                    l10n.deleteAccountConfirm,
                  ), // Reusing generic confirmation or add new key
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await controller.deleteById(tx.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.delete,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amountText,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: amountColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tx.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (tx.note != null && tx.note!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.note,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.note!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _DetailRow(
                      label: l10n.date,
                      value: l10n.locale.languageCode == 'fa'
                          ? formatDatePersian(tx.date)
                          : tx.date.toString().split(' ').first,
                    ),
                    if (accountName != null)
                      _DetailRow(label: l10n.account, value: accountName),
                    _DetailRow(label: l10n.category, value: tx.category),
                    if (tx.relatedPerson != null)
                      _DetailRow(
                        label: l10n.relatedPerson,
                        value: tx.relatedPerson!,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${tx.id}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
