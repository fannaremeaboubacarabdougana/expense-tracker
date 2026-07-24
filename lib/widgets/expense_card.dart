import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onEdit,
  });
  IconData getCategoryIcon() {
    switch (expense.category) {
      case "Food":
        return Icons.restaurant;

      case "Transport":
        return Icons.directions_car;

      case "Shopping":
        return Icons.shopping_bag;

      case "Entertainment":
        return Icons.movie;

      case "Bills":
        return Icons.receipt;

      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(getCategoryIcon(), color: Colors.blue),
          ),
          title: Text(expense.title),
          subtitle: Text(
            "${expense.category} • ${DateFormat('dd MMM yyyy').format(expense.date)}",
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "\$${expense.amount.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
