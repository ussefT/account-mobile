import 'transaction_type.dart';

class AccountTransaction {
  const AccountTransaction({
    required this.id,
    required this.accountId,
    required this.title,
    required this.amountCents,
    required this.type,
    required this.category,
    required this.date,
    this.createdBy,
    this.note,
    this.relatedPerson,
  });

  final String id;
  final String accountId;
  final String title;
  final int amountCents;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? createdBy;
  final String? note;
  final String? relatedPerson;

  AccountTransaction copyWith({
    String? id,
    String? accountId,
    String? title,
    int? amountCents,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? createdBy,
    String? note,
    String? relatedPerson,
  }) {
    return AccountTransaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
      note: note ?? this.note,
      relatedPerson: relatedPerson ?? this.relatedPerson,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'title': title,
      'amountCents': amountCents,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
      'createdBy': createdBy,
      'note': note,
      'relatedPerson': relatedPerson,
    };
  }

  static AccountTransaction fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String;
    return AccountTransaction(
      id: json['id'] as String,
      accountId: (json['accountId'] as String?) ?? 'default',
      title: json['title'] as String,
      amountCents: json['amountCents'] as int,
      type: TransactionType.values.byName(typeName),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      createdBy: json['createdBy'] as String?,
      note: json['note'] as String?,
      relatedPerson: json['relatedPerson'] as String?,
    );
  }
}
