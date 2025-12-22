import 'package:flutter/widgets.dart';

import 'transaction_controller.dart';

class TransactionScope extends InheritedNotifier<TransactionController> {
  const TransactionScope({
    super.key,
    required TransactionController controller,
    required super.child,
  }) : super(notifier: controller);

  static TransactionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TransactionScope>();
    assert(scope != null, 'TransactionScope not found in widget tree.');
    return scope!.notifier!;
  }
}

