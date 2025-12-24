import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../settings/settings_scope.dart';
import '../transactions/transaction_scope.dart';
import '../utils/money.dart';
import '../utils/persian_formatting.dart';
import 'account_controller.dart';
import 'account_form_screen.dart';
import 'account_scope.dart';
import 'bank_account.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  Future<void> _editBalance(
    BuildContext context,
    AccountController accounts,
    BankAccount account,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: (account.initialBalanceCents / 100).toStringAsFixed(2),
    );
    
    final newBalance = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editBalance),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.initialBalance,
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [MoneyTextInputFormatter()],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              try {
                final cents = parseMoneyToCents(controller.text);
                Navigator.of(context).pop(cents);
              } catch (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.enterValidAmount)),
                );
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    
    if (newBalance != null) {
      await accounts.updateAccount(
        account.copyWith(initialBalanceCents: newBalance),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = AccountScope.of(context);
    final transactions = TransactionScope.of(context);
    final settings = SettingsScope.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bankCards),
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
            tooltip: l10n.add,
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
            
            final listItem = Card(
              child: ListTile(
                leading: selected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.credit_card_outlined),
                title: Text(a.name),
                subtitle: GestureDetector(
                  onTap: () => _editBalance(context, accounts, a),
                  child: Text(
                    [
                      if (a.number != null && a.number!.isNotEmpty)
                        formatCardNumber(a.number),
                      l10n.locale.languageCode == 'fa'
                          ? formatMoneyPersian(balance)
                          : formatMoneyCents(balance),
                    ].join(' • '),
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                onTap: () {
                  accounts.selectAccount(a.id);
                  Navigator.of(context).pop();
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.edit,
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
                      tooltip: l10n.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: accounts.accounts.length <= 1
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(l10n.deleteCard),
                                  content: Text(l10n.deleteCardWarning),
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
            
            if (!settings.swipeActionsEnabled || accounts.accounts.length <= 1) {
              return listItem;
            }
            
            return Dismissible(
              key: ValueKey(a.id),
              direction: DismissDirection.horizontal,
              onDismissed: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  // Swipe left to edit
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AccountFormScreen(initial: a),
                    ),
                  );
                } else if (direction == DismissDirection.startToEnd) {
                  // Swipe right to delete
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.deleteCard),
                      content: Text(l10n.deleteCardWarning),
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
                  if (confirmed == true) {
                    await accounts.deleteAccount(a.id);
                  }
                }
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.blue,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                child: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
              child: listItem,
            );
          },
        ),
      ),
    );
  }
}


