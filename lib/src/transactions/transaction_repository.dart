import 'dart:convert';

import '../storage/encrypted_store.dart';

import 'account_transaction.dart';

class TransactionRepository {
  static const _key = 'transactions.v1';

  TransactionRepository({Future<EncryptedStore>? store})
    : _store = store ?? EncryptedStore.create();

  final Future<EncryptedStore> _store;

  Future<List<AccountTransaction>> loadAll() async {
    final store = await _store;
    final raw = await store.readString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => AccountTransaction.fromJson(e.cast<String, Object?>()))
        .toList(growable: false);
  }

  Future<void> saveAll(List<AccountTransaction> items) async {
    final store = await _store;
    final raw = jsonEncode(
      items.map((e) => e.toJson()).toList(growable: false),
    );
    await store.writeString(_key, raw);
  }

  Future<void> clear() async {
    final store = await _store;
    await store.remove(_key);
  }
}
