import 'dart:math';

import 'package:flutter/foundation.dart';

import 'account_transaction.dart';
import 'transaction_repository.dart';
import 'transaction_type.dart';

class TransactionController extends ChangeNotifier {
  TransactionController({TransactionRepository? repository})
    : _repository = repository ?? TransactionRepository();

  final TransactionRepository _repository;

  bool _initialized = false;
  bool get initialized => _initialized;

  List<AccountTransaction> _transactions = const [];
  List<AccountTransaction> get transactions =>
      List<AccountTransaction>.unmodifiable(_transactions);

  Future<void> init() async {
    _transactions = _sort(await _repository.loadAll());
    _initialized = true;
    notifyListeners();
  }

  int get balanceCents {
    var balance = 0;
    for (final t in _transactions) {
      balance += t.type == TransactionType.income
          ? t.amountCents
          : -t.amountCents;
    }
    return balance;
  }

  int balanceCentsForAccount(
    String accountId, {
    required int initialBalanceCents,
  }) {
    var balance = initialBalanceCents;
    for (final t in _transactions) {
      if (t.accountId != accountId) continue;
      balance += t.type == TransactionType.income ? t.amountCents : -t.amountCents;
    }
    return balance;
  }

  List<AccountTransaction> transactionsForAccount(String accountId) {
    return _transactions.where((t) => t.accountId == accountId).toList(growable: false);
  }

  int get totalIncomeCents {
    var total = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.income) total += t.amountCents;
    }
    return total;
  }

  int get totalExpenseCents {
    var total = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.expense) total += t.amountCents;
    }
    return total;
  }

  Future<void> add(AccountTransaction transaction) async {
    _transactions = _sort(<AccountTransaction>[transaction, ..._transactions]);
    await _repository.saveAll(_transactions);
    notifyListeners();
  }

  Future<void> update(AccountTransaction transaction) async {
    _transactions = _sort(
      _transactions
          .map((t) => t.id == transaction.id ? transaction : t)
          .toList(),
    );
    await _repository.saveAll(_transactions);
    notifyListeners();
  }

  Future<void> deleteById(String id) async {
    _transactions = _transactions
        .where((t) => t.id != id)
        .toList(growable: false);
    await _repository.saveAll(_transactions);
    notifyListeners();
  }

  Future<void> deleteByAccountId(String accountId) async {
    _transactions =
        _transactions.where((t) => t.accountId != accountId).toList(growable: false);
    await _repository.saveAll(_transactions);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _transactions = const [];
    await _repository.clear();
    notifyListeners();
  }

  Future<void> replaceAll(List<AccountTransaction> items) async {
    _transactions = _sort(items);
    await _repository.saveAll(_transactions);
    notifyListeners();
  }

  Future<void> mergeAll(List<AccountTransaction> items) async {
    final byId = <String, AccountTransaction>{
      for (final t in _transactions) t.id: t,
    };
    for (final t in items) {
      final id = t.id.trim().isEmpty ? newId() : t.id;
      byId[id] = t.id == id ? t : t.copyWith(id: id);
    }
    _transactions = _sort(byId.values.toList(growable: false));
    await _repository.saveAll(_transactions);
    notifyListeners();
  }

  AccountTransaction? findById(String id) {
    for (final t in _transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  static String newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = Random.secure().nextInt(0xFFFFFFFF);
    return '$now-$random';
  }

  static List<AccountTransaction> _sort(List<AccountTransaction> items) {
    final sorted = items.toList(growable: false);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }
}
