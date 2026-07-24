double monthlyBudget = 2000;

class Budget {
  final int id;
  final double amount;

  Budget({required this.id, required this.amount});

  Map<String, dynamic> toMap() {
    return {'id': id, 'amount': amount};
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(id: map['id'], amount: map['amount']);
  }
}
