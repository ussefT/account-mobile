import 'package:flutter/widgets.dart';

import 'account_controller.dart';

class AccountScope extends InheritedNotifier<AccountController> {
  const AccountScope({
    super.key,
    required AccountController controller,
    required super.child,
  }) : super(notifier: controller);

  static AccountController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AccountScope>();
    assert(scope != null, 'AccountScope not found in widget tree.');
    return scope!.notifier!;
  }
}

