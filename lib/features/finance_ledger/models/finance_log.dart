class FinanceLog {
  final int? financeId;
  final String actionId;
  final String transactionType;
  final int amountCents;
  final String currency;
  final String primaryCategory;
  final String subCategory;
  final String transactionDate;

  FinanceLog({
    this.financeId,
    required this.actionId,
    required this.transactionType,
    required this.amountCents,
    this.currency = 'PHP',
    required this.primaryCategory,
    required this.subCategory,
    required this.transactionDate,
  });

  factory FinanceLog.fromMap(Map<String, dynamic> map) {
    return FinanceLog(
      financeId: (map['finance_id'] as num?)?.toInt(),
      actionId: map['action_id'].toString(),
      transactionType: map['transaction_type'].toString(),
      amountCents: (map['amount_cents'] as num).toInt(),
      currency: map['currency'].toString(),
      primaryCategory: map['primary_category'].toString(),
      subCategory: map['sub_category'].toString(),
      transactionDate: map['transaction_date'].toString(),
    );
  }
}