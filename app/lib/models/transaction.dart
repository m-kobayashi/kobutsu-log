import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String transactionType; // 'buy' or 'sell'

  @HiveField(3)
  final String itemName;

  @HiveField(4)
  final String? itemCategory;

  @HiveField(5)
  final int quantity;

  @HiveField(6)
  final int price;

  @HiveField(7)
  final DateTime transactionDate;

  // 相手方情報（法令必須）
  @HiveField(8)
  final String counterpartyName;

  @HiveField(9)
  final String counterpartyAddress;

  @HiveField(10)
  final int? counterpartyAge;

  @HiveField(11)
  final String? counterpartyOccupation;

  // 本人確認
  @HiveField(12)
  final String idVerificationType;

  @HiveField(13)
  final String? idVerificationNumber;

  // その他
  @HiveField(14)
  final String? photoUrl;

  @HiveField(15)
  final String? notes;

  @HiveField(16)
  final DateTime createdAt;

  @HiveField(17)
  final DateTime updatedAt;

  // ローカル同期用フラグ（サーバーに未同期の場合true）
  @HiveField(18)
  final bool pendingSync;

  Transaction({
    required this.id,
    required this.userId,
    required this.transactionType,
    required this.itemName,
    this.itemCategory,
    this.quantity = 1,
    required this.price,
    required this.transactionDate,
    required this.counterpartyName,
    required this.counterpartyAddress,
    this.counterpartyAge,
    this.counterpartyOccupation,
    required this.idVerificationType,
    this.idVerificationNumber,
    this.photoUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.pendingSync = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      transactionType: json['transaction_type'] as String,
      itemName: json['item_name'] as String,
      itemCategory: json['item_category'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      price: json['price'] as int,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      counterpartyName: json['counterparty_name'] as String,
      counterpartyAddress: json['counterparty_address'] as String,
      counterpartyAge: json['counterparty_age'] as int?,
      counterpartyOccupation: json['counterparty_occupation'] as String?,
      idVerificationType: json['id_verification_type'] as String,
      idVerificationNumber: json['id_verification_number'] as String?,
      photoUrl: json['photo_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      pendingSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'transaction_type': transactionType,
      'item_name': itemName,
      'item_category': itemCategory,
      'quantity': quantity,
      'price': price,
      'transaction_date': transactionDate.toIso8601String(),
      'counterparty_name': counterpartyName,
      'counterparty_address': counterpartyAddress,
      'counterparty_age': counterpartyAge,
      'counterparty_occupation': counterpartyOccupation,
      'id_verification_type': idVerificationType,
      'id_verification_number': idVerificationNumber,
      'photo_url': photoUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? transactionType,
    String? itemName,
    String? itemCategory,
    int? quantity,
    int? price,
    DateTime? transactionDate,
    String? counterpartyName,
    String? counterpartyAddress,
    int? counterpartyAge,
    String? counterpartyOccupation,
    String? idVerificationType,
    String? idVerificationNumber,
    String? photoUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pendingSync,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      transactionType: transactionType ?? this.transactionType,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      transactionDate: transactionDate ?? this.transactionDate,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      counterpartyAddress: counterpartyAddress ?? this.counterpartyAddress,
      counterpartyAge: counterpartyAge ?? this.counterpartyAge,
      counterpartyOccupation: counterpartyOccupation ?? this.counterpartyOccupation,
      idVerificationType: idVerificationType ?? this.idVerificationType,
      idVerificationNumber: idVerificationNumber ?? this.idVerificationNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
