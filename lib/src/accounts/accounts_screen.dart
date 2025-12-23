import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../transactions/transaction_scope.dart';
import '../utils/money.dart';
import '../utils/persian_formatting.dart';
import 'account_form_screen.dart';
import 'account_scope.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accounts = AccountScope.of(context);
    final transactions = TransactionScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank cards'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AccountFormScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_card_outlined),
            tooltip: 'Add',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: accounts.accounts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final a = accounts.accounts[index];
            final selected = a.id == accounts.selectedAccountId;
            final balance = transactions.balanceCentsForAccount(
              a.id,
              initialBalanceCents: a.initialBalanceCents,
            );
            return Card(
              child: ListTile(
                leading: selected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.credit_card_outlined),
                title: Text(a.name),
                subtitle: Text(
                  [
                    if (a.number != null && a.number!.isNotEmpty)
                      formatCardNumber(a.number),
                    l10n.locale.languageCode == 'fa'
                        ? formatMoneyPersian(balance)
                        : formatMoneyCents(balance),
                  ].join(' • '),
                ),
                onTap: () {
                  accounts.selectAccount(a.id);
                  Navigator.of(context).pop();
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AccountFormScreen(initial: a),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: accounts.accounts.length <= 1
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete card?'),
                                  content: const Text(
                                    'Transactions in this card will be deleted.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(l10n.cancel),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(l10n.delete),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true) return;
                              await accounts.deleteAccount(a.id);
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


