import 'package:flutter/material.dart';

import '../accounts/account_scope.dart';
import '../utils/money.dart';
import 'transaction_form_screen.dart';
import 'transaction_scope.dart';
import 'transaction_type.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context) {
    final controller = TransactionScope.of(context);
    final accounts = AccountScope.of(context);
    final tx = controller.findById(transactionId);
    if (tx == null) {
      return const Scaffold(body: Center(child: Text('Transaction not found')));
    }

    final amount = formatMoneyCents(tx.amountCents);
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
        title: const Text('Transaction'),
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
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete transaction?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await controller.deleteById(tx.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (accountName != null) Chip(label: Text(accountName)),
                        Chip(label: Text(tx.type.name)),
                        Chip(label: Text(tx.category)),
                        Chip(label: Text(_formatDate(tx.date))),
                        if (tx.createdBy != null)
                          Chip(label: Text('By ${tx.createdBy!}')),
                        if (tx.relatedPerson != null)
                          Chip(label: Text(tx.relatedPerson!)),
                      ],
                    ),
                    if (tx.note != null) ...[
                      const SizedBox(height: 12),
                      Text(tx.note!),
                    ],
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

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
