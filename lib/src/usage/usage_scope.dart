import 'package:flutter/widgets.dart';

import 'usage_controller.dart';

class UsageScope extends InheritedNotifier<UsageController> {
  const UsageScope({
    super.key,
    required UsageController controller,
    required super.child,
  }) : super(notifier: controller);

  static UsageController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UsageScope>();
    assert(scope != null, 'UsageScope not found in widget tree.');
    return scope!.notifier!;
  }
}

