import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.attach_money)),
        title: Text(expense.title),
        subtitle: Text(
          "${expense.category} • ${expense.date.day}/${expense.date.month}/${expense.date.year}",
        ),
        trailing: Text(
          "\$${expense.amount.toStringAsFixed(2)}",
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
