import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../auth/auth_scope.dart';
import '../accounts/account_scope.dart';
import '../accounts/accounts_screen.dart';
import '../charts/charts_screen.dart';
import '../categories/categories_screen.dart';
import '../categories/category_scope.dart';
import '../settings/settings_screen.dart';
import '../storage/encrypted_store.dart';
import '../transactions/account_transaction.dart';
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
  int _navIndex = 0;

  int _typeRank(TransactionType type, {required bool incomeFirst}) {
    if (incomeFirst) {
      return type == TransactionType.income ? 0 : 1;
    }
    return type == TransactionType.expense ? 0 : 1;
  }

  Future<void> _openFiltersSheet(BuildContext context, DateTime asOf) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final typeFilter = _typeFilter;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month_outlined),
                      title: Text(
                        _selectedDate == null
                            ? 'Any date'
                            : _formatDate(_selectedDate!),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? asOf,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setState(() => _selectedDate = picked);
                        sheetSetState(() {});
                      },
                    ),
                    if (_selectedDate != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() => _selectedDate = null);
                            sheetSetState(() {});
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear date'),
                        ),
                      ),
                    const SizedBox(height: 6),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.sort),
                      title: const Text('Sort'),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<_SortMode>(
                          value: _sortMode,
                          items: const [
                            DropdownMenuItem(
                              value: _SortMode.date,
                              child: Text('Date'),
                            ),
                            DropdownMenuItem(
                              value: _SortMode.amount,
                              child: Text('Amount'),
                            ),
                            DropdownMenuItem(
                              value: _SortMode.income,
                              child: Text('Income first'),
                            ),
                            DropdownMenuItem(
                              value: _SortMode.expense,
                              child: Text('Expense first'),
                            ),
                          ],
                          onChanged: (mode) {
                            if (mode == null) return;
                            setState(() => _sortMode = mode);
                            sheetSetState(() {});
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: typeFilter == null,
                          onSelected: (_) {
                            setState(() => _typeFilter = null);
                            sheetSetState(() {});
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Income'),
                          selected: typeFilter == TransactionType.income,
                          onSelected: (_) {
                            setState(
                              () => _typeFilter = TransactionType.income,
                            );
                            sheetSetState(() {});
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Expense'),
                          selected: typeFilter == TransactionType.expense,
                          onSelected: (_) {
                            setState(
                              () => _typeFilter = TransactionType.expense,
                            );
                            sheetSetState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

    final balancesByAccountId = <String, int>{
      for (final a in accounts.accounts) a.id: a.initialBalanceCents,
    };
    for (final t in transactions.transactions) {
      if (t.date.isAfter(asOf)) continue;
      final current = balancesByAccountId[t.accountId] ?? 0;
      balancesByAccountId[t.accountId] =
          current +
          (t.type == TransactionType.income ? t.amountCents : -t.amountCents);
    }

    final greetingName = (auth.username ?? '').trim().isEmpty
        ? 'User'
        : auth.username!.trim();
    final greeting = switch (now.hour) {
      >= 5 && < 12 => 'Good morning',
      >= 12 && < 17 => 'Good afternoon',
      >= 17 && < 22 => 'Good evening',
      _ => 'Welcome back',
    };

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _IscHeader(
                  greeting: greeting,
                  greetingName: greetingName,
                  selectedAccountName: (selectedAccount?.name ?? 'Account')
                      .trim(),
                  balance: balance,
                  income: income,
                  expenses: expenses,
                  asOf: asOf,
                  lastIn: usage.lastIn,
                  lastOut: usage.lastOut,
                  onLock: auth.logout,
                  onOpenFilters: () => _openFiltersSheet(context, asOf),
                  menu: _OptionsMenu(
                    txList: txList,
                    onAfterImport: () => setState(() {}),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cards',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: accounts.accounts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final a = accounts.accounts[index];
                          final isSelected =
                              a.id == (accounts.selectedAccountId ?? 'default');
                          final accountBalanceCents =
                              balancesByAccountId[a.id] ??
                              a.initialBalanceCents;
                          return _AccountCardTile(
                            name: a.name,
                            number: a.number,
                            balance: formatMoneyCents(accountBalanceCents),
                            selected: isSelected,
                            onTap: () => accounts.selectAccount(a.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Services',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ServiceTile(
                            icon: Icons.add,
                            label: 'Add',
                            onTap: () {
                              final accountId =
                                  accounts.selectedAccountId ?? 'default';
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TransactionFormScreen(
                                    accountId: accountId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ServiceTile(
                            icon: Icons.tune,
                            label: 'Filter',
                            onTap: () => _openFiltersSheet(context, asOf),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ServiceTile(
                            icon: Icons.credit_card_outlined,
                            label: 'Cards',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AccountsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ServiceTile(
                            icon: Icons.pie_chart_outline,
                            label: 'Charts',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ChartsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
                      'Recent activity',
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final accountId = accounts.selectedAccountId ?? 'default';
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TransactionFormScreen(accountId: accountId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: _BottomNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                selected: _navIndex == 0,
                onTap: () => setState(() => _navIndex = 0),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.credit_card_outlined,
                label: 'Cards',
                selected: _navIndex == 1,
                onTap: () {
                  setState(() => _navIndex = 1);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 56),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.pie_chart_outline,
                label: 'Charts',
                selected: _navIndex == 2,
                onTap: () {
                  setState(() => _navIndex = 2);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ChartsScreen(),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                icon: Icons.category_outlined,
                label: 'Categories',
                selected: _navIndex == 3,
                onTap: () {
                  setState(() => _navIndex = 3);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CategoriesScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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

class _IscHeader extends StatelessWidget {
  const _IscHeader({
    required this.greeting,
    required this.greetingName,
    required this.selectedAccountName,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.asOf,
    required this.lastIn,
    required this.lastOut,
    required this.onLock,
    required this.onOpenFilters,
    required this.menu,
  });

  final String greeting;
  final String greetingName;
  final String selectedAccountName;
  final String balance;
  final String income;
  final String expenses;
  final DateTime asOf;
  final DateTime? lastIn;
  final DateTime? lastOut;
  final VoidCallback onLock;
  final VoidCallback onOpenFilters;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top =
        Color.lerp(scheme.primary, Colors.black, 0.78) ?? scheme.primary;
    final bottom =
        Color.lerp(scheme.secondary, Colors.black, 0.72) ?? scheme.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [top, bottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Colors.white.withValues(alpha: 0.92),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hi, $greetingName',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onOpenFilters,
                  icon: const Icon(Icons.tune, color: Colors.white),
                  tooltip: 'Filters',
                ),
                IconButton(
                  onPressed: onLock,
                  icon: const Icon(Icons.lock_outline, color: Colors.white),
                  tooltip: 'Lock',
                ),
                menu,
              ],
            ),
            const SizedBox(height: 12),
            Text(
              selectedAccountName,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              balance,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _DarkPill(
                  icon: Icons.today_outlined,
                  text: 'As of ${_formatDate(asOf)}',
                ),
                if (lastIn != null)
                  _DarkPill(
                    icon: Icons.login_outlined,
                    text: 'In ${_formatDateTime(lastIn!)}',
                  ),
                if (lastOut != null)
                  _DarkPill(
                    icon: Icons.logout_outlined,
                    text: 'Out ${_formatDateTime(lastOut!)}',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Income',
                    value: income,
                    color: Colors.green,
                    compact: true,
                    onDarkBackground: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'Expenses',
                    value: expenses,
                    color: Colors.red,
                    compact: true,
                    onDarkBackground: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
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
    this.compact = false,
    this.onDarkBackground = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool compact;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: onDarkBackground
            ? Colors.white.withValues(alpha: 0.10)
            : scheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onDarkBackground
              ? Colors.white.withValues(alpha: 0.18)
              : scheme.outlineVariant.withValues(alpha: 0.35),
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

class _AccountCardTile extends StatelessWidget {
  const _AccountCardTile({
    required this.name,
    required this.number,
    required this.balance,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String? number;
  final String balance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textColor = selected ? scheme.onPrimary : scheme.onPrimaryContainer;
    final background = LinearGradient(
      colors: selected
          ? [scheme.primary, scheme.secondary]
          : [scheme.primaryContainer, scheme.secondaryContainer],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: background,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.30),
            ),
          ),
          child: DefaultTextStyle(
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(color: textColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selected)
                      Icon(Icons.verified_rounded, size: 18, color: textColor),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (number == null || number!.isEmpty) ? '•••• ••••' : number!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor.withValues(alpha: 0.95),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  'Balance',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balance,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(icon, color: scheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: 0.9);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionsMenu extends StatelessWidget {
  const _OptionsMenu({required this.txList, required this.onAfterImport});

  final List<AccountTransaction> txList;
  final VoidCallback onAfterImport;

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final transactions = TransactionScope.of(context);
    final accounts = AccountScope.of(context);
    return PopupMenuButton<_MenuAction>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      tooltip: 'Options',
      onSelected: (action) async {
        switch (action) {
          case _MenuAction.accounts:
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AccountsScreen()),
            );
            return;
          case _MenuAction.categories:
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
            );
            return;
          case _MenuAction.charts:
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ChartsScreen()),
            );
            return;
          case _MenuAction.settings:
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
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
            onAfterImport();
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
          PopupMenuItem(value: _MenuAction.accounts, child: Text('Bank cards')),
          PopupMenuItem(
            value: _MenuAction.categories,
            child: Text('Categories'),
          ),
          PopupMenuItem(value: _MenuAction.charts, child: Text('Charts')),
          PopupMenuItem(value: _MenuAction.settings, child: Text('Settings')),
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
