import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../auth/auth_scope.dart';
import '../accounts/account_scope.dart';
import '../accounts/accounts_screen.dart';
import '../accounts/bank_account.dart';
import '../charts/charts_screen.dart';
import '../categories/categories_screen.dart';
import '../categories/category_scope.dart';
import '../settings/settings_screen.dart';
import '../storage/encrypted_store.dart';
import '../transactions/transaction_csv.dart';
import '../transactions/transaction_scope.dart';
import '../transactions/transaction_type.dart';
import '../transactions/transaction_detail_screen.dart';
import '../transactions/transaction_form_screen.dart';
import '../usage/usage_scope.dart';
import '../utils/money.dart';

enum _MenuAction {
  accounts,
  categories,
  charts,
  settings,
  exportCsv,
  importCsv,
  policy,
  deleteAccount,
}

enum _SortMode { date, amount, income, expense }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _SortMode _sortMode = _SortMode.date;
  DateTime? _selectedDate;
  TransactionType? _typeFilter;

  int _typeRank(TransactionType type, {required bool incomeFirst}) {
    if (incomeFirst) {
      return type == TransactionType.income ? 0 : 1;
    }
    return type == TransactionType.expense ? 0 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final transactions = TransactionScope.of(context);
    final accounts = AccountScope.of(context);
    final usage = UsageScope.of(context);
    if (!transactions.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedAccount = accounts.selectedAccount;
    final txList = selectedAccount == null
        ? transactions.transactions
        : transactions.transactionsForAccount(selectedAccount.id);

    final now = DateTime.now();
    final asOfRaw = _selectedDate ?? now;
    final asOf = DateTime(asOfRaw.year, asOfRaw.month, asOfRaw.day);
    final initialBalanceCents = selectedAccount?.initialBalanceCents ?? 0;
    var balanceCents = initialBalanceCents;
    var incomeCents = 0;
    var expenseCents = 0;
    for (final t in txList) {
      if (t.date.isAfter(asOf)) continue;
      if (t.type == TransactionType.income) {
        incomeCents += t.amountCents;
        balanceCents += t.amountCents;
      } else {
        expenseCents += t.amountCents;
        balanceCents -= t.amountCents;
      }
    }

    final balance = formatMoneyCents(balanceCents);
    final income = formatMoneyCents(incomeCents);
    final expenses = formatMoneyCents(expenseCents);

    var filteredTxList = _selectedDate == null
        ? txList
        : txList.where((t) => _isSameDay(t.date, asOf)).toList(growable: false);
    final typeFilter = _typeFilter;
    if (typeFilter != null) {
      filteredTxList = filteredTxList
          .where((t) => t.type == typeFilter)
          .toList(growable: false);
    }

    final sortedTxList = filteredTxList.toList(growable: false);
    sortedTxList.sort((a, b) {
      switch (_sortMode) {
        case _SortMode.date:
          return b.date.compareTo(a.date);
        case _SortMode.amount:
          return b.amountCents.compareTo(a.amountCents);
        case _SortMode.income:
          final type = _typeRank(
            a.type,
            incomeFirst: true,
          ).compareTo(_typeRank(b.type, incomeFirst: true));
          return type != 0 ? type : b.date.compareTo(a.date);
        case _SortMode.expense:
          final type = _typeRank(
            a.type,
            incomeFirst: false,
          ).compareTo(_typeRank(b.type, incomeFirst: false));
          return type != 0 ? type : b.date.compareTo(a.date);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: asOf,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              setState(() => _selectedDate = picked);
            },
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Pick date',
          ),
          if (_selectedDate != null)
            IconButton(
              onPressed: () => setState(() => _selectedDate = null),
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date',
            ),
          IconButton(
            onPressed: auth.logout,
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Lock',
          ),
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: (mode) => setState(() => _sortMode = mode),
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: _SortMode.date,
                  child: Text('Sort by date'),
                ),
                PopupMenuItem(
                  value: _SortMode.amount,
                  child: Text('Sort by amount'),
                ),
                PopupMenuItem(
                  value: _SortMode.income,
                  child: Text('Income first'),
                ),
                PopupMenuItem(
                  value: _SortMode.expense,
                  child: Text('Expense first'),
                ),
              ];
            },
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: (action) async {
              switch (action) {
                case _MenuAction.accounts:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountsScreen(),
                    ),
                  );
                  return;
                case _MenuAction.categories:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CategoriesScreen(),
                    ),
                  );
                  return;
                case _MenuAction.charts:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChartsScreen(),
                    ),
                  );
                  return;
                case _MenuAction.settings:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                  return;
                case _MenuAction.exportCsv:
                  final csv = exportTransactionsCsv(txList);
                  await Clipboard.setData(ClipboardData(text: csv));
                  if (!context.mounted) return;
                  final file = XFile.fromData(
                    Uint8List.fromList(utf8.encode(csv)),
                    mimeType: 'text/csv',
                    name: 'transactions.csv',
                  );
                  await Share.shareXFiles([file], subject: 'Transactions CSV');
                  return;
                case _MenuAction.importCsv:
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: const ['csv'],
                    withData: true,
                    allowMultiple: false,
                  );
                  if (result == null || result.files.isEmpty) return;
                  final bytes = result.files.single.bytes;
                  if (bytes == null) return;
                  final csvText = utf8.decode(bytes);
                  final imported = importTransactionsCsv(csvText);
                  await transactions.mergeAll(imported);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Imported ${imported.length} transactions'),
                    ),
                  );
                  return;
                case _MenuAction.policy:
                  await showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Privacy policy'),
                      content: const Text(
                        'This app works offline.\n\n'
                        'Your data is stored locally on your device.\n'
                        'Transactions, bank cards, and categories are encrypted at rest.\n\n'
                        'You can export your data anytime as CSV.',
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                case _MenuAction.deleteAccount:
                  final categories = CategoryScope.of(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Delete account?'),
                        content: const Text(
                          'This deletes the local account and all transactions on this device.',
                        ),
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
                      );
                    },
                  );
                  if (confirmed != true) return;
                  final store = await EncryptedStore.create();
                  await store.clearAllData();
                  await accounts.clearAll();
                  await transactions.clearAll();
                  await categories.clearAll();
                  await auth.resetAccount();
                  return;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: _MenuAction.accounts,
                  child: Text('Bank cards'),
                ),
                PopupMenuItem(
                  value: _MenuAction.categories,
                  child: Text('Categories'),
                ),
                PopupMenuItem(value: _MenuAction.charts, child: Text('Charts')),
                PopupMenuItem(
                  value: _MenuAction.settings,
                  child: Text('Settings'),
                ),
                PopupMenuItem(
                  value: _MenuAction.exportCsv,
                  child: Text('Export CSV (Excel)'),
                ),
                PopupMenuItem(
                  value: _MenuAction.importCsv,
                  child: Text('Import CSV (Excel)'),
                ),
                PopupMenuItem(
                  value: _MenuAction.policy,
                  child: Text('Privacy policy'),
                ),
                PopupMenuItem(
                  value: _MenuAction.deleteAccount,
                  child: Text('Delete account'),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _DashboardHeader(
                  accounts: accounts.accounts,
                  selectedAccountId: accounts.selectedAccountId ?? 'default',
                  asOf: asOf,
                  balance: balance,
                  income: income,
                  expenses: expenses,
                  initialBalanceCents: initialBalanceCents,
                  username: auth.username,
                  lastIn: usage.lastIn,
                  lastOut: usage.lastOut,
                  onSelectAccount: (id) => accounts.selectAccount(id),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        _selectedDate == null
                            ? 'Any date'
                            : _formatDate(_selectedDate!),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: asOf,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setState(() => _selectedDate = picked);
                      },
                    ),
                    if (_selectedDate != null)
                      ActionChip(
                        avatar: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        onPressed: () => setState(() => _selectedDate = null),
                      ),
                    PopupMenuButton<_SortMode>(
                      tooltip: 'Sort',
                      onSelected: (mode) => setState(() => _sortMode = mode),
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: _SortMode.date,
                            child: Text('Sort by date'),
                          ),
                          PopupMenuItem(
                            value: _SortMode.amount,
                            child: Text('Sort by amount'),
                          ),
                          PopupMenuItem(
                            value: _SortMode.income,
                            child: Text('Income first'),
                          ),
                          PopupMenuItem(
                            value: _SortMode.expense,
                            child: Text('Expense first'),
                          ),
                        ];
                      },
                      child: Chip(
                        avatar: const Icon(Icons.sort),
                        label: Text(_sortLabel(_sortMode)),
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _typeFilter == null,
                      onSelected: (_) => setState(() => _typeFilter = null),
                    ),
                    ChoiceChip(
                      label: const Text('Income'),
                      selected: _typeFilter == TransactionType.income,
                      onSelected: (_) =>
                          setState(() => _typeFilter = TransactionType.income),
                    ),
                    ChoiceChip(
                      label: const Text('Expense'),
                      selected: _typeFilter == TransactionType.expense,
                      onSelected: (_) =>
                          setState(() => _typeFilter = TransactionType.expense),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.pie_chart_outline),
                      label: const Text('Charts'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ChartsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Transactions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${sortedTxList.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
            if (sortedTxList.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.separated(
                  itemCount: sortedTxList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final t = sortedTxList[index];
                    return _TransactionCard(
                      transactionId: t.id,
                      title: t.title,
                      category: t.category,
                      date: t.date,
                      type: t.type,
                      amountCents: t.amountCents,
                      notInBalanceYet: t.date.isAfter(asOf),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final accountId =
              AccountScope.of(context).selectedAccountId ?? 'default';
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TransactionFormScreen(accountId: accountId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap “Add” to log income or expenses.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.accounts,
    required this.selectedAccountId,
    required this.asOf,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.initialBalanceCents,
    required this.username,
    required this.lastIn,
    required this.lastOut,
    required this.onSelectAccount,
  });

  final List<BankAccount> accounts;
  final String selectedAccountId;
  final DateTime asOf;
  final String balance;
  final String income;
  final String expenses;
  final int initialBalanceCents;
  final String? username;
  final DateTime? lastIn;
  final DateTime? lastOut;
  final ValueChanged<String> onSelectAccount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = LinearGradient(
      colors: [scheme.primaryContainer, scheme.secondaryContainer],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedAccountId,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem<String>(
                            value: a.id,
                            child: Text(
                              a.number == null || a.number!.isEmpty
                                  ? a.name
                                  : '${a.name} • ${a.number}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (v) {
                      if (v == null) return;
                      onSelectAccount(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: scheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Balance',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            balance,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _HeaderPill(
                icon: Icons.today_outlined,
                text: 'As of ${_formatDate(asOf)}',
              ),
              if (initialBalanceCents != 0)
                _HeaderPill(
                  icon: Icons.savings_outlined,
                  text: 'Initial ${formatMoneyCents(initialBalanceCents)}',
                ),
              if (username != null && username!.trim().isNotEmpty)
                _HeaderPill(icon: Icons.person_outline, text: username!.trim()),
            ],
          ),
          if (lastIn != null || lastOut != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                if (lastIn != null)
                  _HeaderPill(
                    icon: Icons.login_outlined,
                    text: 'In ${_formatDateTime(lastIn!)}',
                  ),
                if (lastOut != null)
                  _HeaderPill(
                    icon: Icons.logout_outlined,
                    text: 'Out ${_formatDateTime(lastOut!)}',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Income',
                  value: income,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Expenses',
                  value: expenses,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transactionId,
    required this.title,
    required this.category,
    required this.date,
    required this.type,
    required this.amountCents,
    required this.notInBalanceYet,
  });

  final String transactionId;
  final String title;
  final String category;
  final DateTime date;
  final TransactionType type;
  final int amountCents;
  final bool notInBalanceYet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amount = formatMoneyCents(amountCents);
    final isExpense = type == TransactionType.expense;
    final amountText = isExpense ? '-$amount' : '+$amount';
    final amountColor = isExpense ? Colors.red : Colors.green;
    final icon = isExpense ? Icons.south_east : Icons.north_east;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: amountColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: amountColor.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: amountColor),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$category • ${_formatDate(date)}${notInBalanceYet ? ' • Not in balance yet' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: amountColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: amountColor.withValues(alpha: 0.22)),
          ),
          child: Text(
            amountText,
            style: TextStyle(fontWeight: FontWeight.w800, color: amountColor),
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  TransactionDetailScreen(transactionId: transactionId),
            ),
          );
        },
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

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDateTime(DateTime dateTime) {
  final dt = dateTime.toLocal();
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}

String _sortLabel(_SortMode mode) {
  return switch (mode) {
    _SortMode.date => 'Date',
    _SortMode.amount => 'Amount',
    _SortMode.income => 'Income first',
    _SortMode.expense => 'Expense first',
  };
}
