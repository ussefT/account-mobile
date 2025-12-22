class BankAccount {
  const BankAccount({
    required this.id,
    required this.name,
    required this.initialBalanceCents,
    required this.createdAt,
    this.number,
  });

  final String id;
  final String name;
  final String? number;
  final int initialBalanceCents;
  final DateTime createdAt;

  BankAccount copyWith({
    String? id,
    String? name,
    String? number,
    int? initialBalanceCents,
    DateTime? createdAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      initialBalanceCents: initialBalanceCents ?? this.initialBalanceCents,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'initialBalanceCents': initialBalanceCents,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static BankAccount fromJson(Map<String, Object?> json) {
    return BankAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as String?,
      initialBalanceCents: json['initialBalanceCents'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

