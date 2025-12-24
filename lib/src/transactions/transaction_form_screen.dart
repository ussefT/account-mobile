import 'package:flutter/material.dart';

import '../accounts/account_scope.dart';
import '../auth/auth_scope.dart';
import '../categories/category_controller.dart';
import '../categories/category_scope.dart';
import '../localization/app_localizations.dart';
import '../utils/money.dart';
import '../utils/persian_formatting.dart';
import 'account_transaction.dart';
import 'transaction_controller.dart';
import 'transaction_scope.dart';
import 'transaction_type.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.initial, this.accountId});

  final AccountTransaction? initial;
  final String? accountId;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryFieldKey = GlobalKey<FormFieldState<String>>();
  final _accountFieldKey = GlobalKey<FormFieldState<String>>();

  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final TextEditingController _personController;

  late TransactionType _type;
  late String _accountId;
  late String _category;
  late DateTime _date;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = initial?.type ?? TransactionType.expense;
    _accountId = initial?.accountId ?? widget.accountId ?? 'default';
    _category = initial?.category ?? '';
    _date = initial?.date ?? DateTime.now();
    _titleController = TextEditingController(text: initial?.title ?? '');
    _amountController = TextEditingController(
      text: initial == null
          ? ''
          : (initial.amountCents / 100).toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: initial?.note ?? '');
    _personController = TextEditingController(
      text: initial?.relatedPerson ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _personController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final cents = parseMoneyToCents(_amountController.text);
      final l10n = AppLocalizations.of(context);
      
      if (cents <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.amountMustBeGreater)),
        );
        return;
      }

      final controller = TransactionScope.of(context);
      final auth = AuthScope.of(context);
      final initial = widget.initial;
      final createdBy = (initial?.createdBy ?? auth.username)?.trim();
      final tx = AccountTransaction(
        id: initial?.id ?? TransactionController.newId(),
        accountId: _accountId,
        title: _titleController.text.trim(),
        amountCents: cents,
        type: _type,
        category: _category,
        date: DateTime(_date.year, _date.month, _date.day),
        createdBy: createdBy == null || createdBy.isEmpty ? null : createdBy,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        relatedPerson: _personController.text.trim().isEmpty
            ? null
            : _personController.text.trim(),
      );

      if (initial == null) {
        await controller.add(tx);
      } else {
        await controller.update(tx);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.couldNotSave}$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onTransactionTypeChanged(
    TransactionType next,
    CategoryController categoryController,
  ) {
    setState(() {
      _type = next;
      final nextCategories = categoryController.categoriesForType(next);
      if (nextCategories.isNotEmpty &&
          nextCategories.every((c) => c.name != _category)) {
        _category = nextCategories.first.name;
      }
      _categoryFieldKey.currentState?.didChange(_category);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final accountsController = AccountScope.of(context);
    final categoryController = CategoryScope.of(context);
    final l10n = AppLocalizations.of(context);
    final isPersian = l10n.locale.languageCode == 'fa';

    final accounts = accountsController.accounts;
    if (accounts.isEmpty) {
      return Scaffold(body: Center(child: Text(l10n.noTransactions)));
    }
    if (!accounts.any((a) => a.id == _accountId)) {
      _accountId = accounts.first.id;
    }

    final categories = categoryController.categoriesForType(_type);
    if (categories.isNotEmpty && categories.every((c) => c.name != _category)) {
      _category = categories.first.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editTransaction : l10n.addTransaction),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<String>(
                  key: _accountFieldKey,
                  initialValue: _accountId,
                  decoration: InputDecoration(
                    labelText: l10n.card,
                    border: const OutlineInputBorder(),
                  ),
                  items: accounts
                      .map(
                        (a) => DropdownMenuItem<String>(
                          value: a.id,
                          child: Text(
                            a.number == null || a.number!.isEmpty
                                ? a.name
                                : '${a.name} • ${formatCardNumber(a.number)}',
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _accountId = value);
                  },
                ),
                const SizedBox(height: 12),
                SegmentedButton<TransactionType>(
                  segments: [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text(l10n.expense),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text(l10n.income),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                  ],
                  selected: <TransactionType>{_type},
                  onSelectionChanged: (value) {
                    _onTransactionTypeChanged(
                      value.first,
                      categoryController,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    hintText: l10n.amountHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(isPersian ? Icons.monetization_on : Icons.attach_money),
                    suffixText: isPersian ? 'ریال' : null,
                  ),
                  inputFormatters: const [MoneyTextInputFormatter()],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    try {
                      final cents = parseMoneyToCents(value ?? '');
                      if (cents <= 0) return l10n.amountMustBeGreater;
                      return null;
                    } catch (_) {
                      return l10n.enterValidAmount;
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.title,
                    hintText: l10n.enterTitle,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return l10n.enterTitle;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: _categoryFieldKey,
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.name,
                          child: Text(c.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.date,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(_formatDate(_date, isPersian: isPersian)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.affectsBalance} ${_formatDate(_date, isPersian: isPersian)}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.noteOptional,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.notes_outlined),
                  ),
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _personController,
                  decoration: InputDecoration(
                    labelText: l10n.relatedPersonOptional,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.done,
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
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
String _formatDate(DateTime date, {bool isPersian = false}) {
  if (isPersian) {
    return formatDatePersian(date);
  }
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
