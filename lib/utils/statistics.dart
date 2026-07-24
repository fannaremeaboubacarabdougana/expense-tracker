import '../models/expense.dart';

class Statistics {
  static double totalExpenses(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  static double averageExpense(List<Expense> expenses) {
    if (expenses.isEmpty) return 0;

    return totalExpenses(expenses) / expenses.length;
  }

  static int transactionCount(List<Expense> expenses) {
    return expenses.length;
  }

  static String highestCategory(List<Expense> expenses) {
    if (expenses.isEmpty) return "None";

    final totals = <String, double>{};

    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static double monthlyExpenses(List<Expense> expenses) {
    final now = DateTime.now();

    return expenses
        .where(
          (expense) =>
              expense.date.month == now.month && expense.date.year == now.year,
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }
}
