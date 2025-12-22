import 'package:flutter/foundation.dart';

import '../transactions/transaction_controller.dart';
import 'account_repository.dart';
import 'bank_account.dart';

class AccountController extends ChangeNotifier {
  AccountController({
    AccountRepository? repository,
    TransactionController? transactionController,
  })  : _repository = repository ?? AccountRepository(),
        _transactionController = transactionController;

  final AccountRepository _repository;
  final TransactionController? _transactionController;

  bool _initialized = false;
  bool get initialized => _initialized;

  List<BankAccount> _accounts = const [];
  List<BankAccount> get accounts => List<BankAccount>.unmodifiable(_accounts);

  String? _selectedAccountId;
  String? get selectedAccountId => _selectedAccountId;

  BankAccount? get selectedAccount {
    final id = _selectedAccountId;
    if (id == null) return null;
    for (final a in _accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> init() async {
    _accounts = await _repository.loadAll();
    if (_accounts.isEmpty) {
      final account = BankAccount(
        id: 'default',
        name: 'Cash',
        number: null,
        initialBalanceCents: 0,
        createdAt: DateTime.now(),
      );
      _accounts = [account];
      await _repository.saveAll(_accounts);
    }

    _selectedAccountId = await _repository.readSelectedAccountId();
    if (_selectedAccountId == null ||
        !_accounts.any((a) => a.id == _selectedAccountId)) {
      _selectedAccountId = _accounts.first.id;
      await _repository.writeSelectedAccountId(_selectedAccountId);
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> selectAccount(String accountId) async {
    if (_selectedAccountId == accountId) return;
    _selectedAccountId = accountId;
    await _repository.writeSelectedAccountId(accountId);
    notifyListeners();
  }

  Future<void> addAccount(BankAccount account) async {
    _accounts = [..._accounts, account];
    await _repository.saveAll(_accounts);
    _selectedAccountId ??= account.id;
    notifyListeners();
  }

  Future<void> updateAccount(BankAccount account) async {
    _accounts = _accounts.map((a) => a.id == account.id ? account : a).toList();
    await _repository.saveAll(_accounts);
    notifyListeners();
  }

  Future<void> deleteAccount(String accountId) async {
    if (_accounts.length <= 1) return;
    _accounts = _accounts.where((a) => a.id != accountId).toList(growable: false);
    await _repository.saveAll(_accounts);
    await _transactionController?.deleteByAccountId(accountId);

    if (_selectedAccountId == accountId) {
      _selectedAccountId = _accounts.first.id;
      await _repository.writeSelectedAccountId(_selectedAccountId);
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    _accounts = const [];
    _selectedAccountId = null;
    await _repository.clear();
    notifyListeners();
  }
}
