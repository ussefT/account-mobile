import 'package:flutter/foundation.dart';

import '../transactions/transaction_controller.dart';
import '../transactions/transaction_type.dart';
import 'category.dart';
import 'category_repository.dart';

class CategoryController extends ChangeNotifier {
  CategoryController({CategoryRepository? repository})
    : _repository = repository ?? CategoryRepository();

  final CategoryRepository _repository;

  bool _initialized = false;
  bool get initialized => _initialized;

  List<TxnCategory> _categories = const [];
  List<TxnCategory> get categories =>
      List<TxnCategory>.unmodifiable(_categories);

  Future<void> init() async {
    try {
      _categories = await _repository.loadAll();
      if (_categories.isEmpty) {
        _categories = [
          TxnCategory(
            id: TransactionController.newId(),
            name: 'Food',
            type: TransactionType.expense,
          ),
          TxnCategory(
            id: TransactionController.newId(),
            name: 'Snack',
            type: TransactionType.expense,
          ),
          TxnCategory(
            id: TransactionController.newId(),
            name: 'Transport',
            type: TransactionType.expense,
          ),
          TxnCategory(
            id: TransactionController.newId(),
            name: 'Loan',
            type: TransactionType.expense,
          ),
          TxnCategory(
            id: TransactionController.newId(),
            name: 'Other',
            type: TransactionType.expense,
          ),
          TxnCategory(
            id: TransactionController.newId(),
            name: 'Salary',
            type: TransactionType.income,
          ),
          TxnCategory(
            id: TransactionController.newId(),
            name: 'Gift',
            type: TransactionType.income,
          ),
          TxnCategory(
            id: TransactionController.newId(),
            name: 'Other',
            type: TransactionType.income,
          ),
        ];
        await _repository.saveAll(_categories);
      }
      _initialized = true;
      notifyListeners();
    } catch (e) {
      // If initialization fails, set up default categories without saving
      _categories = [
        TxnCategory(
          id: TransactionController.newId(),
          name: 'Food',
          type: TransactionType.expense,
        ),
        TxnCategory(
          id: TransactionController.newId(),
          name: 'Snack',
          type: TransactionType.expense,
        ),
        TxnCategory(
          id: TransactionController.newId(),
          name: 'Transport',
          type: TransactionType.expense,
        ),
        TxnCategory(
          id: TransactionController.newId(),
          name: 'Loan',
          type: TransactionType.expense,
        ),
        TxnCategory(
          id: TransactionController.newId(),
          name: 'Other',
          type: TransactionType.expense,
        ),
        TxnCategory(
          id: TransactionController.newId(),
          name: 'Salary',
          type: TransactionType.income,
        ),
        TxnCategory(
          id: TransactionController.newId(),
          name: 'Gift',
          type: TransactionType.income,
        ),
        TxnCategory(
          id: TransactionController.newId(),
          name: 'Other',
          type: TransactionType.income,
        ),
      ];
      _initialized = true;
      notifyListeners();
    }
  }

  List<TxnCategory> categoriesForType(TransactionType type) {
    return _categories.where((c) => c.type == type).toList(growable: false);
  }

  Future<void> addCategory(TxnCategory category) async {
    _categories = [..._categories, category];
    await _repository.saveAll(_categories);
    notifyListeners();
  }

  Future<void> updateCategory(TxnCategory category) async {
    _categories = _categories
        .map((c) => c.id == category.id ? category : c)
        .toList();
    await _repository.saveAll(_categories);
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _categories = _categories.where((c) => c.id != id).toList(growable: false);
    await _repository.saveAll(_categories);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _categories = const [];
    await _repository.clear();
    notifyListeners();
  }
}
