import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../transactions/transaction_controller.dart';
import '../utils/money.dart';
import 'account_scope.dart';
import 'bank_account.dart';

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({super.key, this.initial});

  final BankAccount? initial;

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _numberController;
  late final TextEditingController _initialBalanceController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _numberController = TextEditingController(text: initial?.number ?? '');
    _initialBalanceController = TextEditingController(
      text: initial == null
          ? ''
          : (initial.initialBalanceCents / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final controller = AccountScope.of(context);
      final initialBalanceCents = _initialBalanceController.text.trim().isEmpty
          ? 0
          : parseMoneyToCents(_initialBalanceController.text);

      final name = _nameController.text.trim();
      final number = _numberController.text.trim().isEmpty
          ? null
          : _numberController.text.trim();

      final initial = widget.initial;
      if (initial == null) {
        final account = BankAccount(
          id: TransactionController.newId(),
          name: name,
          number: number,
          initialBalanceCents: initialBalanceCents,
          createdAt: DateTime.now(),
        );
        await controller.addAccount(account);
        await controller.selectAccount(account.id);
      } else {
        await controller.updateAccount(
          initial.copyWith(
            name: name,
            number: number,
            initialBalanceCents: initialBalanceCents,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? l10n.editCard : l10n.addCard)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.cardBankName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.credit_card_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return l10n.enterCardName;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _numberController,
                  decoration: InputDecoration(
                    labelText: l10n.cardNumber,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.numbers_outlined),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _initialBalanceController,
                  decoration: InputDecoration(
                    labelText: l10n.initialBalance,
                    hintText: '0.00',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  inputFormatters: const [MoneyTextInputFormatter()],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return null;
                    try {
                      parseMoneyToCents(value!);
                      return null;
                    } catch (_) {
                      return l10n.enterValidAmount;
                    }
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? l10n.save : l10n.add),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
