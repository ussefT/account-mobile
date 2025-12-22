import 'dart:convert';

import '../storage/encrypted_store.dart';
import 'bank_account.dart';

class AccountRepository {
  static const _key = 'accounts.v1';
  static const _selectedKey = 'accounts.selected.v1';

  AccountRepository({Future<EncryptedStore>? store})
      : _store = store ?? EncryptedStore.create();

  final Future<EncryptedStore> _store;

  Future<List<BankAccount>> loadAll() async {
    final store = await _store;
    final raw = await store.readString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => BankAccount.fromJson(e.cast<String, Object?>()))
        .toList(growable: false);
  }

  Future<void> saveAll(List<BankAccount> items) async {
    final store = await _store;
    final raw = jsonEncode(items.map((e) => e.toJson()).toList(growable: false));
    await store.writeString(_key, raw);
  }

  Future<String?> readSelectedAccountId() async {
    final store = await _store;
    return await store.readString(_selectedKey);
  }

  Future<void> writeSelectedAccountId(String? id) async {
    final store = await _store;
    if (id == null) {
      await store.remove(_selectedKey);
      return;
    }
    await store.writeString(_selectedKey, id);
  }

  Future<void> clear() async {
    final store = await _store;
    await store.remove(_key);
    await store.remove(_selectedKey);
  }
}

