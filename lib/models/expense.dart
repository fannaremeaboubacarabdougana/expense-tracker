import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isRecurring;
  final String recurrence;

  // Identifies the recurring schedule for generated expenses.
  final String? recurringParentId;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.isRecurring = false,
    this.recurrence = 'Monthly',
    this.recurringParentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'recurrence': recurrence,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      isRecurring: map['isRecurring'] == 1,
      recurrence: map['recurrence'] as String? ?? 'Monthly',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'isRecurring': isRecurring,
      'recurrence': recurrence,
      'recurringParentId': recurringParentId,
    };
  }

  factory Expense.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('Expense document has no data');
    }

    return Expense(
      id: document.id,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      date: (data['date'] as Timestamp).toDate(),
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurrence: data['recurrence'] as String? ?? 'Monthly',
      recurringParentId: data['recurringParentId'] as String?,
    );
  }
}
