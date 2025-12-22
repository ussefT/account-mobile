import '../transactions/transaction_type.dart';

class TxnCategory {
  const TxnCategory({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final TransactionType type;

  TxnCategory copyWith({String? id, String? name, TransactionType? type}) {
    return TxnCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  Map<String, Object?> toJson() {
    return {'id': id, 'name': name, 'type': type.name};
  }

  static TxnCategory fromJson(Map<String, Object?> json) {
    return TxnCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      type: TransactionType.values.byName(json['type'] as String),
    );
  }
}
