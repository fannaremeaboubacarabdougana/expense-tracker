import '../models/expense.dart';
import 'database_helper.dart';

class RecurringExpenseService {
  static Future<void> processRecurringExpenses() async {
    final expenses = await DatabaseHelper.instance.getExpenses();

    final today = DateTime.now();

    for (final expense in expenses) {
      if (!expense.isRecurring) continue;

      if (expense.date.isAfter(today)) continue;

      DateTime nextDate;

      switch (expense.recurrence) {
        case "Daily":
          nextDate = expense.date.add(const Duration(days: 1));
          break;

        case "Weekly":
          nextDate = expense.date.add(const Duration(days: 7));
          break;

        case "Yearly":
          nextDate = DateTime(
            expense.date.year + 1,
            expense.date.month,
            expense.date.day,
          );
          break;

        case "Monthly":
        default:
          nextDate = DateTime(
            expense.date.year,
            expense.date.month + 1,
            expense.date.day,
          );
      }

      final alreadyExists = expenses.any(
        (e) =>
            e.title == expense.title &&
            e.amount == expense.amount &&
            e.category == expense.category &&
            e.date.year == nextDate.year &&
            e.date.month == nextDate.month &&
            e.date.day == nextDate.day,
      );

      if (!alreadyExists) {
        final newExpense = Expense(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: expense.title,
          amount: expense.amount,
          category: expense.category,
          date: nextDate,
          isRecurring: true,
          recurrence: expense.recurrence,
        );

        await DatabaseHelper.instance.insertExpense(newExpense);
      }
    }
  }
}
