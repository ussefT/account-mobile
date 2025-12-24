import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../settings/settings_scope.dart';
import '../transactions/transaction_controller.dart';
import '../transactions/transaction_type.dart';
import 'category.dart';
import 'category_scope.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  TransactionType _type = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final controller = CategoryScope.of(context);
    final settings = SettingsScope.of(context);
    final items = controller.categoriesForType(_type);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        actions: [
          IconButton(
            onPressed: () async {
              final name = await _promptName(context, title: l10n.addCategory, l10n: l10n);
              if (name == null || name.trim().isEmpty) return;
              await controller.addCategory(
                TxnCategory(
                  id: TransactionController.newId(),
                  name: name.trim(),
                  type: _type,
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: l10n.add,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<TransactionType>(
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
                  setState(() => _type = value.first);
                },
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text(l10n.noTransactions))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final c = items[index];
                        final listItem = Card(
                          child: ListTile(
                            title: Text(c.name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l10n.edit,
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () async {
                                    final name = await _promptName(
                                      context,
                                      title: l10n.editCategory,
                                      initial: c.name,
                                      l10n: l10n,
                                    );
                                    if (name == null || name.trim().isEmpty) {
                                      return;
                                    }
                                    await controller.updateCategory(
                                      c.copyWith(name: name.trim()),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: l10n.delete,
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete category?'),
                                        content: Text(
                                          '"${c.name}" will be removed.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: Text(l10n.cancel),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: Text(l10n.delete),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed != true) return;
                                    await controller.deleteCategory(c.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                        
                        if (!settings.swipeActionsEnabled) {
                          return listItem;
                        }
                        
                        return Dismissible(
                          key: ValueKey(c.id),
                          direction: DismissDirection.horizontal,
                          onDismissed: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // Swipe right to edit
                              final name = await _promptName(
                                context,
                                title: l10n.editCategory,
                                initial: c.name,
                                l10n: l10n,
                              );
                              if (name != null && name.trim().isNotEmpty) {
                                await controller.updateCategory(
                                  c.copyWith(name: name.trim()),
                                );
                              }
                            } else if (direction == DismissDirection.endToStart) {
                              // Swipe left to delete
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete category?'),
                                  content: Text(
                                    '"${c.name}" will be removed.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(
                                        context,
                                      ).pop(false),
                                      child: Text(l10n.cancel),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(l10n.delete),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await controller.deleteCategory(c.id);
                              }
                            }
                          },
                          background: Container(
                            color: Colors.blue,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 16),
                            child: const Icon(Icons.edit_outlined, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          child: listItem,
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

Future<String?> _promptName(
  BuildContext context, {
  required String title,
  String? initial,
  required AppLocalizations l10n,
}) {
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String?>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: l10n.enterCategoryName,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.save),
          ),
        ],
      );
    },
  );
}
