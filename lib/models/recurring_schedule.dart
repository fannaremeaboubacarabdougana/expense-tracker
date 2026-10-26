import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringSchedule {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String frequency;
  final String status;
  final DateTime anchorDate;
  final DateTime nextDueDate;
  final int nextIndex;

  const RecurringSchedule({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.status,
    required this.anchorDate,
    required this.nextDueDate,
    required this.nextIndex,
  });

  factory RecurringSchedule.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return RecurringSchedule(
      id: doc.id,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] as String,
      frequency: data['frequency'] as String,
      status: data['status'] as String,
      anchorDate: (data['anchorDate'] as Timestamp).toDate(),
      nextDueDate: (data['nextDueDate'] as Timestamp).toDate(),
      nextIndex: (data['nextIndex'] as num).toInt(),
    );
  }
}
